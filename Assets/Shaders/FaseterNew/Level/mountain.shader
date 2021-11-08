Shader "Faster/URP/Level/mountain"
{
    Properties
    {
        _Tint("_Tint",Color)=(1,1,1,1)

        _Splat0("Layer1 (RGB)", 2D) = "white" {}
        _Splat1("Layer2 (RGB)", 2D) = "white" {}
        _Splat2("Layer3 (RGB)", 2D) = "white" {}
        _Control("Control (RGBA)", 2D) = "white" {}
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "RenderPipeline" = "UniversalPipeline"}
        LOD 300
        cull off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
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
            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float3 normal:NORMAL;
                float4 color:COLOR;
            };

            struct v2f
            {
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;

                
                float4 vertex : SV_POSITION;
                float3 normal:NORMAL;
                float4 color:COLOR;
                float3 worldPos:TEXCOORD5;
                half fogFactory:texcoord6;
                float3 sh:texcoord7;
            };



            CBUFFER_START(UnityPerMaterial)
            float4 _Splat0_ST;
            float4 _Splat1_ST;
            float4 _Splat2_ST;
            float4 _Control_ST;
            float4 _Tint;
            CBUFFER_END
            
            TEXTURE2D (_Control);
            SAMPLER (sampler_Control);
            TEXTURE2D(_Splat0);
            SAMPLER (sampler_Splat0);
            TEXTURE2D (_Splat1);
             SAMPLER (sampler_Splat1);
            TEXTURE2D (_Splat2);
            SAMPLER (sampler_Splat2);
            
            v2f vert (appdata v)
            {
                v2f o=(v2f)0;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _Splat0);
                o.uv1 = TRANSFORM_TEX(v.texcoord0, _Splat1);
                o.uv2 = TRANSFORM_TEX(v.texcoord0, _Splat2);
                o.uv3 = TRANSFORM_TEX(v.texcoord0,_Control);
                
                o.normal=TransformObjectToWorldDir(v.normal);
                o.worldPos=TransformObjectToWorld(v.vertex.xyz);
                o.color=_Tint*v.color;
                o.fogFactory=ComputeFogFactor(o.vertex.z);
                o.sh=SampleSHVertex(o.normal);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
             float3 lay1 = SAMPLE_TEXTURE2D(_Splat0,sampler_Splat0,i.uv0).xyz;
               float3 lay2 = SAMPLE_TEXTURE2D(_Splat1,sampler_Splat1, i.uv1).xyz;
              float3 lay3 = SAMPLE_TEXTURE2D(_Splat2,sampler_Splat2,i.uv2).xyz;
                float4 Mask =SAMPLE_TEXTURE2D(_Control,sampler_Control, i.uv3);
               float3 c = (lay1 * Mask.r + lay2 * Mask.g + lay3 * Mask.b );
              

              
                float3 lightDir = normalize( _MainLightPosition.xyz);
                float3 lightColor = _MainLightColor.rgb;
                float3 normal=normalize(i.normal);
                float nl =max(0,dot(normal, lightDir));
            
                half3 ambient =SampleSHPixel(i.sh,i.normal);
                c.rgb*=nl*lightColor+ambient;
                c.rgb= MixFog(c.rgb,i.fogFactory);
                return  float4(c,Mask.a);
            }
            ENDHLSL
        }
    }
}
