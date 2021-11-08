Shader "Faster/Terrain/worldMap"
{
    Properties
    {
        [Toggle(Simplify)] Simplify("Simplify",int)=0
        _Tint("_Tint",Color)=(1,1,1,1)
        _Splat0("Layer1 (RGB)", 2D) = "white" {}
        _Splat1("Layer2 (RGB)", 2D) = "white" {}
        _Splat2("Layer3 (RGB)", 2D) = "white" {}
        _Splat3("Layer4 (RGB)", 2D) = "white" {}
        _Control("Control (RGBA)", 2D) = "white" {}
        _Color0("_Color0",Color)=(1,1,1,1)
        _Color1("_Color0",Color)=(1,1,1,1)
        _Color2("_Color0",Color)=(1,1,1,1)
        _Color3("_Color0",Color)=(1,1,1,1)
        


        _Ref("ref",int)=1
        com("com",int)=1
        stencilOperation("stencilOperation",int)=1
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        
        Pass
        {
            Name "ForwardBase"
            Tags{"LightMode" = "UniversalForward"}
            Stencil
            {
                Ref [_Ref]
                Comp [com]
                Pass [stencilOperation]
            }  
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile _ Simplify
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Cginc/HLSL/BRDFCORE.hlsl"


            
            
            CBUFFER_START(UnityPerMaterial)
            float4 _Splat0_ST;
            float4 _Splat1_ST;
            float4 _Splat2_ST;
            float4 _Splat3_ST;
            float4 _Color0;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float4 _Tint;
            CBUFFER_END
            
            TEXTURE2D (_Splat0);
            SAMPLER(sampler_Splat0);
            TEXTURE2D (_Splat1);
            SAMPLER(sampler_Splat1);
            TEXTURE2D (_Splat2);
            SAMPLER(sampler_Splat2);
            TEXTURE2D (_Splat3);
            SAMPLER(sampler_Splat3);
            TEXTURE2D (_Control);
            SAMPLER(sampler_Control);

            struct appdata {
                half4 vertex : POSITION;
                half3 normal : NORMAL;
                // half4 tangent : TANGENT;*/
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
            };


            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                half fogFactory:TEXCOORD5;
                float4 shadowCoord:TEXCOORD6;
                float3 worldNormal :TEXCOORD7;
                float3 sh:TEXCOORD9;
                float3 worldPos:TEXCOORD8;
                
            };



            v2f vert(appdata v)
            {
                v2f o=(v2f)0;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _Splat0);
                o.uv1 = TRANSFORM_TEX(v.texcoord0, _Splat1);
                o.uv2 = TRANSFORM_TEX(v.texcoord0, _Splat2);
                o.uv3 = TRANSFORM_TEX(v.texcoord0, _Splat3);
                o.uv4 = v.texcoord0;// TRANSFORM_TEX(v.texcoord, _Control);
                o.worldNormal =TransformObjectToWorldNormal(v.normal.xyz) ;           
                o.worldPos =TransformObjectToWorld(v.vertex.xyz);
                
                #ifndef LIGHTMAP_OFF
                    o.lightmapUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                o.fogFactory=ComputeFogFactor(o.pos.z);

                return o;
            }
            half4 frag(v2f i) : SV_Target
            {
                half4 Mask;
                Mask.xyz = SAMPLE_TEXTURE2D(_Control,sampler_Control, i.uv4.xy).xyz;
                Mask.w = 1.0 - Mask.x - Mask.y - Mask.z;

                Light mainLight = GetMainLight(i.shadowCoord);
                float3 normal=normalize(i.worldNormal);
                half3 c;
                #ifndef Simplify
                    half3 lay1 = SAMPLE_TEXTURE2D(_Splat0,sampler_Splat0, i.uv0.xy).rgb;
                    half3 lay2 = SAMPLE_TEXTURE2D(_Splat1,sampler_Splat1, i.uv1.xy).rgb;
                    half3 lay3 = SAMPLE_TEXTURE2D(_Splat2,sampler_Splat2, i.uv2.xy).rgb;
                    half3 lay4 = SAMPLE_TEXTURE2D(_Splat3,sampler_Splat3, i.uv3.xy).rgb;
                    c = (lay1.xyz * Mask.r + lay2.xyz * Mask.g + lay3.xyz * Mask.b + lay4.xyz * Mask.a);
                #else
                    c = (_Color0.xyz * Mask.r + _Color1.xyz * Mask.g + _Color2.xyz * Mask.b + _Color3.xyz * Mask.a);
                #endif
                // #ifndef LIGHTMAP_OFF
                //     half3 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV));
                //     c.rgb *= lm;
                // #endif
                float3 lightdir = normalize(mainLight.direction);
                float3 diff = dot(lightdir, normal)*mainLight.color;
                
                half3 ambient=SampleSHVertex(i.worldNormal);
                c *= diff+ambient;
                c*= mainLight.shadowAttenuation;
                c*=_Tint.rbg;
                MixFog(c.rgb, i.fogFactory);
                return float4(c,_Tint.a);
            }
            ENDHLSL
        }
    }

}

