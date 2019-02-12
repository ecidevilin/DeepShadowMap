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
            StructuredBuffer<DoublyLinkedNode> DoublyLinkedList;
            StructuredBuffer<NeighborsNode> NeighborsList;

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

             void depthSearch(inout int entryIdx, inout NeighborsNode entryNeighbors, float z, out float outDepth, out float outShading)
             {
                 DoublyLinkedNode tempEntry;
                 int current = entryIdx;
                 DoublyLinkedNode entry = DoublyLinkedList[entryIdx];
                 int i;


                 if(entry.depth < z)
                 {
                     for(i = 0; i < NUM_BUF_ELEMENTS; i++)
                     {

                         if(entry.headOrTail == -1)
                         {
                             outDepth = entry.depth;
                             outShading = entry.shading;
                             break;
                         }
                         tempEntry = DoublyLinkedList[current + 1];
                         if(tempEntry.depth >= z)
                         {
                             outDepth = entry.depth;
                             outShading = entry.shading;
                             break;
                         }
                         ++current;
                         entry = tempEntry;
					 }
                 }
                 else
                 {
                     for(i = 0; i < NUM_BUF_ELEMENTS; i++)
                     {
                         if (entry.headOrTail == 1)
                         {
                             outDepth = entry.depth;
                             outShading = 1.0f;
                             break;
                         }
                         entry = DoublyLinkedList[--current];

                         if(entry.depth < z)
                         {
                             outDepth = entry.depth;
                             outShading = entry.shading;
                             break;
                         }
                        
					 }
                 }
				 entryNeighbors = NeighborsList[current];
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
                int currentXEntry;
                int currentYEntry;
                NeighborsNode currentXEntryNeighbors;
                int currentX = xLight - FILTER_SIZE;
                bool noXLink = true;
                int x,y;

				for (x = 0; x < FILTER_SIZE * 2 + 2; x++)
				{
					for (y = 0; y < FILTER_SIZE * 2 + 2; y++)
					{
						depthSamples[x][y] = 1.0f;
						shadingSamples[x][y] = 1.0f;
					}
				}
                for(x = 0; x < FILTER_SIZE * 2 + 2; x++)
                {
                    int currentY = yLight - FILTER_SIZE;

                    for(y = 0; y < FILTER_SIZE * 2 + 2; y++)
                    {
                        if(noXLink)
                        {
							currentX = max(0, min(Dimension - 1, currentX));
							currentY = max(0, min(Dimension - 1, currentY));
							currentXEntry = (currentY * Dimension + currentX) * NUM_BUF_ELEMENTS;
                            if(DoublyLinkedList[currentXEntry].headOrTail == -1)
                            {
                                depthSamples[x][y] = 1.0f;
                                shadingSamples[x][y] = 1.0f;
                                currentY++;
                                continue;
                            }
                        }

                        depthSearch(currentXEntry, currentXEntryNeighbors, posInLight.z, depthSamples[x][y], shadingSamples[x][y]);
                        currentY++;

						currentXEntry = currentXEntryNeighbors.neighbor;
						noXLink = currentXEntry == -1;
                    }

                    currentX++;
                }
            #if FILTER_SIZE > 0
                float depthSamples2[2][FILTER_SIZE * 2 + 2];
                float shadingSamples2[2][FILTER_SIZE * 2 + 2];

                float oneOver = 1.0f / (FILTER_SIZE * 2 + 1);
                
                for(y = 0; y < FILTER_SIZE * 2 + 2; y++)
                    for(x = FILTER_SIZE; x < FILTER_SIZE + 2; x++)
                    {
                        int x2 = x - FILTER_SIZE;
                        float filteredShading = 0;

                        float sample0 = depthSamples[x2][y];
                        filteredShading = shadingSamples[x2][y];
                        x2++;
                        
                        float sample1 = depthSamples[x2][y];
                        filteredShading += shadingSamples[x2][y];
                        x2++;
                    
                        float filteredDepth = logConv(oneOver, sample0, oneOver, sample1);

                        for(; x2 <= x + FILTER_SIZE; x2++)
                        {
                            filteredDepth = logConv(1.0f, filteredDepth, oneOver, depthSamples[x2][y]);
                            filteredShading += shadingSamples[x2][y];
                        }

                        depthSamples2[x - FILTER_SIZE][y] = filteredDepth;
                        shadingSamples2[x - FILTER_SIZE][y] = filteredShading * oneOver;
                    }

                for(x = FILTER_SIZE; x < FILTER_SIZE + 2; x++)
                    for(y = FILTER_SIZE; y < FILTER_SIZE + 2; y++)
                    {
                        int y2 = y - FILTER_SIZE;
                        float filteredShading = 0;

                        float sample0 = depthSamples2[x - FILTER_SIZE][y2];
                        filteredShading = shadingSamples2[x - FILTER_SIZE][y2];
                        y2++;
                        
                        float sample1 = depthSamples2[x - FILTER_SIZE][y2];
                        filteredShading += shadingSamples2[x - FILTER_SIZE][y2];
                        y2++;
                    
                        float filteredDepth = logConv(oneOver, sample0, oneOver, sample1);

                        for(; y2 <= y + FILTER_SIZE; y2++)
                        {
                            filteredDepth = logConv(1.0f, filteredDepth, oneOver, depthSamples2[x - FILTER_SIZE][y2]);
                            filteredShading += shadingSamples2[x - FILTER_SIZE][y2];
                        }

                        depthSamples[x][y] = filteredDepth;
                        shadingSamples[x][y] = filteredShading * oneOver;
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
