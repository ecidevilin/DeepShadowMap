Shader "GEffect/BD_Skin"
{
	Properties
	{
		_Color("Main Color (Use alpha to blend)", Color) = (1,1,1,1)
		_MainTex("Diffuse", 2D) = "white" {}

		_MaskTex("Mask", 2D) = "grey" {}
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

		[Header(Customize)]
		[Toggle]
		_CustomizeInfo("CustomizeInfo" ,float) = 0
		[Header(Eyebrow)]
		_EyebrowColor("Eyebrow Color", Color) = (1	,0	,0	,0)
		_EyebrowThick("Eyebrow Thick", Range(0,1)) = 0.24
		_EyebrowHeight("Eyebrow Height", Range(0,1)) = 0.32
		_EyebrowShape("Eyebrow Shape", Range(0,15)) = 0
		[Header(EyeShadow)]
		_EyeShadowColor("EyeShadow Color", Color) = (1	,0	,0	,0)
		_EyeShadowShade("EyeShadow Shade", Range(0,1)) = 1
		_EyeShadowPower("EyeShadow Power", Range(0,1)) = 0.05
		_EyeShadowShape("EyeShadow Shape", Range(0,15)) = 0
		_EyeShadowSpec("EyeShadow Spec", Range(0,10)) = 0.15
		_EyeShadowSmooth("_EyeShadowS smooth", Range(0,1)) = 0
		[Header(Mouth)]
		_MouthColor("Mouth Color", Color) = (1	,0	,0	,0)
		_MouthShade("Mouth Shade", Range(0,1)) = 0.42
		_MouthPower("Mouth Power", Range(0,1)) = 1
		_MouthShape("Mouth Shape", Range(0,15)) = 0
		_MouthSpec("Mouth Spec", Range(0,10)) = 0.35
		_MouthSmooth("Mouth smooth", Range(0,1)) = 0
		[Header(Cheeck)]
		_CheekColor("Cheek Color", Color) = (1	,0	,0	,0)
		_CheekHeight("Cheek Height", Range(0,1)) = 0
		_CheekPower("Cheek Power", Range(0,1)) = 0.71
		_CheekShape("Cheek Shape", Range(0,15)) = 1
		_CheekSmooth("Cheek smooth", Range(0,1)) = 0


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


			float4 _EyebrowColor;
			float _EyebrowHeight;
			float _EyebrowShape;
			float _EyebrowThick;

			float4 _EyeShadowColor;
			float _EyeShadowShade;
			float _EyeShadowPower;
			float _EyeShadowShape;
			float _EyeShadowSpec;
			float _EyeShadowSmooth;

			float4 _MouthColor;
			float _MouthShade;
			float _MouthPower;
			float _MouthShape;
			float _MouthSpec;
			float _MouthSmooth;

			float4 _CheekColor;
			float _CheekHeight;
			float _CheekPower;
			float _CheekShape;
			float _CheekSmooth;

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

				// parts
				float partSpecPow = 1.0;
				float partSmooth = _SkinSpec;
				float partSpec = 0;
				if (_CustomizeInfo >= 1)
				{
					texBase.xyz *= lerp(1, _Color.xyz, _Color.a);

					//eyebrow
					float2 MaskUV = float2(0,0);
					int _eyebrowIndex = int(_EyebrowShape + 3);
					MaskUV.y = i.uv.y + (_EyebrowHeight - 0.5) * 0.05;
					MaskUV.x = (i.uv.x + _eyebrowIndex % 2) * 0.5;
					MaskUV.y = (MaskUV.y + _eyebrowIndex / 2) * 0.5;
					float pwr = 1.0 - _EyebrowThick + 0.25;
					float eyeBrowGray = tex2D(_MaskTex, MaskUV).g;//_paParam_29
					eyeBrowGray = pow(eyeBrowGray, (0.6 + pwr * pwr * pwr));
					float blend = saturate(eyeBrowGray * _EyebrowColor.w);
					float eyeBrowOcc = dot(float3(1, 1, 1), _EyebrowColor) * 0.333;
					float3 eyeBrowCol = saturate(texBase.xyz - eyeBrowOcc) + _EyebrowColor.xyz;
					eyeBrowCol *= saturate(_EyebrowColor.xyz * _EyebrowColor.xyz *0.5);
					texBase.xyz = lerp(texBase.xyz, eyeBrowCol, blend);

					//eyeShadow
					int _eyeIndex = int(_EyeShadowShape + 3);
					MaskUV.x = (i.uv.x + _eyeIndex % 2) * 0.5;
					MaskUV.y = (i.uv.y + _eyeIndex / 2) * 0.5;
					float eyeShadowGray = tex2D(_MaskTex, MaskUV).r;//_paParam_29
					pwr = 1.0 - _EyeShadowPower + 0.25;
					eyeShadowGray = pow(eyeShadowGray, (0.6 + pwr * pwr * pwr)) * 1.22;
					blend = saturate(eyeShadowGray * _EyeShadowShade);
					float3 eyeShadowCol = lerp(texBase.xyz * _EyeShadowColor.xyz , texBase.xyz * _EyeShadowColor.xyz, blend);
					texBase.xyz = lerp(texBase.xyz, saturate(eyeShadowCol), blend);
					partSmooth = max(partSmooth,_EyeShadowSmooth * blend);
					partSpec += max(partSpec, _EyeShadowSpec * blend * 0.5);
					partSpecPow += _EyeShadowSpec * blend;//_paParam_24

					//lip
					int _lipIndex = int(_MouthShape + 3);
					MaskUV.x = (i.uv.x + _lipIndex % 2) * 0.5;
					MaskUV.y = (i.uv.y + _lipIndex / 2) * 0.5;
					pwr = 1.0 - _MouthPower + 0.25;
					float lipGray = 1.0 - tex2D(_MaskTex, MaskUV).a;//_paParam_29
					lipGray = pow(lipGray, (0.6 + pwr * pwr * pwr));
					blend = saturate(lipGray * _MouthShade);
					texBase.xyz = lerp(texBase.xyz, texBase.xyz * _MouthColor.xyz * _MouthColor.xyz, saturate(blend));
					partSmooth = max(partSmooth, blend * _MouthSmooth);
					partSpec += max(partSpec, _MouthSpec * blend * 0.5);
					partSpecPow += _MouthSpec * blend;

					//cheek
					int _CheekIndex = int(_CheekShape + 3);
					MaskUV.x = (i.uv.x + _CheekIndex % 2) * 0.5;
					MaskUV.y = i.uv.y - 0.05 + _CheekHeight * 0.1;
					MaskUV.y = (MaskUV.y + _CheekIndex / 2) * 0.5;
					pwr = 1.0 - _CheekPower + 0.25;
					float cheekGray = tex2D(_MaskTex, MaskUV).b;//_paParam_29
					cheekGray = pow(cheekGray, (0.6 + pwr * pwr * pwr)) * 1.12;
					blend = saturate(cheekGray * _CheekColor.w);
					partSmooth = max(partSmooth, _CheekSmooth * blend);
					texBase.xyz = lerp(texBase.xyz, texBase.xyz * _CheekColor.xyz , saturate(blend));
				}


				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				half NdotL = dot(wNormal, lightDir.xyz);
				half NdotV = dot(wNormal, viewDir);
				half LdotV = dot(lightDir.xyz, viewDir);
							   
				//GI

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
				float SceneNdotL = dot(wNormal, _StaticLightDir); //SceneNdotL = 0;//游戏中此值为0
				float SceneHalfLambert = SceneNdotL * 0.5 + 0.5;
				SceneHalfLambert = max(SceneHalfLambert, 0.2);

				OutColor *= half4(texBase.xyz, 0.0);

				// Fake Specular
				float4 ShadowResult = half4(1, 1, 1, 1); //TODO:?
				NdotV = saturate(NdotV);
				float inverseNdotV = 1.0 - NdotV;
				inverseNdotV *= (i.world_normal.y * 0.5 + 0.5);
				OutColor.xyz += inverseNdotV * inverseNdotV * NdotL * ShadowResult.x * 3.0 * _LightColor0.xyz;

				// Fake sss
				float temp99 = inverseNdotV * SceneHalfLambert + 0.01;
				OutColor.xyz += _StaticLightColor.xyz * (2.0 * temp99 * temp99 *temp99 *temp99);



				partSpec = max(partSpec, 0.2);

				if (partSpec > 0.05 && smooth > 0.05)
				{
					smooth *= 1.0 + partSmooth - 0.35;
					wNormal0 = normalize(wNormal0);
					float fresnel = _fresnel_Optimize(partSpec, NdotV);
					float matal = min(smooth, 1);
					float Spec = _calc_Specular2_custom_optimize2(wNormal0.xyz, viewDir.xyz, lightDir.xyz, NdotV, fresnel, matal);//_paParam_109
					float3 SpecColor = 0.02;
					float3 EnvColor = _EnvBRDFApprox(SpecColor, pow(1.0 - smooth, partSpecPow), 1.0 - max(NdotV, 0.0));
					EnvColor *= partSpec;


					//float3 sqLightColor = sqrt(_StaticLightColor.xyz * 4.0);
					//float cubeLod = lerp(8.0, 0.0, smooth);
					//float3 CubeUV = reflect(-viewDir, wNormal0);
					//float3 CubeColor = texCUBElod(_Cube, float4(CubeUV, cubeLod)).xyz;
					//CubeColor *= CubeColor * 0.25;
					//OutColor.xyz += CubeColor * EnvColor * sqLightColor;

					OutColor.xyz += Spec * 20.0 * ShadowResult.x * AoTex.x * _LightColor0.xyz * EnvColor;

					float Spec2 = _calc_Specular2_custom_optimize2_Self(wNormal.xyz, viewDir, NdotV, fresnel ,matal);

					OutColor.xyz += partSmooth * (Spec2 * 40).xxx *(sqrt(_SkyColor.xyz) * 0.5 + _StaticLightColor.xyz * SceneHalfLambert * 0.3) * EnvColor.xyz;
				}

				OutColor.xyz = min(OutColor.xyz, float3(5.5,5.5,5.5));
				OutColor.w = 1.0;
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
