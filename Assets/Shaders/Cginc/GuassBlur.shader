
Shader "Hidden/GaussBlur"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _BlurRadius("_BlurRadius",float)=0.1
    }

    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        half _BlurRadius;

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float2 uvs[5] : TEXCOORD1;
        };

        v2f vert_VerticalBlur(appdata v) {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uvs[0] = v.uv;
            o.uvs[1] = v.uv + float2(0, _MainTex_TexelSize.y * 1) * _BlurRadius;
            o.uvs[2] = v.uv + float2(0, _MainTex_TexelSize.y * -1) * _BlurRadius;
            o.uvs[3] = v.uv + float2(0, _MainTex_TexelSize.y * 2) * _BlurRadius;
            o.uvs[4] = v.uv + float2(0, _MainTex_TexelSize.y * -2) * _BlurRadius;
            return o;
        }

        v2f vert_HorizontalBlur(appdata v) {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uvs[0] = v.uv;
            o.uvs[1] = v.uv + float2(_MainTex_TexelSize.x * 1, 0) * _BlurRadius;
            o.uvs[2] = v.uv + float2(_MainTex_TexelSize.x * -1, 0) * _BlurRadius;
            o.uvs[3] = v.uv + float2(_MainTex_TexelSize.x * 2, 0) * _BlurRadius;
            o.uvs[4] = v.uv + float2(_MainTex_TexelSize.x * -2, 0) * _BlurRadius;
            return o;
        }

        fixed4 fragBlur(v2f i) : SV_Target
        {
            half weight[3] = {0.4026, 0.2442, 0.0545};

            fixed4 col = tex2D(_MainTex, i.uvs[0]) * weight[0];

            for (int j = 1; j < 3; j++)
            {
                col += tex2D(_MainTex, i.uvs[2 * j - 1]) * weight[j];
                col += tex2D(_MainTex, i.uvs[2 * j]) * weight[j];
            }

            return col;
        }
        ENDCG

        ZTest Always
        Cull Off
        ZWrite Off

        //Pass1
        Pass
        {
            NAME "GAUSSIAN_BLUR_VERTICAL"

            CGPROGRAM
            #pragma vertex vert_VerticalBlur
            #pragma fragment fragBlur
            ENDCG
        }

        //Pass2
        Pass
        {
            NAME "GAUSSIAN_BLUR_HORIZONTAL"

            CGPROGRAM
            #pragma vertex vert_HorizontalBlur
            #pragma fragment fragBlur
            ENDCG
        }
    }
}
