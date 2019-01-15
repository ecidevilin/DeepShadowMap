Shader "Unlit/DeepShadowMap"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma target 4.5

            #include "UnityCG.cginc"
            #include "DeepShadowMap.cginc"
            uniform float _Alpha;
			RWStructuredBuffer<HeaderNode> HeaderList;
			RWStructuredBuffer<LinkedNode> LinkedList;
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
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }
#ifdef _DEBUG_DSM
            fixed4 frag(v2f i) : SV_Target
#else
			void frag(v2f i)
#endif
            {
                int counter = LinkedList.IncrementCounter();
                LinkedList[counter].depth = i.vertex.z + 0.00002;
                LinkedList[counter].alpha = _Alpha;
                int originalVal;
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
