Shader "Faster/Terrain/hole"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",color)=(1,1,1,1)
        _Ref("refvalue",float)=1
        _Com("Compare",int)=1
        _stencilOperation("stencilOperation",int)=1
        _ZWrite("_ZWrite",int)=1
        _SrcBlend("_SrcBlend",int)=1
        _DstBlend("_DstBlend",int)=0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZWrite[_ZWrite]
        Blend [_SrcBlend] [_DstBlend]   
        Pass
        {
        
            Tags{"Queue"="Transparent" "LightMode" = "UniversalForward"}
            Stencil
            {
                Ref [_Ref]
                Comp [_Com]
                // public enum CompareFunction
                // {
                    
                    //     摘要:
                    //     Depth or stencil test is disabled.
                    //     Disabled = 0,
                    
                    //     摘要:
                    //     Never pass depth or stencil test.
                    //     Never = 1,
                    
                    //     摘要:
                    //     Pass depth or stencil test when new value is less than old one.
                    //     Less = 2,
                    
                    //     摘要:
                    //     Pass depth or stencil test when values are equal.
                    //     Equal = 3,
                    
                    //     摘要:
                    //     Pass depth or stencil test when new value is less or equal than old one.
                    //     LessEqual = 4,
                    
                    //     摘要:
                    //     Pass depth or stencil test when new value is greater than old one.
                    //     Greater = 5,
                    
                    //     摘要:
                    //     Pass depth or stencil test when values are different.
                    //     NotEqual = 6,
                    
                    //     摘要:
                    //     Pass depth or stencil test when new value is greater or equal than old one.
                    //     GreaterEqual = 7,
                    
                    //     摘要:
                    //     Always pass depth or stencil test.
                    //     Always = 8
                // }
                Pass [_stencilOperation]
                // public enum StencilOp
                // {
                    
                    //     摘要:
                    //     Keeps the current stencil value.
                    //     Keep = 0,
                    
                    //     摘要:
                    //     Sets the stencil buffer value to zero.
                    //     Zero = 1,
                    
                    //     摘要:
                    //     Replace the stencil buffer value with reference value (specified in the shader).
                    //     Replace = 2,
                    
                    //     摘要:
                    //     Increments the current stencil buffer value. Clamps to the maximum representable
                    //     unsigned value.
                    //     IncrementSaturate = 3,
                    
                    //     摘要:
                    //     Decrements the current stencil buffer value. Clamps to 0.
                    //     DecrementSaturate = 4,
                    
                    //     摘要:
                    //     Bitwise inverts the current stencil buffer value.
                    //     Invert = 5,
                    
                    //     摘要:
                    //     Increments the current stencil buffer value. Wraps stencil buffer value to zero
                    //     when incrementing the maximum representable unsigned value.
                    //     IncrementWrap = 6,
                    
                    //     摘要:
                    //     Decrements the current stencil buffer value. Wraps stencil buffer value to the
                    //     maximum representable unsigned value when decrementing a stencil buffer value
                    //     of zero.
                    //     DecrementWrap = 7
                // }
            }            


            // cull back
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Cginc/HLSL/BRDFCORE.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal:NORMAL;
                float4 color:COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                half fogFactory:TEXCOORD1;
                float3 worldPos:TEXCOORD2;
                float4 color:COLOR;
                float3 normal:NORMAL;
                float4 vertex : SV_POSITION;
                
                float4 shadowCoord:TEXCOORD3;
                float3 sh:TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Color;
            CBUFFER_END

            sampler2D _MainTex;
            v2f vert (appdata v)
            {
                v2f o=(v2f)0;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.color=v.color*_Color;
                o.normal=TransformObjectToWorldNormal(v.normal.xyz) ;           
                o.worldPos=TransformObjectToWorld(v.vertex.xyz);
                o.shadowCoord= TransformWorldToShadowCoord(o.worldPos);
                o.fogFactory=ComputeFogFactor(o.vertex.z);
                o.sh=SampleSHVertex(o.normal);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 col = tex2D(_MainTex, i.uv);
                
                Light mainLight = GetMainLight(i.shadowCoord);
                float3 normal=normalize(i.normal);
                
                float3 diff = dot(mainLight.direction, normal)*mainLight.color;
                
                half3 ambient=SampleSHVertex(i.normal);
                col.rgb*= diff+ambient;
                col.rgb*= mainLight.shadowAttenuation;
                col*=i.color;
                col.rgb= MixFog(col.rgb,i.fogFactory);
                
                return col;
            }
            ENDHLSL
        }
    }
}
