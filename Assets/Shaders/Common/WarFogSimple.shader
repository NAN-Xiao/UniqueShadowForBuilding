Shader "Simple/WarFogSimple"
{
    Properties
    {
        _Color("Color",color)=(0,0,0,0.5)
        _FogTex ("_FogTex", 2D) = "white" {}
        _CloudTex("Cloud",2d) = "black"{}
        _WarpTex("_WarpTex",2d) = "black"{}

        _Warp("warp",float)=0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100
        cull off
        ztest off
        zwrite off
        blend srcalpha oneminussrcalpha
      //  BlendOp[min]

      //  blend srcalpha oneminussrcalpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2:TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2:TEXCOORD1;
            };

            sampler2D _FogTex,_CloudTex,_WarpTex;
            float4 _FogTex_ST, _CloudTex_ST;
            float4 _Color;
            float _Warp;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _FogTex);
                o.uv2= TRANSFORM_TEX(v.uv2, _CloudTex);
                return o;
            }

            fixed4 frag(v2f v) : SV_Target
            {
                float2 uv0 = v.uv;
                float blur =0.02;
                float2 uv1 = v.uv + float2(0, 1)* blur;
                float2 uv2 = v.uv + float2(1, 1) *blur;
                float2 uv3 = v.uv + float2(-1, -1) *blur;
                float2 uv4 = v.uv + float2(0, -1) *blur;
                float2 uv5 = v.uv + float2(1, 0) *blur;
                float2 uv6 = v.uv + float2(-1, 0) *blur;



                fixed col = tex2D(_FogTex, uv0).a;
                 col += tex2D(_FogTex, uv1).a;
                 col += tex2D(_FogTex, uv2).a;
                 col += tex2D(_FogTex, uv3).a;
                 col += tex2D(_FogTex, uv4).a;
                 col += tex2D(_FogTex, uv5).a;
                 col += tex2D(_FogTex, uv6).a;
                 col *= 0.3;


                half3 flowVal = (tex2D(_WarpTex, v.uv) * 2 - 1) * _Warp;

                float dif1 = frac(_Time.y * 0.25 + 0.5);
                float dif2 = frac(_Time.y * 0.25);

                half lerpVal = abs((0.5 - dif1) / 0.5);

                half4 col1 = tex2D(_CloudTex, v.uv2 - flowVal.xy * dif1);
                half4 col2 = tex2D(_CloudTex, v.uv2 - flowVal.xy * dif2);

                float4 a = lerp(col1, col2, lerpVal) * _Color;
                a.a = min(1, col);
                return  a;
            }
            ENDCG
        }
    }
}
