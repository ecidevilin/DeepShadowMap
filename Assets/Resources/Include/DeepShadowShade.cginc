

float3 CameraPos;
float3 LightDir;
float _HairAlpha;
StructuredBuffer<FittingFunc> RegressionBuffer;

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

float deepShadowmapShading(float3 posInLight)
{
	float4 shadingSamples = float4(0, 0, 0, 0);
	float z = posInLight.z;
#if FILTER_SIZE > 0
	float oneOver = 1.0f / (FILTER_SIZE * 2 + 1);
#endif
	int currentY = posInLight.y - FILTER_SIZE;
	[unroll(FILTER_SIZE * 2 + 2)]
	for (uint y = 0; y < FILTER_SIZE * 2 + 2; y++)
	{
		int idx = currentY++ * Dimension + posInLight.x - FILTER_SIZE;
#if FILTER_SIZE > 0
		float2 filteredShading = float2(0, 0);
#endif
		[unroll(FILTER_SIZE * 2 + 2)]
		for (uint x = 0; x < FILTER_SIZE * 2 + 2; x++)
		{
			FittingFunc func = RegressionBuffer[idx++];
			float3 f0 = func.f[0];
			float shading = 1;
			if (z >= f0.z)
			{
				float3 f1 = func.f[1];
				float3 f2 = func.f[2];
				float3 f3 = func.f[3];
				uint fi = z < f1.z ? 0 : z < f2.z ? 1 : z < f3.z ? 2 : 3;
				float3 f = func.f[fi];
				uint n = FittingBins[fi];
				uint o = FittingBinsAcc[fi];
				float ii = (z - f.y) * f.x * n + o;
				ii = min(ii, NUM_BUF_ELEMENTS-1);
				shading = pow(1.0 - _HairAlpha, ii + 1);
			}
#if FILTER_SIZE > 0
			filteredShading += shading * float2(x < FILTER_SIZE * 2 + 1, x > 0);
#else
			shadingSamples[y * 2 + x] = shading;
#endif
		}
#if FILTER_SIZE > 0
		filteredShading *= oneOver;
		shadingSamples += filteredShading.xyxy * float2(y < FILTER_SIZE * 2 + 1, y > 0).xxyy;
#endif
	}
#if FILTER_SIZE > 0
	shadingSamples *= oneOver;
#endif
	float shading = bilinearInterpolation(frac(posInLight.x), frac(posInLight.y), shadingSamples);
	shading = max(shading, 0.1);
	return shading;
}