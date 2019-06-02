Shader "Unlit/EyeBall"
{
    Properties
    {

		[Header(Iris)]
		_IrisColor("Iris Color", 2D) = "white" {}
		_IrisUVRadius("Iris UV Radius", Range(0, 0.5)) = 0.15
		[HDR]
		_IrisBrightness("Iris Brightness", Color) = (1,1,1,1)
		_IrisConcavityScale("Iris Concavity Scale", Range(0, 4)) = 0.112
		_IrisConcavityPower("Iris Concavity Power", Range(0.1, 2)) = 0.277
		_IrisSmoothness("Iris Smoothmess", float) = 0.1
		_IrisSpecular("Iris Specular", float) = 0.3
		_PupilScale("Pupil Scale", Range(0, 1)) = 0.7

        [Header(Refration)]
        [NoScaleOffset]
        _EyeMidPlaneDisplacement ("Eye Mid Plane Displacement", 2D) = "white" {}
        _RoRI ("Reciprocal of Refractive Index", Range(0.1, 1)) = 0.7485
        _DepthScale ("Depth Scale", Range(0,2)) = 1.2
        _DepthPlaneOffset ("Depth Offset", Range(0, 1)) = 0.5

        [Header(Sclera)]
        [NoScaleOffset]
        _ScleraColor ("Sclera Color", 2D) = "white" {}
        [HDR]
        _ScleraBrightness ("Sclera Brightness", Color) = (0.9, 0.9,0.9,1)
        _ScleraSmoothness ("Sclera Smoothmess", float) = 0.1
        _ScleraSpecular ("Sclera Specular", float) = 0.3
        _ScleraInnerColor ("Sclera Inner Color", Color) = (1,1,1,0)
        _ScleraOuterColor ("Sclera Outer Color", Color) = (1,1,1,0)
        _Veins ("Veins", Range(0, 10)) = 1

        [Header(Limbus)]
		_LimbusUVWidthColor("Limbus UV Width Color", float) = 0.035
        _LimbusUVWidthShading ("Limbus UV Width Shading", float) = 0.045
        _LimbusDarkScale ("Limbus Dark Scale", float) = 2.15
        _LimbusPow ("Limbus Pow", float) = 8

        [Header(Normal)]
        [NoScaleOffset]
        _EyeNormals ("Eye Normals", 2D) = "bump" {}
        _NormalUVScale ("Normal UV Scale", float) = 0.4
        [NoScaleOffset]
        _EyeWetNormal ("Eye Wet Normal", 2D) = "bump" {}
        _FlattenNormal ("Flattern Normal", float) = 0.95

        [Header(Shadow)]
        _ShadowRadius ("Shadow Radius", float) = 0.65
        _ShadowHardness ("Shadow Hardness", float) = 0.1

        [Header(Environment)]
		[NoScaleOffset]
		_OcclusionTex("Occlusion Texture (R-AO, G-SO)", 2D) = "white" {}
		_AOScale("AO Scale", float) = 1
		_SOScale("SO Scale", float) = 1
        //_SecondaryEnvRotation ("Secondary Env Rotation", Range(0, 360)) = 0
        //_SecondaryEnvRotationAxis ("Secondary Env Rotation Axis", Vector) = (0,0,1,1)
        //[NoScaleOffset]
        //_SecondaryEnv ("Secondary Env", CUBE) = "white" {}
        //_SecondaryEnvBalance ("Secondary Env Balance", Color) = (0,0,0,1)

        _ReflectionSpecular ("Reflection Specular", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vertEye
            #pragma fragment fragEye
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityStandardUtils.cginc"
            #include "UnityStandardCore.cginc"
            //#include "../Hair/Resources/Include/Quaternion.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 vvec : TEXCOORD1;
				half4 ambientOrLightmapUV             : TEXCOORD2;    // SH or Lightmap UV
                float4 tangentToWorldAndPackedData[3] : TEXCOORD3; 
                UNITY_FOG_COORDS(6)
            };

            float _RoRI;
            float _LimbusUVWidthColor;
			float _LimbusUVWidthShading;
            float _DepthScale;
            sampler2D _EyeMidPlaneDisplacement;
            float _IrisUVRadius;
            sampler2D _EyeNormals;
            float _DepthPlaneOffset;

            float _NormalUVScale;
            sampler2D _EyeWetNormal;
            float _FlattenNormal;
            float _IrisConcavityScale;
            float _IrisConcavityPower;

            float _ScleraSmoothness;
            float _IrisSmoothness;
            float _ScleraSpecular;
            float _IrisSpecular;

            float _PupilScale;
            sampler2D _IrisColor;
            float4 _IrisColor_ST;
            float3 _IrisBrightness;
            float _LimbusDarkScale;
            float _LimbusPow;

            float _ShadowRadius;
            float _ShadowHardness;

            float3 _ScleraOuterColor;
            float3 _ScleraInnerColor;
            sampler2D _ScleraColor;
            float _Veins;
            float3 _ScleraBrightness;

            
            samplerCUBE _EnvInfo;
			float _AOScale;
			float _SOScale;
			sampler2D _OcclusionTex;
            //float _SecondaryEnvRotation;
            //float3 _SecondaryEnvRotationAxis;
            //samplerCUBE _SecondaryEnv;
            //float3 _SecondaryEnvBalance;

            float3 _ReflectionSpecular;


            inline half4 VertexGIForward(appdata v, float3 posWorld, half3 normalWorld)
            {
                half4 ambientOrLightmapUV = 0;
                // Static lightmaps
                #ifdef LIGHTMAP_ON
                    ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                    ambientOrLightmapUV.zw = 0;
                // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
                #elif UNITY_SHOULD_SAMPLE_SH
                    #ifdef VERTEXLIGHT_ON
                        // Approximated illumination from non-important point lights
                        ambientOrLightmapUV.rgb = Shade4PointLights (
                            unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                            unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                            unity_4LightAtten0, posWorld, normalWorld);
                    #endif

                    ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
                #endif

                #ifdef DYNAMICLIGHTMAP_ON
                    ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif

                return ambientOrLightmapUV;
            }

            v2f vertEye (appdata v)
            {
                v2f o;
                float4 wp = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = mul(UNITY_MATRIX_VP, wp);
                o.uv.xy = TRANSFORM_TEX(v.uv, _IrisColor); //no _DetailAlbedoMap
                o.vvec = normalize(WorldSpaceViewDir(v.vertex));
                float3 wn = UnityObjectToWorldNormal(v.normal);
                float4 wt = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

                float3x3 t2w = CreateTangentToWorldPerVertex(wn, wt.xyz, wt.w);
                o.tangentToWorldAndPackedData[0] = float4(t2w[0], wp.x);
                o.tangentToWorldAndPackedData[1] = float4(t2w[1], wp.y);
                o.tangentToWorldAndPackedData[2] = float4(t2w[2], wp.z);

                o.ambientOrLightmapUV = VertexGIForward(v, wp, wn);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float2 IrisUVMask(float2 uv)
            {
				float2 l = float2(_LimbusUVWidthColor, _LimbusUVWidthShading);
                float2 r = (length(uv - 0.5f) - (_IrisUVRadius - l)) / l;
                return smoothstep(0, 1, saturate(1 - r));
            }

            float3 RefractionDirection(float3 n, float3 v)
            {
                float r = _RoRI;
                float w = r * dot(n, v);
                float k = sqrt(1 + (w - r) * (w + r));
                float3 t = (w - k) * n - r * v;
                return -normalize(t);
            }

            void EyeRefraction(float2 uv, float3 v, float3 n, float3 wn, float3 wt, out float2 irisMask, out float2 refactUV)
            {
				irisMask = IrisUVMask(uv);

                float dep = tex2D(_EyeMidPlaneDisplacement, uv).r;
				dep = max(0, dep - _DepthPlaneOffset) * _DepthScale;

                float von = dot(v, n);
                float d2i = dep / lerp(0.325, 1, von * von);
                
				float3 dt = normalize(wt - n * dot(wt, n));
                float3 db = cross(dt, n);

				float3 rd = RefractionDirection(wn, v) * d2i;
				float2 ruv = uv - _IrisUVRadius * float2(dot(rd, dt), dot(rd, db));

				refactUV = lerp(uv, ruv, irisMask.x);
            }

            float2 ScalePupils(float2 uv)
            {
                float2 c = uv - 0.5;
                return lerp(normalize(c) * 0.5, float2(0, 0), saturate((1 - length(c) * 2) * _PupilScale)) + 0.5;
            }

            fixed4 fragEye (v2f i) : SV_Target
            {
                float4 tn = tex2D(_EyeNormals, i.uv);
				tn.xyz = tn.xyz * 2.0f - 1.0f;
                
                float3 wt = normalize(i.tangentToWorldAndPackedData[0].xyz);
                float3 wb = normalize(i.tangentToWorldAndPackedData[1].xyz);
                float3 wn = normalize(i.tangentToWorldAndPackedData[2].xyz);
                float3 wv = normalize(i.vvec);
				float3 wp = float3(i.tangentToWorldAndPackedData[0].w, i.tangentToWorldAndPackedData[1].w, i.tangentToWorldAndPackedData[2].w);

				tn.xyz = normalize(wt * tn.x + wb * tn.y + wn * tn.z);
                float2 irisMask;
                float2 refractedUV;
                EyeRefraction(i.uv, wv, tn, wn, wt, irisMask, refractedUV);

                float coat = irisMask.y;
                float blend = irisMask.x;

				float2 nuv = i.uv * _NormalUVScale + 0.5 - 0.5 * _NormalUVScale;
                float3 wetn = tex2D(_EyeWetNormal, nuv).rgb;
				wetn.xyz = wetn.xyz * 2.0f - 1.0f;
                float flat = lerp(_FlattenNormal, 1, blend);
                
                float3 norm = lerp(wetn, float3(0,0,1), flat);
				norm = normalize(wt * norm.x + wb * norm.y + wn * norm.z);
                
                float ccSmth = 1-pow(length(refractedUV - 0.5) / _IrisUVRadius * _IrisConcavityScale, _IrisConcavityPower);

                float smth = lerp(_ScleraSmoothness, _IrisSmoothness, blend);
                float spec = lerp(_ScleraSpecular, _IrisSpecular, blend);

				float2 irUV = (refractedUV - 0.5) * 0.5 / _IrisUVRadius + 0.5;
				irUV = ScalePupils(irUV);
                float3 col = tex2D(_IrisColor, irUV).rgb * _IrisBrightness;

                float limbus = length((irUV - 0.5) * _LimbusDarkScale);
                limbus = 1 - pow(saturate(limbus), _LimbusPow);
				col *= limbus;

				float sphere = 1 - pow(length(i.uv.xy - 0.5) / _ShadowRadius, 1-_ShadowHardness);
                float3 mask = lerp(lerp(_ScleraOuterColor, 1, sphere), lerp(1, _ScleraInnerColor, sphere), sphere);
                float3 sclera = tex2D(_ScleraColor, i.uv).rgb;
				sclera = lerp(1, sclera, _Veins) * _ScleraBrightness * mask;
                
				col = lerp(sclera, col, blend);

				float3 occ = tex2D(_OcclusionTex, i.uv).rgb;
				occ = saturate(1 - (1 - occ) * float3(_AOScale, _SOScale, 1));
				float ao = occ.r;
				float so = occ.g;

				float3 specCol = _ReflectionSpecular.rgb * spec * so;
				UnityLight mainLight = MainLight();
                FragmentCommonData s = FragmentSetup(i.uv, wv, half3(0,0,0), i.tangentToWorldAndPackedData, wp);
				UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);
                UnityGI gi = FragmentGI (s, ao, i.ambientOrLightmapUV, atten, mainLight);
                FragmentCommonData scc = (FragmentCommonData) 0;
				scc.specColor = specCol;
				scc.smoothness = ccSmth;
				scc.normalWorld = norm;
				scc.eyeVec = wv;
				scc.posWorld = wp;
                UnityGI ccgi = FragmentGI(scc, ao, i.ambientOrLightmapUV, atten, mainLight);
                

                half4 c = BRDF1_Unity_PBS(col, specCol, s.oneMinusReflectivity, smth, norm, -wv, gi.light, gi.indirect);
                c += BRDF1_Unity_PBS(0, specCol, 1 - SpecularStrength(specCol), ccSmth, norm, -wv, gi.light, ccgi.indirect) * coat;
                
				float3 rDir = BoxProjectedCubemapDirection(reflect(-wv, norm), wp, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
                half4 rgbm = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, rDir);
                c.rgb += DecodeHDR(rgbm, unity_SpecCube0_HDR) *ao * col;

                //float3 evnVec = RotVectorAroundAxis(reflectDir, normalize(_SecondaryEnvRotationAxis), _SecondaryEnvRotation / 180 * 3.14);
                //evnVec = normalize(evnVec + reflectDir);
                //float3 emmisive = texCUBE(_SecondaryEnv, evnVec) *_SecondaryEnvBalance;
                //c.rgb += emmisive;
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, c);
                return c;
            }
            ENDCG
        }
    }
}
