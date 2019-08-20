// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/DepthOnly"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

			float4 vert (float4 vertex : POSITION) : SV_POSITION
            {
				return UnityObjectToClipPos(vertex);
            }

            fixed4 frag () : SV_Target
            {
				return 0;
            }
            ENDCG
        }
    }
}
