Shader "Faster/Terrain/hole"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",color)=(1,1,1,1)
        _Ref("refvalue",float)=1
        com("Compare",int)=1
        stencilOperation("stencilOperation",int)=1
        _ZWrite("_ZWrite",int)=1
        _SrcBlend("_SrcBlend",int)=1
        _DstBlend("_DstBlend",int)=0
    }
    SubShader
    {
        Tags { "RenderType"="Geometry-10" }
        LOD 100
        ZWrite[_ZWrite]
        Blend [_SrcBlend] [_DstBlend]
        
        Pass
        {

            
            Stencil
            {
                Ref 3
                Comp Always
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
                Pass Replace
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


            cull front
            ColorMask 0
            
        }
        Pass
        {


            Stencil
            {
                Ref [_Ref]
                Comp [com]
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
                Pass [stencilOperation]
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


            cull back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "lighting.cginc"

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
                UNITY_FOG_COORDS(1)
                float4 color:COLOR;
                float3 normal:NORMAL;
                float4 vertex : SV_POSITION;
                float3 worldPos:TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            v2f vert (appdata v)
            {
                v2f o=(v2f)0;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.color=v.color;
                o.normal=mul((float3x3)unity_ObjectToWorld,v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
                #ifndef LIGHTMAP_OFF
                    fixed3 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV));
                    c.rgb *= lm;
                #endif
                float3 normal=normalize(i.normal);
                float3 lightdir = normalize(_WorldSpaceLightPos0);
                float3 diff = dot(lightdir, normal)*_LightColor0.rgb;
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos.xyz);
                half3 ambient=ShadeSH9(float4(normal,1));
                col.rgb*= diff+ambient;
                col.rgb*= atten;
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                return col*_Color*i.color;
            }
            ENDCG
        }
    }
}
