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
		_SkinSmoothness("_SkinSmoothness ", Range(0,1)) = 0.31
		_SkinF0 ("_SkinF0", Range(0.02, 0.08)) = 0.02

		_SelfSpecWeight("Self Specular Weight", Range(0,1)) = 1
		_SelfSpecColor("Self Specular Color", Color) = (1,0,0,0)

		_SSSWeight ("SSS Weight", Range(0, 1)) = 1
		_LookupDiffuseSpec("SSS Lut", 2D) = "gray" {}
		_SSSOffset ("SSS Offset", Range(-1, 1)) = 0
		_SSSPower ("SSS Power", float) = 1
		_SSSColor ("SSS Color", Color) = (1,1,1,1)

		[Header(Decal)]
		_DecalTex ("Decal Tex", 2D) = "black" {}
		[Header(BrowL)]
		_BrowLMakeupColor ("BrowL Makeup Color", Color) = (1,1,1,1)
		_BrowLMakeupAlpha ("BrowL Makeup Alpha", Range(0, 1)) = 0
		_BrowLMakeupScale ("BrowL Makeup Scale", Vector) = (1,1,1,1)
		_BrowLMakeupSmoothness ("BrowL Makeup Smoothness", Range(0, 1)) = 0
		_BrowLMakeupMetallic ("BrowL Makeup Metallic", Range(0, 1)) = 0
		_BrowLMakeupPos ("BrowL Makeup Pos", Vector) = (0,0,0,0)
		_BrowLMakeupSizeAndOffset ("BrowL Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_BrowLMakeupHSV ("BrowL Makeup HSV", Vector) = (0,0,0,0)
		[Header(BrowR)]
		_BrowRMakeupColor ("BrowR Makeup Color", Color) = (1,1,1,1)
		_BrowRMakeupAlpha ("BrowR Makeup Alpha", Range(0, 1)) = 0
		_BrowRMakeupScale ("BrowR Makeup Scale", Vector) = (1,1,1,1)
		_BrowRMakeupSmoothness ("BrowR Makeup Smoothness", Range(0, 1)) = 0
		_BrowRMakeupMetallic ("BrowR Makeup Metallic", Range(0, 1)) = 0
		_BrowRMakeupPos ("BrowR Makeup Pos", Vector) = (0,0,0,0)
		_BrowRMakeupSizeAndOffset ("BrowR Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_BrowRMakeupHSV ("BrowR Makeup HSV", Vector) = (0,0,0,0)
		[Header(EyeL)]
		_EyeLMakeupColor ("EyeL Makeup Color", Color) = (1,1,1,1)
		_EyeLMakeupAlpha ("EyeL Makeup Alpha", Range(0, 1)) = 0
		_EyeLMakeupScale ("EyeL Makeup Scale", Vector) = (1,1,1,1)
		_EyeLMakeupSmoothness ("EyeL Makeup Smoothness", Range(0, 1)) = 0
		_EyeLMakeupMetallic ("EyeL Makeup Metallic", Range(0, 1)) = 0
		_EyeLMakeupPos ("EyeL Makeup Pos", Vector) = (0,0,0,0)
		_EyeLMakeupSizeAndOffset ("EyeL Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_EyeLMakeupHSV ("EyeL Makeup HSV", Vector) = (0,0,0,0)
		[Header(EyeR)]
		_EyeRMakeupColor ("EyeR Makeup Color", Color) = (1,1,1,1)
		_EyeRMakeupAlpha ("EyeR Makeup Alpha", Range(0, 1)) = 0
		_EyeRMakeupScale ("EyeR Makeup Scale", Vector) = (1,1,1,1)
		_EyeRMakeupSmoothness ("EyeR Makeup Smoothness", Range(0, 1)) = 0
		_EyeRMakeupMetallic ("EyeR Makeup Metallic", Range(0, 1)) = 0
		_EyeRMakeupPos ("EyeR Makeup Pos", Vector) = (0,0,0,0)
		_EyeRMakeupSizeAndOffset ("EyeR Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_EyeRMakeupHSV ("EyeR Makeup HSV", Vector) = (0,0,0,0)
		[Header(Lip)]
		_LipMakeupColor ("Lip Makeup Color", Color) = (1,1,1,1)
		_LipMakeupAlpha ("Lip Makeup Alpha", Range(0, 1)) = 0
		_LipMakeupScale ("Lip Makeup Scale", Vector) = (1,1,1,1)
		_LipMakeupSmoothness ("Lip Makeup Smoothness", Range(0, 1)) = 0
		_LipMakeupMetallic ("Lip Makeup Metallic", Range(0, 1)) = 0
		_LipMakeupPos ("Lip Makeup Pos", Vector) = (0,0,0,0)
		_LipMakeupSizeAndOffset ("Lip Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_LipMakeupHSV ("Lip Makeup HSV", Vector) = (0,0,0,0)
		[Header(DecalL)]
		_DecalLMakeupColor ("DecalL Makeup Color", Color) = (1,1,1,1)
		_DecalLMakeupAlpha ("DecalL Makeup Alpha", Range(0, 1)) = 0
		_DecalLMakeupScale ("DecalL Makeup Scale", Vector) = (1,1,1,1)
		_DecalLMakeupSmoothness ("DecalL Makeup Smoothness", Range(0, 1)) = 0
		_DecalLMakeupMetallic ("DecalL Makeup Metallic", Range(0, 1)) = 0
		_DecalLMakeupPos ("DecalL Makeup Pos", Vector) = (0,0,0,0)
		_DecalLMakeupSizeAndOffset ("DecalL Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_DecalLMakeupHSV ("DecalL Makeup HSV", Vector) = (0,0,0,0)
		[Header(DecalR)]
		_DecalRMakeupColor ("DecalR Makeup Color", Color) = (1,1,1,1)
		_DecalRMakeupAlpha ("DecalR Makeup Alpha", Range(0, 1)) = 0
		_DecalRMakeupScale ("DecalR Makeup Scale", Vector) = (1,1,1,1)
		_DecalRMakeupSmoothness ("DecalR Makeup Smoothness", Range(0, 1)) = 0
		_DecalRMakeupMetallic ("DecalR Makeup Metallic", Range(0, 1)) = 0
		_DecalRMakeupPos ("DecalR Makeup Pos", Vector) = (0,0,0,0)
		_DecalRMakeupSizeAndOffset ("DecalR Makeup SizeAndOffset", Vector) = (1,1,0,0)
		_DecalRMakeupHSV ("DecalR Makeup HSV", Vector) = (0,0,0,0)

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

			float _SkinF0;
			float _SelfSpecWeight;
			float4 _SelfSpecColor;
			float _SSSWeight;

			sampler2D _LookupDiffuseSpec;
			float _SSSOffset;
			float _SSSPower;
			float3 _SSSColor;

			sampler2D _DecalTex;
			float4 _DecalTex_ST;
			DECLARE_DECAL_PROPERTIES(_DecalLMakeup)
			DECLARE_DECAL_PROPERTIES(_DecalRMakeup)
			DECLARE_DECAL_PROPERTIES(_LipMakeup)
			DECLARE_DECAL_PROPERTIES(_EyeLMakeup)
			DECLARE_DECAL_PROPERTIES(_EyeRMakeup)
			DECLARE_DECAL_PROPERTIES(_BrowLMakeup)
			DECLARE_DECAL_PROPERTIES(_BrowRMakeup)

			fixed4 frag(v2f i) : SV_Target
			{
				// base
				float4 texBase = tex2Dbias(_MainTex, half4(i.uv, 0, -0.5));
				float4 misc = tex2D(_MaterialTex, i.uv);
				// smoothness
				float smooth = misc.g;
				// thickness
				float thick = misc.r;
				// normal
				float3 texNormal = tex2Dbias(_NormalTex, half4(i.uv, 0, -1.5)).xyz - 0.5;
				float3 DetailNormal = tex2Dbias(_DetailNormalTex, half4(i.uv * _DetailNormalTile, 0, -1.5)).xyz - 0.5;
				texNormal += DetailNormal.xyz *  0.2 * _DetailNormalWeight;
				float3 wNormal = texNormal.x * i.world_tangent.xyz + texNormal.y * i.world_binormal + texNormal.z * i.world_normal;
				float3 wNormal0 = wNormal;//5 * texNormal.x * i.world_tangent.xyz + 5 * texNormal.y * i.world_binormal + texNormal.z * i.world_normal;
				// ao
				float4 AoTex = tex2Dbias(_AO, half4(i.uv, 0, -0.5)); //AO
				texBase.xyz *= saturate(AoTex.x * 1.3);

				float partSmoothness = _SkinSmoothness;
				float metallic = 0;

				float4 partBase = float4(0,0,0,0);
				
				CAL_FRAG_DECAL_UV_RGB(_DecalLMakeup, partBase, i.uv, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_DecalRMakeup, partBase, i.uv, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_LipMakeup, partBase, i.uv, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_EyeLMakeup, partBase, i.uv, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_EyeRMakeup, partBase, i.uv, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_BrowRMakeup, partBase, i.uv, partSmoothness, metallic);
				CAL_FRAG_DECAL_UV_RGB(_BrowLMakeup, partBase, i.uv, partSmoothness, metallic);
								

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

				half3 preintegrate = tex2D(_LookupDiffuseSpec, half2(halfLambert * atten, saturate((1 - thick + _SSSOffset)*_SSSPower))).rgb;
				
				// preintegrate *= preintegrate;
				half3 diff = 5 * preintegrate * atten;
				diff *= _SSSColor;
				OutColor.xyz *= lerp(1, diff, _SSSWeight);
				
				// Sky Light
				float normalY = wNormal.y * 0.5 + 0.5;
				OutColor.xyz += _SkyColor.xyz * normalY;
				OutColor.xyz += _AmbientColor;

				// Secondary Light
				float SceneNdotL = dot(wNormal, normalize(_StaticLightDir.xyz));
				float SceneHalfLambert = SceneNdotL * 0.5 + 0.5;
				SceneHalfLambert = max(SceneHalfLambert, 0.2);

				float3 outPart = partBase.rgb * OutColor.rgb;
				
				OutColor *= half4(texBase.xyz, 0.0);

				float4 ShadowResult = half4(1, 1, 1, 1); //TODO:?
				// Fake SSS
				// NdotV = saturate(NdotV);
				// float inverseNdotV = 1.0 - NdotV;
				// inverseNdotV *= (i.world_normal.y * 0.5 + 0.5);
				// float3 fakeSSS = inverseNdotV * inverseNdotV * min(0, NdotL) * ShadowResult.x * _LightColor0.xyz;
				// OutColor.xyz += fakeSSS * _SSSWeight;

				// 
				//float temp = inverseNdotV * SceneHalfLambert + 0.01;
				//OutColor.xyz += _StaticLightColor.xyz * temp;
				// main spec	
				float pSmooth = smooth;
				pSmooth *= 1.0 + partSmoothness;
				pSmooth = saturate(pSmooth);
				smooth *= 1.0 + _SkinSmoothness;
				smooth = saturate(smooth);
				wNormal0 = normalize(wNormal0);
				float fresnel = _fresnel_Optimize(_SkinF0, NdotV);
				float mtlFres = _fresnel_Optimize(0.98, NdotV);
				float smth = min(smooth, 1);
				float pSmth = min(pSmooth, 1);
				float Spec = _calc_Specular2_custom_optimize2(wNormal0.xyz, viewDir.xyz, lightDir.xyz, NdotV, fresnel, smth);//_paParam_109
				float mSpec = _calc_Specular2_custom_optimize2(wNormal0.xyz, viewDir.xyz, lightDir.xyz, NdotV, mtlFres, pSmth);//_paParam_109
				float pSpec = _calc_Specular2_custom_optimize2(wNormal0.xyz, viewDir.xyz, lightDir.xyz, NdotV, fresnel, pSmth);//_paParam_109
				pSpec = lerp(pSpec, mSpec, metallic);
				// Spec = lerp(Spec, SM, metallic);
				float3 EnvColor = _EnvBRDFApprox(_SkinF0, pow(1.0 - smooth, 1), 1.0 - max(NdotV, 0.0));

				
				// float3 rDir = BoxProjectedCubemapDirection(reflect(-viewDir.xyz, wNormal0), i.worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
                // half4 rgbm = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, rDir);
                // half3 reflectCol = DecodeHDR(rgbm, unity_SpecCube0_HDR);

				float3 mEnv = _EnvBRDFApprox(0.98, pow(1.0 - pSmooth, 1), 1.0 - max(NdotV, 0.0)) * partBase.rgb;
				float3 pEnv = _EnvBRDFApprox(_SkinF0, pow(1.0 - pSmooth, 1), 1.0 - max(NdotV, 0.0));
				pEnv = lerp(pEnv, mEnv, metallic);
				// EnvColor = lerp(EnvColor, MtlColor, metallic);
				// EnvColor *= partSpecular;
				OutColor.xyz += Spec * 20.0 * ShadowResult.x * AoTex.x * _LightColor0.xyz * EnvColor;
				outPart += pSpec * 20.0 * ShadowResult.x * AoTex.x * _LightColor0.xyz * pEnv * partBase.a;


				// secondary spec
				float Spec2 = _calc_Specular2_custom_optimize2_Self(wNormal.xyz, viewDir, NdotV, fresnel, smth) * 100;
				OutColor.xyz += _SkinSmoothness * Spec2 *(_SkyColor.xyz + _StaticLightColor.xyz * SceneHalfLambert) * _SelfSpecWeight * _SelfSpecColor.rgb;
				// float pSpec2 = _calc_Specular2_custom_optimize2_Self(wNormal.xyz, viewDir, NdotV, mtlFres, pSmth) * 100;
				// outPart.xyz += partSmoothness * pSpec2 *(_SkyColor.xyz + _StaticLightColor.xyz * SceneHalfLambert) * _SelfSpecWeight * _SelfSpecColor.rgb;
				
				OutColor.xyz = ToneMapping(OutColor.xyz, _HDR_Multiply);
				outPart = ToneMapping(outPart, _HDR_Multiply);
				//need gamma correction before into the framebuffer when linear space on
				OutColor.xyz = pow(OutColor.xyz, 2.2);
				outPart = pow(outPart, 2.2);
				
				OutColor.xyz = lerp(OutColor.xyz, outPart, partBase.a);

				UNITY_APPLY_FOG(i.fogCoord, OutColor);
				return OutColor;
			}
			ENDCG
		}
		}

			Fallback "VertexLit"
}
