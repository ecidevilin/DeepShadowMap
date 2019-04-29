

float3 CameraPos;
float3 LightDir;
float _HairAlpha;
StructuredBuffer<FittingFunc> FittingFuncList;

float CalculateKajiyaKay(float3 tangent, float3 posInWorld)
{
	float tdotl = dot(tangent, normalize(LightDir));
	float diffuse = sqrt(1 - tdotl * tdotl);
	float tdotv = dot(tangent, normalize(CameraPos - posInWorld));
	float specular = pow(tdotl * tdotv + diffuse * sqrt(1 - tdotv * tdotv), 6.0f);
	//return (saturate(diffuse) * 0.7f + saturate(specular) * 0.8f) * 0.90f; // scale this thing a bit
	return (saturate(diffuse) * 0.63f + saturate(specular) * 0.72f); // scale this thing a bit
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
			FittingFunc func = FittingFuncList[idx++];
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
	shading = clamp(shading, 0.25, 1);
	return shading;
}