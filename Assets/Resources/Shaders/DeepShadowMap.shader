Shader "Unlit/DeepShadowMap"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

		Cull Off
		ZTest Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma target 4.5

            #include "UnityCG.cginc"
            #include "../Include/DeepShadowMap.cginc"
            float _HairAlpha;
			//RWStructuredBuffer<HeaderNode> HeaderList;
			RWStructuredBuffer<LinkedNode> LinkedList;
			float4x4 _LightVP;
#define _DEBUG_DSM

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 lightPos : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.lightPos = mul(_LightVP, worldPos);
                return o;
            }
#ifdef _DEBUG_DSM
            fixed4 frag(v2f i) : SV_Target
#else
			void frag(v2f i)
#endif
            {
                float3 posInLight = i.lightPos;
                posInLight += 1;
                posInLight *= 0.5f;
                posInLight.xy *= Dimension;
                int counter = LinkedList.IncrementCounter();
                //int originalVal;
                //InterlockedExchange(HeaderList[((uint)i.vertex.y) * Dimension + (uint)i.vertex.x].start, counter, originalVal);
                //LinkedList[counter].next = originalVal;
				
                LinkedList[counter].index = ((uint)posInLight.y) * Dimension + (uint)posInLight.x;
				LinkedList[counter].depth = posInLight.z;
				//LinkedList[counter].alpha = _HairAlpha;

#ifdef _DEBUG_DSM
                return fixed4(LinkedList[counter].depth, 0, counter, 1);
#endif

            }
            ENDCG
        }
    }
}
