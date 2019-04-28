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
				float tdotl = dot(tangent, normalize(LightDir));
				float tdotv = dot(tangent, normalize(CameraPos - posInWorld));
                float diffuse = sqrt(1 - tdotl * tdotl);
                float specular = pow(tdotl * tdotv + diffuse * sqrt(1 - tdotv * tdotv), 6.0f);
                return (saturate(diffuse) * 0.7f + saturate(specular) * 0.8f) * 0.90f; // scale this thing a bit
            }

            float bilinearInterpolation(float s, float t, float v0, float v1, float v2, float v3) 
            { 
                return (1-s)*(1-t)*v0 + s*(1-t)*v1 + (1-s)*t*v2 + s*t*v3;
            }

			float deepShadowmapShading(float3 posInLight)
			{
				float shadingSamples[2][2] = {0,0,0,0};
				float z = posInLight.z;
#if FILTER_SIZE > 0
				float oneOver = 1.0f / (FILTER_SIZE * 2 + 1);
#endif
				int currentY = posInLight.y - FILTER_SIZE;
				[unroll(FILTER_SIZE * 2 + 2)]
				for (uint y = 0; y < FILTER_SIZE * 2 + 2; y++)
				{
					int idx = currentY++ * Dimension + posInLight.x - FILTER_SIZE;
#if FILTER_SIZE > 0
					float filteredShading0 = 0;
					float filteredShading1 = 0;
#endif
					[unroll(FILTER_SIZE * 2 + 2)]
					for (uint x = 0; x < FILTER_SIZE * 2 + 2; x++)
					{
						FittingFunc func = FittingFuncList[idx++];
						float3 f0 = func.f[0];
						float shading = 1;
						if (z >= f0.z)
						{
							float3 f1 = func.f[1];
							float3 f2 = func.f[2];
							float3 f3 = func.f[3];
							uint fi = z < f1.z ? 0 : z < f2.z ? 1 : z < f3.z ? 2 : 3;
							float3 f = func.f[fi];
							float ii = (z - f.y) * f.x * FittingBins[fi] + FittingBinsAcc[fi];
							shading = pow(1.0 - _HairAlpha, ii + 1);
						}
#if FILTER_SIZE > 0
						filteredShading0 += shading * (x < FILTER_SIZE * 2 + 1);
						filteredShading1 += shading * (x > 0);
#else
						shadingSamples[x][y] = shading;
#endif
					}
#if FILTER_SIZE > 0
					float averageShading0 = filteredShading0 * oneOver;
					float averageShading1 = filteredShading1 * oneOver;
					shadingSamples[0][0] += averageShading0 * (y < FILTER_SIZE * 2 + 1);
					shadingSamples[1][0] += averageShading1 * (y < FILTER_SIZE * 2 + 1);
					shadingSamples[0][1] += averageShading0 * (y > 0);
					shadingSamples[1][1] += averageShading1 * (y > 0);
#endif
				}
#if FILTER_SIZE > 0
				shadingSamples[0][0] *= oneOver;
				shadingSamples[1][0] *= oneOver;
				shadingSamples[0][1] *= oneOver;
				shadingSamples[1][1] *= oneOver;
#endif
				float shading = bilinearInterpolation(frac(posInLight.x), frac(posInLight.y), shadingSamples[0][0], shadingSamples[1][0], shadingSamples[0][1], shadingSamples[1][1]);
				shading = clamp(shading, 0.25, 1);
				return shading;
			}

            v2f vert (appdata v)
            {
                v2f o;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                o.worldPos = worldPos;
				o.lightPos = mul(_LightVP, worldPos);
                o.tangent = v.tangent;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 posInLight = i.lightPos * 0.5f + 0.5f;
				posInLight.xy *= Dimension;
                float3 finalColor = _HairColor * (CalculateKajiyaKay(normalize(i.tangent.xyz), i.worldPos) + 0.09);
				float shading = deepShadowmapShading(posInLight);
                return float4(finalColor * shading, 1.0f);
            }
            ENDCG
        }
    }
}
