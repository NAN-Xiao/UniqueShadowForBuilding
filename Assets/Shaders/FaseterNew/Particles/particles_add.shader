Shader "Faster/URP/Particles/Blend"
{
    Properties
    { _Color("Titnt",Color) = (1,1,1,1)
        _MainTex("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags {"Queue" = "TRANSPARENT" }
        LOD 100
        blend SrcAlpha One
        zwrite off
        ColorMask RGB
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                half4 vertex : POSITION;
                half2 uv : TEXCOORD0;
                half4 color:COLOR;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;

                half4 vertex : SV_POSITION;
                half _fogFactory:TEXCOORD1;
                half4 color:COLOR;
            };
            sampler2D _MainTex;
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            half4 _MainTex_ST;
            CBUFFER_END

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o._fogFactory = ComputeFogFactor(o.vertex.z);
                o.color = v.color * _Color;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv) * i.color;
                col.rgb = MixFog(col.rgb,i._fogFactory);
                return col;
            }
            ENDHLSL
        }
    }
}
