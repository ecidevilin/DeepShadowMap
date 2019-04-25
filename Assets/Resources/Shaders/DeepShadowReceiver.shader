Shader "Unlit/DeepShadowReceiver"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
		Cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma target 4.5

            #include "UnityCG.cginc"
			#include "../Include/DeepShadowMap.cginc"
			StructuredBuffer<FittingFunc> FittingFuncList;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float4 lightPos : TEXCOORD2;
                float3 tangent : TANGENT;
            };

			float4x4 _LightVP;
            float3 CameraPos;
            float3 LightDir;
			float3 _HairColor;
			float _HairAlpha;


			float logConv(float w0, float d1, float w1, float d2)
			{
				return (d1 + log(w0 + (w1 * exp(d2 - d1))));
			}
            float CalculateKajiyaKay(float3 tangent, float3 posInWorld)
            {
                float3 eye = normalize(CameraPos - posInWorld);
                float3 light = normalize(LightDir);
                
                float diffuse = sin(acos(dot(tangent, light)));
                float specular = pow(dot(tangent, light) * dot(tangent, eye) + sin(acos(dot(light, tangent))) * sin(acos(dot(tangent, eye))), 6.0f);
                
                return (max(min(diffuse, 1.0f), 0.0f) * 0.7f + max(min(specular, 1.0f), 0.0f) * 0.8f) * 0.90f; // scale this thing a bit
            }

            float bilinearInterpolation(float s, float t, float v0, float v1, float v2, float v3) 
            { 
                return (1-s)*(1-t)*v0 + s*(1-t)*v1 + (1-s)*t*v2 + s*t*v3;
            }

			void depthSearch(int entryIdx, float z, out float outDepth, out float outShading)
			{
				int idx = entryIdx / NUM_BUF_ELEMENTS;
				FittingFunc func = FittingFuncList[idx];
				outDepth = z;

				float3 f0 = func.f[0];
				float3 f1 = func.f[1];
				float3 f2 = func.f[2];
				float3 f3 = func.f[3];

				uint n = FittingBins[0];
				uint o = 0;
				float xx[5];
				xx[0] = -1;
				xx[1] = (z - f0.y) / f0.x * n;
				o += n;
				n = FittingBins[1];
				xx[2] = (z - f1.y) / f1.x * n + o;
				o += n;
				n = FittingBins[2];
				xx[3] = (z - f2.y) / f2.x * n + o;
				o += n;
				n = FittingBins[3];
				xx[4] = (z - f3.y) / f3.x * n + o;
				uint fi = z < f0.z ? 0 : z < f1.z ? 1 : z < f2.z ? 2 : z < f3.z ? 3 : 4;
				float ii = xx[fi];
				outShading = pow(1.0 - _HairAlpha, ii + 1);
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = worldPos;
				o.lightPos = mul(_LightVP, worldPos);
                o.tangent = v.tangent;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 tangent = normalize(i.tangent.xyz);
                float3 posInWorld = i.worldPos;
                float3 posInLight = i.lightPos;
				posInLight += 1;
				posInLight *= 0.5f;
				posInLight.xy *= Dimension;
                int xLight = posInLight.x;
                int yLight = posInLight.y;
                float3 finalColor;
                finalColor = _HairColor * (CalculateKajiyaKay(tangent, posInWorld) + 0.09);

                float depthSamples[FILTER_SIZE * 2 + 2][FILTER_SIZE * 2 + 2];
                float shadingSamples[FILTER_SIZE * 2 + 2][FILTER_SIZE * 2 + 2];

				int x, y;

				//default
				[unroll(FILTER_SIZE * 2 + 2)]
				for (x = 0; x < FILTER_SIZE * 2 + 2; x++)
				{
					[unroll(FILTER_SIZE * 2 + 2)]
					for (y = 0; y < FILTER_SIZE * 2 + 2; y++)
					{
						depthSamples[x][y] = 1.0f;
						shadingSamples[x][y] = 1.0f;
					}
				}

				//search
				int currentX = xLight - FILTER_SIZE;
				bool noXLink = true;
				int currentXEntry;
				for (x = 0; x < FILTER_SIZE * 2 + 2; x++)
				{
					int currentY = yLight - FILTER_SIZE;

					for (y = 0; y < FILTER_SIZE * 2 + 2; y++)
					{
						currentXEntry = (currentY * Dimension + currentX) * NUM_BUF_ELEMENTS;

						depthSearch(currentXEntry, posInLight.z, depthSamples[x][y], shadingSamples[x][y]);
						currentY++;
					}

					currentX++;
				}

				//filter
#if FILTER_SIZE > 0
				float depthSamples2[2][FILTER_SIZE * 2 + 2];
				float shadingSamples2[2][FILTER_SIZE * 2 + 2];

				float oneOver = 1.0f / (FILTER_SIZE * 2 + 1);

				[unroll(FILTER_SIZE * 2 + 2)]
				for (y = 0; y < FILTER_SIZE * 2 + 2; y++)
				{
					{
						float filteredShading = 0;

						float sample0 = depthSamples[0][y];
						filteredShading = shadingSamples[0][y];

						float sample1 = depthSamples[1][y];
						filteredShading += shadingSamples[1][y];

						float filteredDepth = logConv(oneOver, sample0, oneOver, sample1);

						[unroll(FILTER_SIZE * 2 - 1)]
						for (int x2 = 2; x2 <= 2 * FILTER_SIZE; x2++)
						{
							filteredDepth = logConv(1.0f, filteredDepth, oneOver, depthSamples[x2][y]);
							filteredShading += shadingSamples[x2][y];
						}

						depthSamples2[0][y] = filteredDepth;
						shadingSamples2[0][y] = filteredShading * oneOver;
					}
					{
						float filteredShading = 0;

						float sample0 = depthSamples[1][y];
						filteredShading = shadingSamples[1][y];

						float sample1 = depthSamples[2][y];
						filteredShading += shadingSamples[2][y];

						float filteredDepth = logConv(oneOver, sample0, oneOver, sample1);

						[unroll(FILTER_SIZE * 2 - 1)]
						for (int x2 = 3; x2 <= 1 + 2 * FILTER_SIZE; x2++)
						{
							filteredDepth = logConv(1.0f, filteredDepth, oneOver, depthSamples[x2][y]);
							filteredShading += shadingSamples[x2][y];
						}

						depthSamples2[1][y] = filteredDepth;
						shadingSamples2[1][y] = filteredShading * oneOver;
					}
				}

				{
					float filteredShading = 0;

					float sample0 = depthSamples2[0][0];
					filteredShading = shadingSamples2[0][0];

					float sample1 = depthSamples2[0][1];
					filteredShading += shadingSamples2[0][1];

					float filteredDepth = logConv(oneOver, sample0, oneOver, sample1);

					[unroll(FILTER_SIZE * 2 - 1)]
					for (int y2 = 2; y2 <= 2 * FILTER_SIZE; y2++)
					{
						filteredDepth = logConv(1.0f, filteredDepth, oneOver, depthSamples2[0][y2]);
						filteredShading += shadingSamples2[0][y2];
					}

					depthSamples[FILTER_SIZE][FILTER_SIZE] = filteredDepth;
					shadingSamples[FILTER_SIZE][FILTER_SIZE] = filteredShading * oneOver;
				}
				{
					float filteredShading = 0;

					float sample0 = depthSamples2[0][1];
					filteredShading = shadingSamples2[0][1];

					float sample1 = depthSamples2[0][2];
					filteredShading += shadingSamples2[0][2];

					float filteredDepth = logConv(oneOver, sample0, oneOver, sample1);

					[unroll(FILTER_SIZE * 2 - 1)]
					for (int y2 = 3; y2 <= 1 + 2 * FILTER_SIZE; y2++)
					{
						filteredDepth = logConv(1.0f, filteredDepth, oneOver, depthSamples2[0][y2]);
						filteredShading += shadingSamples2[0][y2];
					}

					depthSamples[FILTER_SIZE][FILTER_SIZE + 1] = filteredDepth;
					shadingSamples[FILTER_SIZE][FILTER_SIZE + 1] = filteredShading * oneOver;
				}
				{
					float filteredShading = 0;

					float sample0 = depthSamples2[1][0];
					filteredShading = shadingSamples2[1][0];

					float sample1 = depthSamples2[1][1];
					filteredShading += shadingSamples2[1][1];

					float filteredDepth = logConv(oneOver, sample0, oneOver, sample1);

					[unroll(FILTER_SIZE * 2 - 1)]
					for (int y2 = 2; y2 <= 2 * FILTER_SIZE; y2++)
					{
						filteredDepth = logConv(1.0f, filteredDepth, oneOver, depthSamples2[1][y2]);
						filteredShading += shadingSamples2[1][y2];
					}

					depthSamples[FILTER_SIZE + 1][FILTER_SIZE] = filteredDepth;
					shadingSamples[FILTER_SIZE + 1][FILTER_SIZE] = filteredShading * oneOver;
				}
				{
					float filteredShading = 0;

					float sample0 = depthSamples2[1][1];
					filteredShading = shadingSamples2[1][1];

					float sample1 = depthSamples2[1][2];
					filteredShading += shadingSamples2[1][2];

					float filteredDepth = logConv(oneOver, sample0, oneOver, sample1);

					[unroll(FILTER_SIZE * 2 - 1)]
					for (int y2 = 3; y2 <= 1 + 2 * FILTER_SIZE; y2++)
					{
						filteredDepth = logConv(1.0f, filteredDepth, oneOver, depthSamples2[1][y2]);
						filteredShading += shadingSamples2[1][y2];
					}

					depthSamples[FILTER_SIZE + 1][FILTER_SIZE + 1] = filteredDepth;
					shadingSamples[FILTER_SIZE + 1][FILTER_SIZE + 1] = filteredShading * oneOver;
				}
#endif

                float dx = frac(posInLight.x);
                float dy = frac(posInLight.y);

                float depth = bilinearInterpolation(dx, dy, depthSamples[FILTER_SIZE][FILTER_SIZE], depthSamples[FILTER_SIZE + 1][FILTER_SIZE], depthSamples[FILTER_SIZE][FILTER_SIZE + 1], depthSamples[FILTER_SIZE + 1][FILTER_SIZE + 1]);
                float shading = bilinearInterpolation(dx, dy, shadingSamples[FILTER_SIZE][FILTER_SIZE], shadingSamples[FILTER_SIZE + 1][FILTER_SIZE], shadingSamples[FILTER_SIZE][FILTER_SIZE + 1], shadingSamples[FILTER_SIZE + 1][FILTER_SIZE + 1]);
				shading += 0.25f;// brighter shadow
				// In shadow : depth < posInLight.z 
                return float4(finalColor * clamp(shading * exp(10.0f * (depth - posInLight.z)), 0.1f, 1.0f), 1.0f);

            }
            ENDCG
        }
    }
}
