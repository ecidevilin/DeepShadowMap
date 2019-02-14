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
			RWStructuredBuffer<int> HeaderList;
			//RWStructuredBuffer<LinkedNode> LinkedList;
			RWStructuredBuffer<DoublyLinkedNode> DoublyLinkedList;
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
    //            int counter = LinkedList.IncrementCounter();
				//
    //            LinkedList[counter].index = ((uint)posInLight.y) * Dimension + (uint)posInLight.x;
				//LinkedList[counter].depth = posInLight.z;
				//LinkedList[counter].alpha = _HairAlpha;

				uint idx = ((uint)posInLight.y) * Dimension + (uint)posInLight.x;
				uint offset = idx * NUM_BUF_ELEMENTS;
				int originalVal;
				InterlockedAdd(HeaderList[idx], 1, originalVal);
				originalVal = min(NUM_BUF_ELEMENTS - 1, originalVal);
				DoublyLinkedList[offset + originalVal].depth = posInLight.z;
				DoublyLinkedList[offset + originalVal].shading = _HairAlpha;
#ifdef _DEBUG_DSM
                return fixed4(DoublyLinkedList[offset + originalVal].depth, DoublyLinkedList[offset + originalVal].shading, originalVal, 1);
#endif

            }
            ENDCG
        }
    }
}
