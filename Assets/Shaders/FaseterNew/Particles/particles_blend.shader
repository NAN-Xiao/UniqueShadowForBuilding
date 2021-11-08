Shader "Faster/URP/Particles/Blend"
{
    Properties
    {   
        _Color("Color",Color)=(1,1,1,1)
        _MainTex("MainTex",2D)= "white" {}
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            

            struct Attributes
            {
                float3 positionOS   : POSITION;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4  positionCS  : SV_POSITION;
                float4   color       : COLOR;
                float2   uv          : TEXCOORD0;
                float   fogFactory  : TEXCOORD1;
            };


            
            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST;
            half4 _Color;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            Varyings vert(Attributes attributes)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(attributes.positionOS);
                o.color*= attributes.color;
                o.uv = TRANSFORM_TEX(attributes.uv, _MainTex);
                o.fogFactory = ComputeFogFactor( o.positionCS.z);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);//*i.color;
                col.rgb = MixFog(col.rgb,i.fogFactory);
                return col;
            }
            ENDHLSL
        }
    }

}
