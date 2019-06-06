Shader "GEffect/BD_OpacityCommon"
{
	Properties
	{
		_Color ("Main Color", Color)=(1,1,1,1)
		_MainTex ("Diffuse", 2D) = "grey" {}
		_MaskTex ("Mask", 2D) = "grey" {}
		_NormalTex ("Normal", 2D) = "normal" {}
		_AO("AO Texture", 2D) = "white"{}
		_DetailNormalTex("DetailNormal", 2D) = "normal"{}
		_MaterialTex("Material", 2D) = "normal"{}
		_Cube ("Cubemap", CUBE) = "" {}
		[Gamma]_SkyColor("SkyColor", Color) = (0.548828	,0.548828	,0.548828	,0.5)
		_StaticLightColor("LightColor", Color) = (0.548828	,0.548828	,0.548828	,0.5)
		_StaticLightDir("LightDir", Vector) = (-0.07473408,	0.0,	-0.9972036, 0)
		[Gamma]_ReflectColor("ReflectColor", Color) = (0.548828	,0.548828	,0.548828	,0.5)
		_CustomizeInfo("CustomizeInfo" ,Vector) = (0,0,0,0)
		_CustomizeInfoDetails("CustomizeInfoDetails" ,Vector) = (0,0,0,0)
		_DetailNormalTile("DetailNormalTile", Float) = 1.0
		_SkinSpec ("SkinSpec ", Range(0,1)) = 0.31

		_BleachBypassRate("_BleachBypassRate", Range(0,1)) = 0.5
		_BlackLevel("_BlackLevel", Float) = 0
		_HDR_Multiply("_HDR_Multiply", Range(0,1)) = 0.5
		

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
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

			
			
			fixed4 frag (v2f i) : SV_Target
			{

				float4 FinalColor = half4(1,1,1,1);
				
				int isFrontFacing = 1;
				float4 texBase = tex2Dbias (_MainTex, half4(i.uv, 0, -0.5));
				float4 texMask = tex2D (_MaskTex, i.uv);
				float4 texMaterial = tex2D (_MaterialTex, i.uv);
				float3 texNormal = tex2Dbias (_NormalTex, half4(i.uv, 0, -1.5)).xyz - 0.5;
				

				float mat = saturate(texMaterial.w * 2);
				mat = saturate(mat * 2.0 - 1);
				float smooth = texMaterial.y;
				float roughness = 1.0 - smooth;				
				float temp8 = 1.0 - abs(texMaterial.w * 2.0 - 1.0);
				float temp9 = saturate(texMaterial.x * 2.0);
				temp9 = saturate(texMaterial.x *2.0 - 1.0 + temp9);
				float temp10 = 1.0 - saturate(mat + temp8 + temp9);
				float3 wNormal = i.world_normal;
				
				float3 wNormal0 = wNormal;
				float temp14 = abs(texMaterial.w - 0.5) * 2.0;
				
				float3 DetailNormal = tex2Dbias(_DetailNormalTex, half4(i.uv * _DetailNormalTile, 0, -1.5)).xyz - 0.5;
				texNormal += DetailNormal.xyz *  mat * 0.2 * temp14 * _CustomizeInfoDetails.w;
				float2 texNormalXY = texNormal.xy *(5.0 - 4.0 * mat);
				wNormal += texNormalXY.x * i.world_tangent.xyz + texNormalXY.y * i.world_binormal;
				texNormalXY = lerp(texNormal.xy , texNormal.xy * 5.0, temp14);
				wNormal0 += texNormalXY.x * i.world_tangent.xyz + texNormalXY.y * i.world_binormal;

				//invert unity's built-in gamma
				texBase.xyz = pow(texBase.xyz, (0.45, 0.45, 0.45));
				texBase.xyz = pow(texBase.xyz, (2.0 + mat * 0.6).xxx); //线性空间
				texBase.xyz *= 1.0 + mat * 0.5; 
				
				float4 AoTex = tex2Dbias (_AO, half4(i.uv, 0, -0.5)); //AO

				texBase.xyz *= saturate(AoTex.x * 1.3);
				
				if(texBase.w < 0.6)
				{
					discard;
				}
				texBase.xyz /= texBase.w * texBase.w;
				
				half4 OutColor = half4(0,0,0,0);
				float temp24 = 1.0;
				float temp23 = temp8;
				
				if ( _CustomizeInfo.w > 1.0 )
				{
					
					float4 color1 = _decodeRGBA(_CustomizeInfoDetails.x);
					float4 color2 = _decodeRGBA(_CustomizeInfoDetails.y);
					float4 color3 = _decodeRGBA(_CustomizeInfoDetails.z);
					
					fixed4 texMask = tex2D (_MaskTex, i.uv);
					float3 col = texBase.xyz;
					col.xyz = (dot(OutColor.xyz, float3(0.222, 0.70700002, 0.071000002)) - 0.5).xxx;
					col.xyz *= 0.5;
					col.xyz = clamp((col.xyz + 0.5) * 1.3, 0.0, 1.0);
					texBase.xyz = lerp(texBase.xyz, (col.xyz * _colorCorrect(color1.xyz) * 0.5), texMask.x);
					texBase.xyz = lerp(texBase.xyz, (col.xyz * _colorCorrect(color2.xyz) * 0.5), texMask.y);
					texBase.xyz = lerp(texBase.xyz, (col.xyz * _colorCorrect(color3.xyz) * 0.5), texMask.z);
					
				}
				else{
					if( _CustomizeInfo.w >= 0 )
					{
						float4 Masktextemp = float4(0,0,0,0);
						float temp40 = _SkinSpec;//_CustomizeData
						if(_Color.w > 0.5)//Eye
						{
							
							float4 ColorTemp34 = _decodeRGBA(_CustomizeData1.y); //Y Color , X EyeDirction(0,1), w z :Offset
							int _eyeIndex = int(_CustomizeData1.x + 12);
							float2 MaskUV = i.uv;
							float temp35 = (1.0 - _CustomizeData1.w) * 1.5 + 0.1;
							float temp36 = (1.0 - _CustomizeData1.z) * 2.0 + 0.1;
							float temp37 = _CustomizeData2.w - 0.5;
							MaskUV -= 0.5;
							MaskUV.x *= temp35 * temp36;
							MaskUV.y *= temp35;
							MaskUV +=0.5;
							MaskUV.y += temp37 *0.5;
							MaskUV = saturate(MaskUV);
							MaskUV.x = (MaskUV.x + int(_eyeIndex % 4)) * 0.25;
							MaskUV.y = (MaskUV.y + int(_eyeIndex / 4)) * 0.25;
							Masktextemp = tex2D(_MaskTex, MaskUV);
							
							
							float temp55 =  1.0 - _CustomizeData3.w + 0.25;

							Masktextemp.y += pow(Masktextemp.y, 0.60000002 + temp55* temp55* temp55) + 0.67000002;
							Masktextemp.y = pow (Masktextemp.y, 0.55000001);
							float _thick = Masktextemp.y * _CustomizeData2.y;
							texBase.xyz = lerp(texBase.xyz, texBase.xyz * ColorTemp34.xyz , _thick);
							

							ColorTemp34 = _decodeRGBA(_CustomizeData3.y);
							_eyeIndex = int(_CustomizeData3.x + 12);
							MaskUV = i.uv;
							MaskUV -= 0.5;
							MaskUV.x *= temp35 * temp36;
							MaskUV.y *= temp35;
							MaskUV += 0.5;
							MaskUV.y += temp37 * 0.5;
							MaskUV = saturate(MaskUV);
							MaskUV.x = (MaskUV.x + int(_eyeIndex % 4)) * 0.25;
							MaskUV.y = (MaskUV.y + int(_eyeIndex / 4)) * 0.25;
							Masktextemp =  tex2D(_MaskTex, MaskUV); 

							float3 ColorTemp39 = texBase.xyz * ColorTemp34.xyz + ColorTemp34.xyz * dot(ColorTemp34.xyz , float3(1.0,1.0,1.0)).xxx * 0.02;
							_thick = saturate(Masktextemp.z * _CustomizeData2.z * 2.0);
							temp40 = max(temp40 , _CustomizeData1.z);
							texBase.xyz = lerp(texBase.xyz ,ColorTemp39, _thick );
							
							
							ColorTemp34 = _decodeRGBA(_CustomizeData0.y);
							_eyeIndex = int(_CustomizeData0.x + 12);
							MaskUV = i.uv;
							temp35 = (1.0 - _CustomizeData0.w) * 1.5 + 0.1;
							temp36 = (1.0 - _CustomizeData0.z) * 2.0 + 0.1;
							MaskUV -= 0.5;
							MaskUV.x *= temp35 * temp36;
							MaskUV.y *= temp35;
							MaskUV += 0.5;
							MaskUV.y += temp37 *temp35 * 0.5;
							MaskUV = saturate(MaskUV);
							MaskUV.x = (MaskUV.x + int(_eyeIndex % 4)) * 0.25;
							MaskUV.y = (MaskUV.y + int(_eyeIndex / 4)) * 0.25;
							Masktextemp =  tex2D(_MaskTex, MaskUV);
														
							_thick = saturate(Masktextemp.x * _CustomizeData2.x * 1.2);
							float3 ColorTemp41 = texBase.xyz * ColorTemp34.xyz + ColorTemp34.xyz * dot(ColorTemp34.xyz , float3(1.0,1.0,1.0)).xxx * 0.1;
							texBase.xyz = lerp(texBase.xyz, ColorTemp41, _thick); 
												
						}
						else{
							if(_Color.w < 0.5)
							{//皮肤
								
								float3 ColorTemp31 = texBase.xyz;
								
								texBase.xyz *= lerp(texBase.xyz, _colorCorrect(_Color.xyz) * 0.5, _CustomizeInfoDetails.w);
								
								float2 MaskUV = float2(0,0);
								float4 ColorTemp58 = _decodeRGBA(_CustomizeData3.y);

								//眉毛
								float temp32 = dot(float3(1,1,1), ColorTemp58) * 0.33333299;
								int _eyebrowIndex = int(_CustomizeData3.x + 3);
								float temp59 = _CustomizeData3.z - 0.5;
								MaskUV.y = i.uv.y + temp59 * 0.05;
								MaskUV.x = (i.uv.x + _eyebrowIndex % 2 ) * 0.5;
								MaskUV.y = (MaskUV.y + _eyebrowIndex / 2) * 0.5;
								Masktextemp = tex2D(_MaskTex, MaskUV);//_paParam_29
								float temp64 = 1.0 - _CustomizeData3.w + 0.25;
								Masktextemp.y = pow(Masktextemp.y, (0.6 + temp64 * temp64 * temp64));
								float _rate = saturate(Masktextemp.y * _CustomizeData4.x);
								float3 ColorTemp65 = saturate(ColorTemp31.xyz - temp32) + ColorTemp58;
								ColorTemp65 *= saturate(ColorTemp58.xyz * ColorTemp58.xyz *0.5);
								texBase.xyz = lerp(texBase.xyz, ColorTemp65, _rate);
								float temp62 = _rate;
								
								//眼影
								float4 ColorTemp66 = _decodeRGBA(_CustomizeData1.y);
								ColorTemp66.xyz = _colorCorrect(ColorTemp66.xyz);
								int _eyeIndex = int(_CustomizeData1.x + 3);
								MaskUV.x = (i.uv.x + _eyeIndex % 2 ) * 0.5;
								MaskUV.y = (i.uv.y + _eyeIndex / 2 ) * 0.5;
								Masktextemp = tex2D(_MaskTex, MaskUV);//_paParam_29
								temp64 = 1.0 - _CustomizeData1.w + 0.25;
								Masktextemp.x = pow(Masktextemp.x, (0.6 + temp64 * temp64 * temp64)) * 1.22;
								_rate = saturate(Masktextemp.x * _CustomizeData1.z);
								ColorTemp65 = lerp( ColorTemp31.xyz * ColorTemp66.xyz , texBase.xyz * ColorTemp66.xyz, temp62);
								//
								texBase.xyz = lerp(texBase.xyz, saturate(ColorTemp65), _rate);
								temp40 = max(temp40,_CustomizeData5.x * _rate );
								texMaterial.z += max(texMaterial.z, _CustomizeData5.y * _rate * 0.5);
								temp24 += _CustomizeData5.y * _rate;//_paParam_24
								
								//嘴型
								int _lipIndex = int(_CustomizeData0.x + 3);
								float4 ColorTemp71 = _decodeRGBA(_CustomizeData0.y);
								MaskUV.x = (i.uv.x + _lipIndex % 2 ) * 0.5;
								MaskUV.y = (i.uv.y + _lipIndex / 2 ) * 0.5;
								Masktextemp = tex2D(_MaskTex, MaskUV);//_paParam_29
								
								Masktextemp.w = (1.0 - Masktextemp.w);
								
								temp64 = 1.0 - _CustomizeData0.w + 0.25;
								Masktextemp.w = pow(Masktextemp.w, (0.6 + temp64 * temp64 * temp64));
								_rate = saturate(Masktextemp.w * _CustomizeData0.z);
								texBase.xyz = lerp(texBase.xyz, ColorTemp31.xyz * ColorTemp71.xyz * ColorTemp71.xyz, saturate(_rate));
								
								temp24 += _CustomizeData5.z * _rate;
								texMaterial.z += max(texMaterial.z, _CustomizeData5.z * _rate * 0.5);
								_rate = _rate * _CustomizeData4.w; 
								temp40 = max(temp40, 3 * _rate );
								



								//脸颊
								int _CheekIndex = int(_CustomizeData2.x + 3);
								ColorTemp71 = _decodeRGBA(_CustomizeData2.y);
								float temp77 =  1.0 - (_CustomizeData2.z + 0.5);
								MaskUV.x = (i.uv.x + _CheekIndex % 2 ) * 0.5;
								MaskUV.y = i.uv.y - temp77 * 0.1;
								MaskUV.y = (MaskUV.y +_CheekIndex / 2) * 0.5; 
								Masktextemp = tex2D(_MaskTex, MaskUV);//_paParam_29
								
								float temp79 = 1.0 - _CustomizeData2.w + 0.25;
								Masktextemp.z = pow(Masktextemp.z, (0.6 + temp79 * temp79 * temp79)) * 1.12;
								_rate = saturate(Masktextemp.z * _CustomizeData4.y);
								temp40 = max(temp40, _CustomizeData4.z * _rate );
								texBase.xyz = lerp(texBase.xyz, ColorTemp31.xyz * ColorTemp71.xyz , saturate(_rate));

							}
						}
						temp23 = temp40;
						
					}
				}
				
				float4 ShadowResult =half4(1,1,1,1);
				

				half3 normalVec = wNormal;
				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				
				half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				half NdotL = dot(normalVec, lightDir.xyz);
				half NdotV = dot(normalVec, viewDir);
				half LdotV = dot(lightDir.xyz, viewDir);
				
				float nDotlnormalize = NdotL * 0.5 + 0.5;

				float _light = nDotlnormalize * nDotlnormalize *6.0;
				
				_light = _calcOrenNayar3_optimize(lerp(NdotL, nDotlnormalize * 0.35, mat), NdotV, NdotL) * 6.0;


				//GI
				float atten = LIGHT_ATTENUATION(i);	

				float normalY = normalVec.y * 0.5 + 0.5; 

				OutColor.xyz = _LightColor0.xyz * _light * atten;

				OutColor.xyz +=  _SkyColor.xyz * normalY ;
						
				OutColor.xyz += 1.7 * _ReflectColor;
				
				
				float3 SceneLightColor = _StaticLightColor;
				float3 SceneLightDir = _StaticLightDir;//SceneLight
				float SceneNdotL = dot(normalVec, SceneLightDir);
				SceneNdotL = 0;
				float ScenenNdotLnormalize = SceneNdotL * 0.5 + 0.5;				
				ScenenNdotLnormalize *= lerp(ScenenNdotLnormalize * ScenenNdotLnormalize, 1.0 , saturate(SceneLightDir * 10.0 * mat));


				float3 SceneLight = SceneLightColor * ScenenNdotLnormalize * 0.25;
				SceneLight = max(SceneLight, SceneLightColor * mat * 0.05);

				OutColor.xyz += SceneLight;
				
				NdotV = saturate(NdotV);
				float inverseNdotV = max(1.0 - NdotV, 0);
				OutColor.xyz *= (1.0 + mat);
				
				OutColor *= half4(texBase.xyz, 0.0);
				
				normalVec = normalize(wNormal0);
				
				
				
				inverseNdotV *= (i.world_normal.y * 0.5 + 0.5);
				OutColor.xyz += inverseNdotV * inverseNdotV * NdotL * ShadowResult.x * 3.0 * _LightColor0.xyz;
				
				
				float3 _H2 = normalize(viewDir + SceneLightDir.xyz);
				float NdotH = saturate(dot(normalVec, _H2));
				float PowerNdotH = pow(NdotH, 30.0) * 0.1;
				float temp99 = inverseNdotV * ScenenNdotLnormalize + 0.01;
				OutColor.xyz += SceneLightColor.xyz * ( PowerNdotH * (1.0 - saturate(mat * 3.0 + texMaterial.x * 3.0)) + 2.0 * temp99 * temp99 *temp99 *temp99 );
				
				
				
				texMaterial.z = max(texMaterial.z, mat * 0.2);
				if(texMaterial.z > 0.05 && texMaterial.y > 0.05)
				{
					float temp100 = temp23 - 0.35;
					smooth *= 1.0 + temp100 * mat;
					float temp102 = lerp(8.0, 0.0, smooth);
					float3 CubeUV = reflect(-viewDir, normalVec);
					float3 CubeColor = texCUBElod(_Cube, float4(CubeUV,temp102)).xyz;
					CubeColor *= CubeColor * lerp(0.75, 0.25, mat);
					float fresnel = _fresnel_Optimize(texMaterial.z, NdotV);
					float matal = smooth * (1.3 - mat* 0.3);
					matal = min(matal, 1.0);
					float Spec = _calc_Specular2_custom_optimize2(normalVec.xyz, viewDir.xyz, lightDir.xyz, NdotV, fresnel, matal);//_paParam_109
					float3 SpecColor = lerp(normalize(texBase.xyz + 0.001), float3(0.02,0.02,0.02), mat);
					float3 EnvColor = _EnvBRDFApprox(SpecColor, pow(roughness, temp24), 1.0-max(NdotV, 0.0));
					EnvColor *= texMaterial.z;
					OutColor.xyz = lerp(OutColor.xyz, OutColor.xyz * float3(0.35,0.35,0.35), texMaterial.z * temp10);

										
					float3 sqLightColor = sqrt(_StaticLightColor.xyz * 4.0);
					sqLightColor += SceneLightColor.xyz * (1.0 - mat) * 7.0 * ScenenNdotLnormalize;
					OutColor.xyz *= lerp((1.0 - EnvColor)*(1.0 - texMaterial.z), float3(1.0,1.0,1.0), mat);
					
					
					OutColor.xyz += CubeColor * EnvColor * sqLightColor;
					
					OutColor.xyz += Spec * 20.0 * ShadowResult.x * AoTex.x * _LightColor0.xyz * EnvColor;
					//
					float Spec2 = _calc_Specular2_custom_optimize2_Self(wNormal.xyz, viewDir, NdotV, fresnel ,matal );

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
					
					OutColor.xyz += temp23 * (Spec2 * (10.0 + 30.0 * mat)).xxx * (sqrt(_SkyColor.xyz) * 0.5 + SceneLightColor.xyz * ScenenNdotLnormalize * 0.3) * EnvColor.xyz + i.ambient;
				}

				OutColor.xyz *= saturate(1.0 + 0.4);
				OutColor.w = 0;
				OutColor.xyz *= _SkyColor.w * 2.0;
				OutColor.xyz = min(OutColor.xyz, float3(5.5,5.5,5.5));
				OutColor.w = 1.0;
				OutColor.xyz = ToneMapping(OutColor.xyz, _HDR_Multiply);
				OutColor.xyz = pow(OutColor.xyz, 2.2);

				UNITY_APPLY_FOG(i.fogCoord, OutColor);
				return OutColor;
			}
			ENDCG
		}
	}
	
	Fallback "VertexLit"
}
