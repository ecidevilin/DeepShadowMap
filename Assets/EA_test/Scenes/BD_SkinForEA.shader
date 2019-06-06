Shader "GEffect/BD_Skin_EA"
{
	Properties
	{
		_Color("Main Color (Use alpha to blend)", Color) = (1,1,1,1)
		_MainTex("Diffuse", 2D) = "white" {}
		_NormalTex("Normal", 2D) = "normal" {}

		_AO("AO Texture", 2D) = "white"{}
		_DetailNormalTex("DetailNormal", 2D) = "normal"{}
		_MaterialTex("Smooth(G)", 2D) = "normal"{}
		//_Cube("Cubemap", CUBE) = "" {}
		//_ShadowMapFocus("ShadowMap",2D) = "normal"{}
		_SkyColor("SkyColor", Color) = (0.548828	,0.548828	,0.548828	,0.5)
		_StaticLightColor("Secondary Light Color", Color) = (0.548828	,0.548828	,0.548828	,0.5)
		_StaticLightDir("Secondary Light Direction", Vector) = (-0.07473408,	0.0,	-0.9972036, 0)
		_AmbientColor("Ambient Color", Color) = (0.548828	,0.548828	,0.548828	,0.5)
		_DetailNormalTile("DetailNormalTile", Float) = 1.0
		_DetailNormalWeight("DetailNormalWeight" ,Range(0,10)) = 1
		_HDR_Multiply("_HDR_Multiply", Range(0,2)) = 1
		_SkinSpec("_SkinSpec ", Range(0,1)) = 0.31

		_SelfSpecWeight("Self Specular Weight", Range(0,1)) = 1
		_SelfSpecColor("Self Specular Color", Color) = (1,0,0,0)

		_SSSWeight ("SSS Weight", Range(0, 1)) = 1

	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 100

			Pass
			{
				Tags{ "LightMode" = "ForwardBase" "Queue" = "Geometry"}


			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "BD_CommonVert.cginc"	

			float _SelfSpecWeight;
			float4 _SelfSpecColor;
			float _SSSWeight;

			fixed4 frag(v2f i) : SV_Target
			{
				// base
				float4 texBase = tex2Dbias(_MainTex, half4(i.uv, 0, -0.5));
				// smooth
				float smooth = tex2D(_MaterialTex, i.uv).g;
				// normal
				float3 texNormal = tex2Dbias(_NormalTex, half4(i.uv, 0, -1.5)).xyz - 0.5;
				float3 DetailNormal = tex2Dbias(_DetailNormalTex, half4(i.uv * _DetailNormalTile, 0, -1.5)).xyz - 0.5;
				texNormal += DetailNormal.xyz *  0.2 * _DetailNormalWeight;
				float3 wNormal = texNormal.x * i.world_tangent.xyz + texNormal.y * i.world_binormal + texNormal.z * i.world_normal;
				float3 wNormal0 = 5 * texNormal.x * i.world_tangent.xyz + 5 * texNormal.y * i.world_binormal + texNormal.z * i.world_normal;
				// ao
				float4 AoTex = tex2Dbias(_AO, half4(i.uv, 0, -0.5)); //AO
				texBase.xyz *= saturate(AoTex.x * 1.3);

				// tint
				texBase.xyz *= lerp(1, _Color.xyz, _Color.a);

				// Dir & Cos
				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				half NdotL = dot(wNormal, lightDir.xyz);
				half NdotV = dot(wNormal, viewDir);
				half LdotV = dot(lightDir.xyz, viewDir);
							   
				// Lights
				half4 OutColor = half4(0, 0, 0, 0);

				// Main Light
				float halfLambert = NdotL * 0.5 + 0.5;
				float _light = _calcOrenNayar3_optimize(halfLambert * 0.35, NdotV, NdotL) * 6.0;
				float atten = LIGHT_ATTENUATION(i);
				OutColor.xyz = _LightColor0.xyz * _light * atten;
				
				// Sky Light
				float normalY = wNormal.y * 0.5 + 0.5;
				OutColor.xyz += _SkyColor.xyz * normalY;
				OutColor.xyz += _AmbientColor;

				// Secondary Light
				float SceneNdotL = dot(wNormal, normalize(_StaticLightDir.xyz));
				float SceneHalfLambert = SceneNdotL * 0.5 + 0.5;
				SceneHalfLambert = max(SceneHalfLambert, 0.2);

				OutColor *= half4(texBase.xyz, 0.0);

				float4 ShadowResult = half4(1, 1, 1, 1); //TODO:?
				// Fake SSS
				NdotV = saturate(NdotV);
				float inverseNdotV = 1.0 - NdotV;
				inverseNdotV *= (i.world_normal.y * 0.5 + 0.5);
				float3 fakeSSS = inverseNdotV * inverseNdotV * min(0, NdotL) * ShadowResult.x * _LightColor0.xyz;
				OutColor.xyz += fakeSSS * _SSSWeight;
				// 
				//float temp = inverseNdotV * SceneHalfLambert + 0.01;
				//OutColor.xyz += _StaticLightColor.xyz * temp;
				// main spec	
				smooth *= 1.0 + _SkinSpec;
				wNormal0 = normalize(wNormal0);
				float fresnel = _fresnel_Optimize(0.2, NdotV);
				float matal = min(smooth, 1);
				float Spec = _calc_Specular2_custom_optimize2(wNormal0.xyz, viewDir.xyz, lightDir.xyz, NdotV, fresnel, matal);//_paParam_109
				float3 EnvColor = _EnvBRDFApprox(0.02, pow(1.0 - smooth, 1), 1.0 - max(NdotV, 0.0));
				EnvColor *= 0.2;
				OutColor.xyz += Spec * 20.0 * ShadowResult.x * AoTex.x * _LightColor0.xyz * EnvColor;


				// secondary spec
				float Spec2 = _calc_Specular2_custom_optimize2_Self(wNormal.xyz, viewDir, NdotV, fresnel, matal) * 100;
				OutColor.xyz += _SkinSpec * Spec2 *(_SkyColor.xyz + _StaticLightColor.xyz * SceneHalfLambert) * _SelfSpecWeight * _SelfSpecColor.rgb;
				
				OutColor.xyz = ToneMapping(OutColor.xyz, _HDR_Multiply);
				//need gamma correction before into the framebuffer when linear space on
				OutColor.xyz = pow(OutColor.xyz, 2.2);

				UNITY_APPLY_FOG(i.fogCoord, OutColor);
				return OutColor;
			}
			ENDCG
		}
		}

			Fallback "VertexLit"
}
