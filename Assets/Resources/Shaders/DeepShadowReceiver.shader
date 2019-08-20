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

		_MainTex ("Main", 2D) = "white" {}
		_ClipAlpha ("Clip", Range(0, 1)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
		Cull Off
        Pass
        {
			Name "DeepShadowReceiver"
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
				float2 screenPos : TEXCOORD7;
            };

			float4x4 _LightVP;
            float3 _HairColor;
            float _AmbientScale;

			float _ClipAlpha;
			sampler2D _MainTex;

			sampler2D _BlurShadowTexture;

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
				o.screenPos = o.vertex.xy / o.vertex.w * 0.5f + 0.5;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 col = tex2D(_MainTex, i.uv);

				if (col.a < _ClipAlpha)
				{
					discard;
				}

                float3 posInLight = i.lightPos * 0.5f + 0.5f;
				posInLight.xy *= Dimension;
                float3 tangent = normalize(i.tangent.xyz);
                float3 normal = normalize(i.normal);
                float3 viewDir = normalize(i.viewDir);
                float3 finalColor = col * (CalculateKajiyaKay(tangent, normal, i.uv, viewDir, _WorldSpaceLightPos0.xyz));
				float shading = tex2D(_BlurShadowTexture, i.screenPos);
                shading = lerp(_AmbientScale, 1, shading);
                return float4(finalColor * shading, 1.0f);

            }
            ENDCG
        }
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
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
				float2 screenPos : TEXCOORD7;
			};

			float4x4 _LightVP;
			float3 _HairColor;
			float _AmbientScale;

			float _ClipAlpha;
			sampler2D _MainTex;

			sampler2D _BlurShadowTexture;

			v2f vert(appdata v)
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
				o.screenPos = o.vertex.xy / o.vertex.w * 0.5f + 0.5;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);

				if (col.a >= 1 - _ClipAlpha)
				{
					discard;
				}

				float3 posInLight = i.lightPos * 0.5f + 0.5f;
				posInLight.xy *= Dimension;
				float3 tangent = normalize(i.tangent.xyz);
				float3 normal = normalize(i.normal);
				float3 viewDir = normalize(i.viewDir);
				float3 finalColor = col * (CalculateKajiyaKay(tangent, normal, i.uv, viewDir, _WorldSpaceLightPos0.xyz));
				float shading = tex2D(_BlurShadowTexture, i.screenPos);
				shading = lerp(_AmbientScale, 1, shading);
				return float4(finalColor * shading, col.a);

			}
			ENDCG
		}
		Pass
		{
			Name "DepthOnly"
			Tags{"LightMode" = "DepthOnly"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			float _ClipAlpha;
			sampler2D _MainTex;

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			#include "UnityCG.cginc"

			v2f vert(float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				v2f o;
				o.uv = uv;
				o.vertex = UnityObjectToClipPos(vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				if (col.a < _ClipAlpha)
				{
					discard;
				}
				return 0;
			}
			ENDCG
		}

		Pass
		{
			Name "DeepShadowCaster"
			Tags{"LightMode" = "DeepShadowCaster"}
			Cull Back
			ZTest Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.5
			float _ClipAlpha;
			sampler2D _MainTex;

			#include "UnityCG.cginc"
			#include "../Include/DeepShadowMap.cginc"
			RWStructuredBuffer<uint> NumberBuffer;
			RWStructuredBuffer<float2> DepthBuffer;
			float4x4 _LightVP;
			float _HairAlpha;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 lightPos : TEXCOORD1;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.uv = v.uv;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = mul(UNITY_MATRIX_VP, worldPos);
				o.lightPos = mul(_LightVP, worldPos);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				if (col.a < _ClipAlpha)
				{
					discard;
				}
				float3 posInLight = i.lightPos * 0.5f + 0.5f;
				posInLight.xy *= Dimension;
				uint idx = ((uint)posInLight.y) * Dimension + (uint)posInLight.x;
				uint offset = idx * NUM_BUF_ELEMENTS;
				uint originalVal;
				InterlockedAdd(NumberBuffer[idx], 1, originalVal);
				originalVal = min(NUM_BUF_ELEMENTS - 1, originalVal);
				DepthBuffer[offset + originalVal].x = posInLight.z;
				DepthBuffer[offset + originalVal].y = _HairAlpha;

				return fixed4(posInLight.z, 0, 0, 1);

			}
			ENDCG
		}
    }
}
