Shader "Faster/URP/Level/Decal"
{

    Properties
    {
        _MainTex("_MainTex", 2D) = "white" {}

    }
    SubShader
    {
        Tags { "Queue" = "AlphaTest" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
            Name "ForwardBase"
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            struct Attributes
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
            };


            struct Varyings
            {
                float2 uv : TEXCOORD0;
                #ifdef LIGHTMAP_ON
                    float2 uvStaticLightmap :TEXCOORD1;
                #endif 
                float4 shadowCoord : TEXCOORD5;
                float3 sh : TEXCOORD7;
                float3 normal:TEXCOORD6;
                float4 pos : SV_POSITION;
            };

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Cginc/HLSL/LightFuction.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END
            TEXTURE2D (_MainTex);
            SAMPLER(sampler_MainTex);
            Varyings vert(Attributes v)
            {
                Varyings o=(Varyings)0;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord0, _MainTex);
                half3 positionWS=TransformObjectToWorld(v.vertex.xyz);
                o.shadowCoord= TransformWorldToShadowCoord(positionWS);
                #ifdef LIGHTMAP_ON
                    o.uvStaticLightmap= v.texcoord2 * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                o.sh=SampleSHVertex(o.normal);
                return o;
            }
            half4 frag(Varyings i) : SV_Target
            {
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                half4 shadowCoord = i.shadowCoord;
                Light mainLight = GetMainLight(shadowCoord);
                half3 atten =  mainLight.shadowAttenuation;
                col.rgb *= atten;
                #ifdef LIGHTMAP_ON
                    col.rgb  *= SampleLightmap( i.uvStaticLightmap,normal);
                #else
                    half3 sh = SampleSHPixel(i.sh,i.normal);
                    col.rgb+=sh;
                #endif
                col.rgb *= _MainLightColor.rgb;
                return col;
            }
            ENDHLSL
        }

        /*   Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            -------------------------------------
            Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }*/
        //Pass
        //{
            //    Name "DepthOnly"
            //    Tags{"LightMode" = "DepthOnly"}

            //    ZWrite On
            //    ColorMask 0
            //    Cull[_Cull]

            //    HLSLPROGRAM
            //    #pragma exclude_renderers gles gles3 glcore
            //    #pragma target 4.5

            //    #pragma vertex DepthOnlyVertex
            //    #pragma fragment DepthOnlyFragment

            //    // -------------------------------------
            //    // Material Keywords
            //    #pragma shader_feature_local_fragment _ALPHATEST_ON
            //    #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //    //--------------------------------------
            //    // GPU Instancing
            //    #pragma multi_compile_instancing
            //    #pragma multi_compile _ DOTS_INSTANCING_ON

            //    #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            //    #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            //    ENDHLSL
        //}
    }

}