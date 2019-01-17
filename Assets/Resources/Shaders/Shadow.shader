// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Shadow"
{
    Properties
    {
        _ShadowMap ("Shadow", 2D) = "white" {}
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
				float4 lightPos : TEXCOORD0;
            };

            sampler2D _ShadowMap;
            float4 _ShadowMap_ST;
			float4x4 _LightVP;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.lightPos = mul(_LightVP, worldPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float comp = (tex2D(_ShadowMap, i.lightPos.xy * 0.5 + 0.5).r * 2 - 1) > i.lightPos.z;
                return comp.xxxx;
            }
            ENDCG
        }
    }
}
