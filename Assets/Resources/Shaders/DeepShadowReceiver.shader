Shader "Unlit/DeepShadowReceiver"
{
    Properties
    {
        _ShiftTex ("Shift", 2D) = "black" {}
        _NoiseTex ("Noise", 2D) = "white" {}
        _Diffuse ("Diffuse", float) = 0.25
        _PrimaryShift ("Primary Shift", float) = 1
        _SecondaryShift ("Secondary Shift", float) = 0.75
        _PrimarySpecular ("Primary Specular", float) = 100
        _SecondarySpecular ("Secondary Specular", float) = 100
        _PrimarySpecularColor ("Primary Specular Color", Color) = (0.25,0.25,0.25,0.25)
        _SecondarySpecularColor ("Secondary Specular Color", Color) = (0.25,0.25,0.25,0.25)
        _AmbientScale ("Ambient Scale", float) = 0.125
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
                float3 normal : NORMAL;
                float2 uv : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD1;
                float4 lightPos : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float3 tangent : TEXCOORD4;
                float3 normal : TEXCOORD5;
                float4 worldPos : TEXCOORD6;
            };

			float4x4 _LightVP;
            float3 _HairColor;
            float _AmbientScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = worldPos;
				o.lightPos = mul(_LightVP, worldPos);
                o.tangent = v.tangent;
                o.normal = v.normal;
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 posInLight = i.lightPos * 0.5f + 0.5f;
				posInLight.xy *= Dimension;
                float3 tangent = normalize(i.tangent.xyz);
                float3 normal = normalize(i.normal);
                float3 viewDir = normalize(i.viewDir);
                float3 finalColor = _HairColor * (CalculateKajiyaKay(tangent, normal, i.uv, viewDir, _WorldSpaceLightPos0.xyz));
                float shading = deepShadowmapShading(posInLight);
                shading = lerp(_AmbientScale, 1, shading);
                return float4(finalColor * shading, 1.0f);

            }
            ENDCG
        }
    }
}
