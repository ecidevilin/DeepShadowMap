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
			RWStructuredBuffer<int> HeaderList;
			RWStructuredBuffer<LinkedNode> LinkedList;
			float4x4 _LightVP;

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
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = mul(UNITY_MATRIX_VP, worldPos);
				o.lightPos = mul(_LightVP, worldPos);
                return o;
            }
            fixed4 frag(v2f i) : SV_Target
            {
				float3 posInLight = i.lightPos * 0.5f + 0.5f;
				posInLight.xy *= Dimension;
                int counter = LinkedList.IncrementCounter();
				LinkedList[counter].depth = posInLight.z;
				int originalVal;
				InterlockedExchange(HeaderList[((uint)posInLight.y) * Dimension + (uint)posInLight.x], counter, originalVal);
				LinkedList[counter].next = originalVal;

                return fixed4(LinkedList[counter].depth, 0, 0, 1);

            }
            ENDCG
        }
    }
}
