Shader "Faster/URP/Level/Grass" {
    Properties {
        _Color0 ("_Color0", Color) = (1,1,1,1)
        _Color1("_Color1", Color) = (1,1,1,1)
        _Gradient("gradient",float)=1
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Dirction("_Dirction",vector) = (0,0,0,0)
        _weight("_weight",float) = 1
        _Wave("_Wave",float) = 1
        _Strengh("_Strengh",float) = 1
        _OffsetRadio("_OffsetRadio",float) = 1
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }

    SubShader {
        Tags {"Queue"="AlphaTest" "RenderPipeline" = "UniversalPipeline"}
        LOD 300
        cull off
        Pass
        {
            Name "ForwardBase"
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD3;
                float3 normal:TEXCOORD6;
                half fogFactory:TEXCOORD8;
                float4 shadowCoord : TEXCOORD7;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Dirction;
            float _weight;
            float _Wave;
            float _Strengh;
            float _OffsetRadio;
            float _Cutoff;
            float4 _Color0;
            float4 _Color1;
            float _Gradient;
            CBUFFER_END

            TEXTURE2D (_MainTex);
            SAMPLER(sampler_MainTex);


            Varyings vert (Attributes v)
            {
                Varyings o=(Varyings)0;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                // TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)


                float3 wp=TransformObjectToWorldPos(v.vertex.xyz);
                float3 offset=clamp(0,1,wp.y-_weight);
                float rip=sin(_Time.y*_Wave*3.14+wp.x+wp.z*10)*_Strengh;
                float3 of=(rip)*_Dirction.xyz*offset;

                v.vertex.xyz+=of;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.fogFactory=ComputeFogFactor(o.vertex.z);
                o.shadowCoord= TransformWorldToShadowCoord(wp);
                o.normal=TransformObjectToWorldDir(v.normal);
                

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv);
                col.rgb *=lerp(_Color1.rgb,_Color0.rgb, i.uv.y* _Gradient) ;

                
                
                col.rgb= MixFog(col.rgb,i.fogFactory);
                clip(col.a - _Cutoff);
                return col;
            }
            ENDHLSL
        }
        // Pass to render object as a shadow caster
        // Pass {
            //     Name "Caster"
            //     Tags { "LightMode" = "ShadowCaster" }

            //     CGPROGRAM
            //     #pragma vertex vert
            //     #pragma fragment frag
            //     #pragma target 2.0
            //     #pragma multi_compile_shadowcaster
            //     #pragma multi_compile_instancing 
            //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //     struct Attributes {
                //         V2F_SHADOW_CASTER;
                //         float2  uv : TEXCOORD1;
                //         UNITY_VERTEX_OUTPUT_STEREO
            //     };

            //     uniform float4 _MainTex_ST;
            //     uniform sampler2D _MainTex;
            //     uniform fixed _Cutoff;
            //     uniform fixed4 _Color;


            //     float4 _Dirction;
            //     float _weight, _Wave, _Strengh, _OffsetRadio;

            //     Attributes vert( appdata_base v )
            //     {
                //         Attributes o;
                //         float3 wp = TrasformObjectToWorld(v.vertex.xyz);
                //         float3 offset = clamp(0, 1, wp.y - _weight);
                //         float rip = sin(_Time.y * _Wave * UNITY_PI * +(wp.x + wp.z) * 10) * _Strengh;
                //         float3 of = (rip)*_Dirction.xyz * offset;
                //         v.vertex.xyz += of;
                //         UNITY_SETUP_INSTANCE_ID(v);
                //         UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                //         TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                //         o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //         return o;
            //     }

            
            //     float4 frag( v2f i ) : SV_Target
            //     {
                //         fixed4 texcol = tex2D( _MainTex, i.uv );
                //         clip( texcol.a*_Color.a - _Cutoff );

                //         SHADOW_CASTER_FRAGMENT(i)
            //     }
            //     ENDHLSL

        // }

    }

}
