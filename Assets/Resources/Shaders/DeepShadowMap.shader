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
			RWStructuredBuffer<HeaderNode> HeaderList;
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
            };

            v2f vert (appdata v)
            {
                v2f o;
                //o.vertex = UnityObjectToClipPos(v.vertex);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = mul(_LightVP, worldPos);
                return o;
            }
#ifdef _DEBUG_DSM
            fixed4 frag(v2f i) : SV_Target
#else
			void frag(v2f i)
#endif
            {
                int counter = LinkedList.IncrementCounter();
                LinkedList[counter].depth = i.vertex.z + 1 / 256.0;
                LinkedList[counter].alpha = _HairAlpha;
                int originalVal;
				if (i.vertex.z > 1)
				{
					return float4(1, 0, 0, 0);
				}
                InterlockedExchange(HeaderList[((uint)i.vertex.y) * Dimension + (uint)i.vertex.x].start, counter, originalVal);
                LinkedList[counter].next = originalVal;
#ifdef _DEBUG_DSM
                return fixed4(LinkedList[counter].depth, LinkedList[counter].alpha, HeaderList[((uint)i.vertex.y) * Dimension + (uint)i.vertex.x].start, 1);
#endif
            }
            ENDCG
        }
    }
}
