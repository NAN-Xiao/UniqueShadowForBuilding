// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Faster/Terrain/Grass" {
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
        Tags {"Queue"="AlphaTest+50" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        LOD 100

        Tags { "RenderType"="Opaque" }
        LOD 100
        cull off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "lighting.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD3;

                #ifndef LIGHTMAP_OFF
                    float2 lightmapUV:TEXCOORD5;
                #endif
                UNITY_FOG_COORDS(6)
                SHADOW_COORDS(15)  
                    UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex,_noiseTex;
            float4 _MainTex_ST,_noiseTex_ST;
            float4 _Dirction;
            float _weight,_Wave,_Strengh,_OffsetRadio;
            float _Cutoff;
            float4 _Color0, _Color1;
            float _Gradient;
            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
               // TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)


                float3 wp=mul(unity_ObjectToWorld,v.vertex);
                float3 offset=clamp(0,1,wp.y-_weight);
                float rip=sin(_Time.y*_Wave*UNITY_PI+wp.x+wp.z*10)*_Strengh;
                float3 of=(rip)*_Dirction.xyz*offset;

                v.vertex.xyz+=of;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = v.vertex.yz;
                #ifndef LIGHTMAP_OFF
                    o.lightmapUV = v.uv.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
              col.rgb *=lerp(_Color1.rgb,_Color0.rgb, i.uv.z* _Gradient) ;

             
                #ifndef LIGHTMAP_OFF
                    fixed3 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV));
                    col.rgb *= lm;
                #endif
                UNITY_APPLY_FOG(i.fogCoord, col);
                clip(col.a - _Cutoff);
                return col;
            }
            ENDCG
        }
        // Pass to render object as a shadow caster
        Pass {
            Name "Caster"
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
            #include "UnityCG.cginc"

            struct v2f {
                V2F_SHADOW_CASTER;
                float2  uv : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            uniform float4 _MainTex_ST;
            uniform sampler2D _MainTex;
            uniform fixed _Cutoff;
            uniform fixed4 _Color;


            float4 _Dirction;
            float _weight, _Wave, _Strengh, _OffsetRadio;

            v2f vert( appdata_base v )
            {
                v2f o;
                float3 wp = mul(unity_ObjectToWorld, v.vertex);
                float3 offset = clamp(0, 1, wp.y - _weight);
                float rip = sin(_Time.y * _Wave * UNITY_PI * +(wp.x + wp.z) * 10) * _Strengh;
                float3 of = (rip)*_Dirction.xyz * offset;
                v.vertex.xyz += of;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

       
            float4 frag( v2f i ) : SV_Target
            {
                fixed4 texcol = tex2D( _MainTex, i.uv );
                clip( texcol.a*_Color.a - _Cutoff );

                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG

        }

    }

}
