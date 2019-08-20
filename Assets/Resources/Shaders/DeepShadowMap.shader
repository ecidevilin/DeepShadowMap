Shader "Unlit/DeepShadowMap"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

		Cull Back
		ZTest Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma target 4.5

            #include "UnityCG.cginc"
            #include "../Include/DeepShadowMap.cginc"
			RWStructuredBuffer<uint> NumberBuffer;
			RWStructuredBuffer<float2> DepthBuffer;
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
				uint idx = ((uint)posInLight.y) * Dimension + (uint)posInLight.x;
				uint offset = idx * NUM_BUF_ELEMENTS;
				uint originalVal;
				InterlockedAdd(NumberBuffer[idx], 1, originalVal);
				originalVal = min(NUM_BUF_ELEMENTS - 1, originalVal);
				DepthBuffer[offset + originalVal].x = posInLight.z;
				DepthBuffer[offset + originalVal].y = 1;

                return fixed4(posInLight.z, 0, 0, 1);

            }
            ENDCG
        }
    }
}
