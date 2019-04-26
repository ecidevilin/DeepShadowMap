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

			float deepShadowmapShading(float3 posInLight)
			{
				float shadingSamples[FILTER_SIZE * 2 + 2][FILTER_SIZE * 2 + 2];

				int x, y;
				float z = posInLight.z;

				//default
				[unroll(FILTER_SIZE * 2 + 2)]
				for (x = 0; x < FILTER_SIZE * 2 + 2; x++)
				{
					[unroll(FILTER_SIZE * 2 + 2)]
					for (y = 0; y < FILTER_SIZE * 2 + 2; y++)
					{
						shadingSamples[x][y] = 1.0f;
					}
				}

				//search
				int currentY = posInLight.y - FILTER_SIZE;
				[unroll(FILTER_SIZE * 2 + 2)]
				for (y = 0; y < FILTER_SIZE * 2 + 2; y++)
				{
					int idx = (currentY * Dimension + posInLight.x - FILTER_SIZE);
					[unroll(FILTER_SIZE * 2 + 2)]
					for (x = 0; x < FILTER_SIZE * 2 + 2; x++)
					{
						FittingFunc func = FittingFuncList[idx++];

						float3 f0 = func.f[0];
						if (z < f0.z)
						{
							shadingSamples[x][y] = 1;
							continue;
						}
						float3 f1 = func.f[1];
						float3 f2 = func.f[2];
						float3 f3 = func.f[3];
						uint fi = z < f1.z ? 0 : z < f2.z ? 1 : z < f3.z ? 2 : 3;
						float3 f = func.f[fi];
						uint n = FittingBins[fi];
						uint o = FittingBinsAcc[fi];
						float ii = (z - f.y) * f.x * n + o;
						shadingSamples[x][y] = pow(1.0 - _HairAlpha, ii + 1);
					}
					currentY++;
				}

				//filter
#if FILTER_SIZE > 0
				float shadingSamples2[2][FILTER_SIZE * 2 + 2];

				float oneOver = 1.0f / (FILTER_SIZE * 2 + 1);

				[unroll(FILTER_SIZE * 2 + 2)]
				for (y = 0; y < FILTER_SIZE * 2 + 2; y++)
				{
					{
						float filteredShading = 0;

						filteredShading = shadingSamples[0][y];

						filteredShading += shadingSamples[1][y];

						[unroll(FILTER_SIZE * 2 - 1)]
						for (int x2 = 2; x2 <= 2 * FILTER_SIZE; x2++)
						{
							filteredShading += shadingSamples[x2][y];
						}

						shadingSamples2[0][y] = filteredShading * oneOver;
					}
					{
						float filteredShading = 0;

						filteredShading = shadingSamples[1][y];

						filteredShading += shadingSamples[2][y];

						[unroll(FILTER_SIZE * 2 - 1)]
						for (int x2 = 3; x2 <= 1 + 2 * FILTER_SIZE; x2++)
						{
							filteredShading += shadingSamples[x2][y];
						}

						shadingSamples2[1][y] = filteredShading * oneOver;
					}
				}

				{
					float filteredShading = 0;

					filteredShading = shadingSamples2[0][0];

					filteredShading += shadingSamples2[0][1];

					[unroll(FILTER_SIZE * 2 - 1)]
					for (int y2 = 2; y2 <= 2 * FILTER_SIZE; y2++)
					{
						filteredShading += shadingSamples2[0][y2];
					}

					shadingSamples[FILTER_SIZE][FILTER_SIZE] = filteredShading * oneOver;
				}
				{
					float filteredShading = 0;

					filteredShading = shadingSamples2[0][1];

					filteredShading += shadingSamples2[0][2];

					[unroll(FILTER_SIZE * 2 - 1)]
					for (int y2 = 3; y2 <= 1 + 2 * FILTER_SIZE; y2++)
					{
						filteredShading += shadingSamples2[0][y2];
					}

					shadingSamples[FILTER_SIZE][FILTER_SIZE + 1] = filteredShading * oneOver;
				}
				{
					float filteredShading = 0;

					filteredShading = shadingSamples2[1][0];

					filteredShading += shadingSamples2[1][1];

					[unroll(FILTER_SIZE * 2 - 1)]
					for (int y2 = 2; y2 <= 2 * FILTER_SIZE; y2++)
					{
						filteredShading += shadingSamples2[1][y2];
					}

					shadingSamples[FILTER_SIZE + 1][FILTER_SIZE] = filteredShading * oneOver;
				}
				{
					float filteredShading = 0;

					filteredShading = shadingSamples2[1][1];

					filteredShading += shadingSamples2[1][2];

					[unroll(FILTER_SIZE * 2 - 1)]
					for (int y2 = 3; y2 <= 1 + 2 * FILTER_SIZE; y2++)
					{
						filteredShading += shadingSamples2[1][y2];
					}
					shadingSamples[FILTER_SIZE + 1][FILTER_SIZE + 1] = filteredShading * oneOver;
				}
#endif

				float dx = frac(posInLight.x);
				float dy = frac(posInLight.y);

				float shading = bilinearInterpolation(dx, dy, shadingSamples[FILTER_SIZE][FILTER_SIZE], shadingSamples[FILTER_SIZE + 1][FILTER_SIZE], shadingSamples[FILTER_SIZE][FILTER_SIZE + 1], shadingSamples[FILTER_SIZE + 1][FILTER_SIZE + 1]);
				shading = clamp(shading, 0.25, 1);
				return shading;
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
                float3 finalColor = _HairColor * (CalculateKajiyaKay(tangent, posInWorld) + 0.09);
				float shading = deepShadowmapShading(posInLight);
                return float4(finalColor * shading, 1.0f);

            }
            ENDCG
        }
    }
}
