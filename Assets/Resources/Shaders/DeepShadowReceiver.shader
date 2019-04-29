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
			#include "../Include/DeepShadowShade.cginc"

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
            float3 _HairColor;

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
