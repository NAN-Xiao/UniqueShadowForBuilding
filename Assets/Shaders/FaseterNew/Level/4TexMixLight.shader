Shader "Faster/URP/Level/4TexMixLight"
{

    Properties
    {
        _Splat0("Layer1 (RGB)", 2D) = "white" {}
        _Splat1("Layer2 (RGB)", 2D) = "white" {}
        _Splat2("Layer3 (RGB)", 2D) = "white" {}
        _Splat3("Layer4 (RGB)", 2D) = "white" {}
        _Control("Control (RGBA)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        Pass
        {
            Name "ForwardBase"
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Cginc/HLSL/LightFuction.hlsl"
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
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                float4 shadowCoord : TEXCOORD5;
                #ifdef LIGHTMAP_ON
                    float2  uvStaticLightmap :TEXCOORD6;
                #endif
                float3  sh : TEXCOORD7;
                half _fogFactory:TEXCOORD8;
                float3 normal:TEXCOORD9;
                float4 pos : SV_POSITION;
            };

            

            CBUFFER_START(UnityPerMaterial)
            float4 _Splat0_ST;
            float4 _Splat1_ST;
            float4 _Splat2_ST;
            float4 _Splat3_ST;
            CBUFFER_END


            TEXTURE2D (_Splat0);
            TEXTURE2D (_Splat1);
            TEXTURE2D (_Splat2);
            TEXTURE2D (_Splat3);
            TEXTURE2D (_Control);
            SAMPLER(sampler_Control);
            

            Varyings vert(Attributes v)
            {
                Varyings o=(Varyings)0;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _Splat0);
                o.uv1 = TRANSFORM_TEX(v.texcoord0, _Splat1);
                o.uv2 = TRANSFORM_TEX(v.texcoord0, _Splat2);
                o.uv3 = TRANSFORM_TEX(v.texcoord0, _Splat3);
                o.uv4 = v.texcoord0;// TRANSFORM_TEX(v.texcoord, _Control);


                float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                
                o.shadowCoord= TransformWorldToShadowCoord(positionWS);
                o.normal = TransformObjectToWorldDir(v.normal.xyz);
                o._fogFactory=ComputeFogFactor(o.pos.z);
                #ifdef LIGHTMAP_ON
                    o.uvStaticLightmap= v.texcoord2 * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                o.sh=SampleSHVertex(o.normal);
                return o;
            }
            half4 frag(Varyings i) : SV_Target
            {
                half4 Mask;
                Mask.xyz = SAMPLE_TEXTURE2D(_Control, sampler_Control, i.uv4.xy).xyz;
                Mask.w = 1.0 - Mask.x - Mask.y - Mask.z;
                half3 lay1 = SAMPLE_TEXTURE2D(_Splat0, sampler_Control, i.uv0.xy).rgb;
                half3 lay2 = SAMPLE_TEXTURE2D(_Splat1, sampler_Control, i.uv1.xy).rgb;
                half3 lay3 = SAMPLE_TEXTURE2D(_Splat2, sampler_Control, i.uv2.xy).rgb;
                half3 lay4 = SAMPLE_TEXTURE2D(_Splat3, sampler_Control, i.uv3.xy).rgb;
                half3 c;
                c = (lay1.xyz * Mask.r + lay2.xyz * Mask.g + lay3.xyz * Mask.b + lay4.xyz * Mask.a);
                half4 shadowCoord = i.shadowCoord;
                Light mainLight = GetMainLight(shadowCoord);
                half3 atten =  mainLight.shadowAttenuation;
                c *= atten;
                #ifdef LIGHTMAP_ON
                    c *= SampleLightmap( i.uvStaticLightmap,i.normal);
                #else
                    half diff = DiffuseLambert(mainLight.direction, i.normal);
                    half3 sh = SampleSHPixel(i.sh,i.normal);
                    c *= diff * mainLight.color+sh;
                #endif
                c= MixFog(c.rgb,i._fogFactory);
                return float4(c,1);
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