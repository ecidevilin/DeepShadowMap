
float4 _decodeRGBA(in float _fPacked)
{
    float4 _vecResult = {0, 0, 0, 0};
    _vecResult.x = floor(_fPacked / 125000.0); 
    _fPacked -= _vecResult.x * 125000.0;
    _vecResult.y = floor(_fPacked / 2500.0);
    _fPacked -= _vecResult.y * 2500.0;
    _vecResult.z = floor(_fPacked / 50.0);
    _fPacked -= _vecResult.z * 50.0;
    _vecResult.w = _fPacked;
    return clamp(_vecResult / 49.0, 0.0, 1.0);

}
float3 _colorCorrect(in float3 _color)
{
    return (_color.xyz * _color.xyz);
}


float _calcOrenNayar3_optimize(in float _dotLN, in float _dotVN, in float _dotLV)
{
    float _cos_nl = max(_dotLN, 0.0);
    float _cos_nv = max(_dotVN, 0.0);
    float _oren_nayar_s = (max(_dotLV, 0.0) - (_cos_nl * _cos_nv));
    return (_cos_nl * (0.77450264 + (0.41284403 * _oren_nayar_s)));
    
}
float _fresnel_Optimize(in float _f0, in float _NdotL)
{
    float _reNdotL = (1.0 - _NdotL);
    float s8 = (1.0 - _NdotL);
    return (_f0 + ((1.0 - _f0) * ((((s8 * s8) * s8) * s8) * s8)));
    
}
float _NormalDistribution_GGX(in float _NdH, in float _a)
{
    float _a2 = (_a * _a);
    float _denominator = (((_NdH * _NdH) * (_a2 - 1.0)) + 1.0);
    (_denominator *= _denominator);
    (_denominator *= 3.1415901);
    return (_a2 / _denominator);
}
float _geometry_CookTorrance_Optimize(in float _NdotH, in float _NdotL, in float _NdotV, in float _VdotH, in float _roughness)
{
    return min((((2.0 * _NdotH) / _VdotH) * max(min(_NdotV, _NdotL), 0.0)), 1.0);
}
float _calc_Specular2_custom_optimize2(in float3 _vecNormal, in float3 _vecViewDirection, in float3 _lightDirection, in float _NdotV, in float _fresnelResult, in float _u_roughness)
{
    float3 _vecHalf = normalize((_vecViewDirection + _lightDirection));
    float _NdotL = dot(_vecNormal, _lightDirection);
    float _NdotH = dot(_vecNormal, _vecHalf);
    float _VdotH = dot(_vecViewDirection, _vecHalf);
    float _NdotL_clamped = max(_NdotL, 0.0);
    float _NdotV_clamped = max(_NdotV, 0.0);
    float _invRoughness = max((1.0 - _u_roughness), 0.0099999998);
    float _brdf_spec = (((_fresnelResult * _geometry_CookTorrance_Optimize(_NdotH, _NdotL, _NdotV, _VdotH, _invRoughness)) * _NormalDistribution_GGX(max(_NdotH, 0.0), _invRoughness)) / (4.0 * _NdotV_clamped));
    return max(_brdf_spec, 0.0);

}
float3 _EnvBRDFApprox(in float3 _SpecularColor, in float _Roughness, in float _NoV)
{
    float4 _r = ((_Roughness * float4(-1.0, -0.0275, -0.57200003, 0.022)) + float4(1.0, 0.0425, 1.04, -0.039999999));
    float _a004 = ((min((_r.x * _r.x), exp2((-9.2799997 * _NoV))) * _r.x) + _r.y);
    float2 _AB = ((float2(-1.04, 1.04) * _a004) + _r.zw);
    return ((_SpecularColor * _AB.x) + _AB.y);
}
float _NormalDistribution_GGX_Self(in float _NdH, in float _a)
{
    float _a2 = (_a * _a);
    float _denominator = (((_NdH * _NdH) * (_a2 - 1.0)) + 1.0);
    (_denominator *= _denominator);
    (_denominator *= 3.1415901);
    return (_a2 / _denominator);

}
float _geometry_CookTorrance_Optimize_Self(in float _NdotH, in float _NdotL, in float _NdotV, in float _VdotH, in float _roughness)
{
    return min(((2.0 * _NdotH) * max(min(_NdotV, _NdotL), 0.0)), 1.0);

}	
float _calc_Specular2_custom_optimize2_Self(in float3 _vecNormal, in float3 _vecViewDirection, in float _NdotV, in float _fresnelResult, in float _u_roughness)
{
    float _NdotL = dot(_vecNormal, _vecViewDirection);
    float _NdotH = _NdotL;
    float _NdotL_clamped = max(_NdotL, 0.0);
    float _NdotV_clamped = max(_NdotV, 0.0);
    float _invRoughness = max((1.0 - _u_roughness), 0.0099999998);
    float _brdf_spec = (((_fresnelResult * _geometry_CookTorrance_Optimize_Self(_NdotH, _NdotL, _NdotV, 1.0, _invRoughness)) * _NormalDistribution_GGX_Self(max(_NdotH, 0.0), _invRoughness)) / (4.0 * _NdotV_clamped));
    return max(_brdf_spec, 0.0);

}
static float _gamma = 2.0;
float3 _Uncharted2ToneMapping(in float3 _color)
{
    _color = clamp(_color , 0.01, 10.0);
    float _A = {0.15000001};
    float _B = {0.5};
    float _C = {0.1};
    float _D = {0.2};
    float _E = {0.02};
    float _F = {0.30000001};
    float _W = {11.2};
    _color = (_color * (_A * _color + _C * _B) + _D * _E) / (_color * (_A * _color + _B) + _D * _F) - _E / _F;
    float _white = (_W * (_A * _W + _C * _B) + _D * _E) / (_W * (_A * _W + _B) + _D * _F) - _E / _F;
    _color /= _white;
    return _color;
}
float3 ToneMapping(in float3 Color, in float HDR_Multiply)
{
    //float HDR_Multiply = 0.5;
    uint _toneMapValue = 0;
    if (_toneMapValue == 0)
    {
        Color.xyz = Color.xyz * HDR_Multiply * 10.0;
        Color.xyz = _Uncharted2ToneMapping(Color.xyz);
    }
    return Color;

}
float3 _ShiftTangent(in float3 _T, in float3 _N, in float _fShiftAmount)
{
    return normalize((_T + (_fShiftAmount * _N)));
}
float _HairSingleSpecularTerm(in float3 _T, in float3 _H, in float _fExponent)
{
    float _fDotTH = dot(_T, _H);
    float _fSinTH = sqrt(clamp((1.0 - (_fDotTH * _fDotTH)), 0.001, 1.0));
    float _dirAtten = smoothstep(-1.0, 0.0, _fDotTH);
    return (_dirAtten * pow(_fSinTH, _fExponent));
}
