

float3 CameraPos;
float3 LightDir;
float _HairAlpha;

half3 _LightColor0;
half _Diffuse;
half _PrimaryShift;
half _SecondaryShift;
half _PrimarySpecular;
half _SecondarySpecular;
half3 _PrimarySpecularColor;
half3 _SecondarySpecularColor;

sampler2D _ShiftTex;
sampler2D _NoiseTex;

half3 Diffuse(half3 normal, half3 lightDir, half softness)
{
	fixed dotNL = saturate(dot(normal, lightDir));
	return saturate(lerp(softness, 1, dotNL));
}
fixed3 Fresnel(half3 normal, half3 viewDir, fixed power)
{
	fixed dotNL = 1 - saturate(dot(normal, viewDir));
	return pow(dotNL, power);
}
half3 ShiftTangent(half3 tangent, half3 normal, half shift)
{
	return normalize(tangent + shift * normal);
}
half Specular(half3 tangent, half3 viewDir, half3 lightDir, half exponent)
{
	half3 h = normalize(viewDir + lightDir);
	half dotTH = dot(tangent, h);
	half sinTH = sqrt(1.0 - dotTH * dotTH);
	half dirAtten = smoothstep(-1.0, 0.0, dotTH);
	return dirAtten * pow(sinTH, exponent);
}

half3 CalculateKajiyaKay(half3 tangent, half3 normal, float2 uv, half3 viewDir, half3 lightDir)
{
	half shift = tex2D(_ShiftTex, uv).r;
	half noise = tex2D(_NoiseTex, uv).g;
	half3 tangent1 = ShiftTangent(tangent, normal, _PrimaryShift + shift);
	half3 tangent2 = ShiftTangent(tangent, normal, _SecondaryShift + shift);
	half3 specular = Specular(tangent1, viewDir, lightDir, _PrimarySpecular) * _PrimarySpecularColor;
	specular += Specular(tangent2, viewDir, lightDir, _SecondarySpecular) * noise * _SecondarySpecularColor;
	half3 diffuse = Diffuse(normal, lightDir, _Diffuse);
	return (diffuse + specular) * _LightColor0;
}

float bilinearInterpolation(float s, float t, float4 v)
{
	float st = s * t;
	return dot(float4(1 - s - t + st, s - st, t - st, st), v);
}
