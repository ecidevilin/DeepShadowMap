struct appdata
{
    float4 vertex : POSITION;  
    float4 tangent : TANGENT; 
    float3 normal : NORMAL;  
    float4 texcoord : TEXCOORD0;  
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;  
    float4 texcoord3 : TEXCOORD3;   
 
    fixed4 color : COLOR;  
};

struct v2f
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 worldPos   : TEXCOORD1;
    half3 world_normal  : TEXCOORD2;
    half3 world_tangent : TEXCOORD3;
    half3 world_binormal : TEXCOORD4;
    UNITY_FOG_COORDS(5)
    LIGHTING_COORDS(6,7)
    #if defined(LIGHTMAP_ON)|| defined(UNITY_SHOULD_SAMPLE_SH)
        float4 ambientOrLightmapUV : TEXCOORD8;
    #endif
	//SHADOW_COORDS(8)

};

sampler2D _MainTex;
sampler2D _NormalTex;
sampler2D _MaskTex;
sampler2D _AO;
sampler2D _DetailNormalTex;
sampler2D _ShadowMapFocus;
sampler2D _MaterialTex;
float BaseMapBias;
float NormalMapBias;
float4 _MainTex_ST;
float _CustomizeInfo;
float _DetailNormalWeight;
float _DetailNormalTile;
float4 _Color;
float4 _SkyColor;
float4 _AmbientColor;
float4 _StaticLightColor;
float4 _StaticLightDir;
float4 _CustomizeData0;
float4 _CustomizeData1;
float4 _CustomizeData2;
float4 _CustomizeData3;
float4 _CustomizeData4;
float4 _CustomizeData5;
float _SkinSpec;
samplerCUBE _Cube;
float _HDR_Multiply;
float _BleachBypassRate;
float _BlackLevel;

#include "BD_FunctionLibrary.cginc"

v2f vert (appdata v)
{
    v2f o = (v2f)0;
    o.pos = UnityObjectToClipPos(v.vertex);
    //o.uv = v.texcoord.xy;

    o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
    o.worldPos = mul( unity_ObjectToWorld, v.vertex );

    half3 wNormal = UnityObjectToWorldNormal(v.normal);  
    half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
	//wTangent = v.tangent.xyz;
    half tangentSign = v.tangent.w * unity_WorldTransformParams.w;  
    half3 wBinormal = cross(wNormal, wTangent) * tangentSign;  
                    
    o.world_normal =wNormal;
    o.world_tangent = wTangent; 
    o.world_binormal = wBinormal;
    
    TRANSFER_VERTEX_TO_FRAGMENT(o);
    UNITY_TRANSFER_FOG(o,o.pos);
	//TRANSFER_SHADOW(o);
	
    return o;
}