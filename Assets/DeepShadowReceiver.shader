Shader "Unlit/DeepShadowReceiver"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma target 4.5

            #include "UnityCG.cginc"
			#include "DeepShadowMap.cginc"
            StructuredBuffer<HeaderNode> HeaderList;
            StructuredBuffer<DoublyLinkedNode> DoublyLinkedList;
            StructuredBuffer<NeighborsNode> NeighborsList;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 tangent : TANGENT;
                float3 color : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float4 lightPos : TEXCOORD2;
                float3 tangent : TANGENT;
                float3 color : COLOR;
            };

			float4x4 _LightVP;
            float3 CameraPos;
            float3 LightPos;


			float logConv(float w0, float d1, float w1, float d2)
			{
				return (d1 + log(w0 + (w1 * exp(d2 - d1))));
			}
            float CalculateKajiyaKay(float3 tangent, float3 posInWorld)
            {
                float3 eye = normalize(CameraPos - posInWorld);
                float3 light = normalize(LightPos - posInWorld);
                
                float diffuse = sin(acos(dot(tangent, light)));
                float specular = pow(dot(tangent, light) * dot(tangent, eye) + sin(acos(dot(light, tangent))) * sin(acos(dot(tangent, eye))), 6.0f);
                
                return (max(min(diffuse, 1.0f), 0.0f) * 0.7f + max(min(specular, 1.0f), 0.0f) * 0.8f) * 0.90f; // scale this thing a bit
            }

            float bilinearInterpolation(float s, float t, float v0, float v1, float v2, float v3) 
            { 
                return (1-s)*(1-t)*v0 + s*(1-t)*v1 + (1-s)*t*v2 + s*t*v3;
            }

             void depthSearch(inout DoublyLinkedNode entry, inout NeighborsNode entryNeighbors, float z, out float outDepth, out float outShading)
             {
                 DoublyLinkedNode tempEntry;
                 int newNum = -1;	// -1 means not changed
                
                 if(entry.depth < z)
                     for(int i = 0; i < NUM_BUF_ELEMENTS; i++)
                     {
                         if(entry.next == -1)
                         {
                             outDepth = entry.depth;
                             outShading = entry.shading;
                             break;
                         }

                         tempEntry = DoublyLinkedList[entry.next];
                         if(tempEntry.depth >= z)
                         {
                             outDepth = entry.depth;
                             outShading = entry.shading;
                             break;
                         }
                         newNum = entry.next;
                         entry = tempEntry;
                     }
                 else
                     for(int i = 0; i < NUM_BUF_ELEMENTS; i++)
                     {
                         if(entry.prev == -1)
                         {
                             outDepth = entry.depth;
                             outShading = 1.0f;
                             break;
                         }
                        
                         newNum = entry.prev;
                         entry = DoublyLinkedList[entry.prev];

                         if(entry.depth < z)
                         {
                             outDepth = entry.depth;
                             outShading = entry.shading;
                             break;
                         }
                        
                     }
                
                 if(newNum != -1)	// finally lookup the neighbors if we changed entry
                     entryNeighbors = NeighborsList[newNum];
             }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = worldPos;
				o.lightPos = mul(_LightVP, worldPos);
                o.tangent = v.tangent;
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 tangent = normalize(i.tangent.xyz);
                float3 posInWorld = i.worldPos;
                float3 posInLight = i.lightPos;
                int xLight = posInLight.x;
                int yLight = posInLight.y;
                float3 finalColor;
                float3 objectColor = i.color;
                finalColor = objectColor * (CalculateKajiyaKay(tangent, posInWorld) + 0.09);

                float depthSamples[FILTER_SIZE * 2 + 2][FILTER_SIZE * 2 + 2];
                float shadingSamples[FILTER_SIZE * 2 + 2][FILTER_SIZE * 2 + 2];
                DoublyLinkedNode currentXEntry;
                DoublyLinkedNode currentYEntry;
                NeighborsNode currentXEntryNeighbors;
                NeighborsNode currentYEntryNeighbors;
                int currentX = xLight - FILTER_SIZE;
                bool noXLink = true;
                int x,y;
	
                for(x = 0; x < FILTER_SIZE * 2 + 2; x++)
                {
                    bool noYLink = false;
                    int currentY = yLight - FILTER_SIZE;

                    if(noXLink && !(currentX < 0 || currentY < 0 || currentX >= Dimension || currentY >= Dimension))
                    {
                        int start = HeaderList[currentY * Dimension + currentX].start;
                        if(start != -1)
                        {
                            currentXEntry = DoublyLinkedList[start];
                            currentXEntryNeighbors = NeighborsList[start];
                            noXLink = false;
                        }
                    }

                    if(noXLink)
                        noYLink = true;
                    else
                    {
                        currentYEntry = currentXEntry;
                        currentYEntryNeighbors = currentXEntryNeighbors;
                    }

                    for(y = 0; y < FILTER_SIZE * 2 + 2; y++)
                    {
                        if(currentX < 0 || currentY < 0 || currentX >= Dimension || currentY >= Dimension)
                        {
                            depthSamples[x][y] = 1.0f;	
                            shadingSamples[x][y] = 1.0f;
                            currentY++;
                            continue;
                        }
                        
                        if(noYLink)
                        {
                            int start = HeaderList[currentY * Dimension + currentX].start;
                            if(start == -1)
                            {
                                depthSamples[x][y] = 1.0f;
                                shadingSamples[x][y] = 1.0f;
                                currentY++;
                                continue;
                            }

                            noYLink = false;
                            currentYEntry = DoublyLinkedList[start];
                            currentYEntryNeighbors = NeighborsList[start];
                        }
                        
                        depthSearch(currentYEntry, currentYEntryNeighbors, posInLight.z, depthSamples[x][y], shadingSamples[x][y]);
                        currentY++;

                        if(currentYEntryNeighbors.top != -1 && !noYLink)
                        {
                            currentYEntry = DoublyLinkedList[currentYEntryNeighbors.top];
                            currentYEntryNeighbors = NeighborsList[currentYEntryNeighbors.top];
                        }
                        else
                            noYLink = true;
                    }

                    currentX++;

                    if(currentXEntryNeighbors.right != -1 && !noXLink)
                    {
                        currentXEntry = DoublyLinkedList[currentXEntryNeighbors.right];
                        currentXEntryNeighbors = NeighborsList[currentXEntryNeighbors.right];
                    }
                    else
                        noXLink = true;
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
                return float4(finalColor * clamp(shading * exp(20.0f * (depth - posInLight.z)), 0.1f, 1.0f), 1.0f);

            }
            ENDCG
        }
    }
}
