Shader "Faster/Common//treeanimation"
{
    Properties
    {
        _MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
        _Wind("_Wind",vector) = (1,1,1,1)
        _WindSpeed("_WindSpeed",float) = 1
        _Cutoff("Alpha cutoff", Range(0,1)) = 0.5
        //  [Toggle(DoubleSide)]_DoubleSide("2Side",int)=1 
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" "DisableBatching"="True"}
        LOD 100
        Pass
        { 
            Tags { "LightMode" = "ForwardBase"}
            // cull [_DoubleSide]
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fwdadd_fullshadows
            #include "UnityCg.cginc"
            #include "AutoLight.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Assets/Shaders/CgInc/Wind.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldnormal:NORMAL;
                float3 worldPos:TEXCOORD1;
                #ifndef LIGHTMAP_OFF
                    float2 lightmapUV:TEXCOORD5;
                #endif
                UNITY_FOG_COORDS(6)
                LIGHTING_COORDS(2,3)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Wind;
            float _Cutoff;
            float _WindSpeed;

            v2f vert (appdata v)
            {
                v2f o=(v2f)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                float3 objectPosition=float3(unity_ObjectToWorld._m03,unity_ObjectToWorld._m13,unity_ObjectToWorld._m23);
                float2 wind=normalize(_Wind.xz);
                float speed=sin(_Time.y*_WindSpeed);
                ApplyMainBending(v.vertex.xyz,wind,0.01*speed);
                float windStrength = length(_Wind);
                ApplyDetailBending(
                v.vertex.xyz,
                v.normal,
                objectPosition,	
                v.color.a,					//1 Leaf phase - not used in this scenario, but would allow for variation in side-to-side motion
                v.color.g,		            //2
                _Time*_WindSpeed,           //3
                v.color.r,		            //4 edge attenuation, leaf stiffness
                1 -  v.color.b,             //5 branch attenuation. High values close to stem, low values furthest from stem.
                // For some reason, Crysis uses solid blue for non-moving, and black for most movement.
                // So we invert the blue value here.
                windStrength,               //6 branch amplitude. Play with this until it looks good.
                2,					        //7 Speed. Play with this until it looks good.
                1,					        //8 Detail frequency. Keep this at 1 unless you want to have different per-leaf frequency
                windStrength	            //9 Detail amplitude. Play with this until it looks good.
                );
                o.pos =UnityObjectToClipPos( v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                #ifndef LIGHTMAP_OFF
                    o.lightmapUV = v.uv.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                o.worldnormal=mul((float3x3)unity_ObjectToWorld,v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                UNITY_TRANSFER_FOG(o,o.pos);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 lightdir = normalize(_WorldSpaceLightPos0.xyz);
                float3 normal=normalize(i.worldnormal);
                float diff=max(0,dot(lightdir,normal));
                fixed4 col = tex2D(_MainTex, i.uv);
                half3 ambient_contrib =ShadeSH9(float4(normal,1));
                
                col.rgb*=diff*_LightColor0.rgb+ambient_contrib;
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                col.rgb*=atten;
                clip(col.a - _Cutoff);
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                
                return col;
            }
            ENDCG
        }
        Pass
        {
            Tags{"LightMode" = "ShadowCaster"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
            #include "Assets/Shaders/CgInc/Wind.cginc"
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;
            float _WindSpeed;
            float4 _Wind;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct v2f
            {
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD0;
                //float4 color:COLOR;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                float3 objectPosition=float3(unity_ObjectToWorld._m03,unity_ObjectToWorld._m13,unity_ObjectToWorld._m23);
                float2 wind=normalize(_Wind.xz);
                float speed=sin(_Time.y*_WindSpeed);
                ApplyMainBending(v.vertex.xyz,wind,0.01*speed);
                float windStrength = length(_Wind);
                ApplyDetailBending(
                v.vertex.xyz,
                v.normal,
                objectPosition,	
                v.color.a,					//1 Leaf phase - not used in this scenario, but would allow for variation in side-to-side motion
                v.color.g,		            //2
                _Time*_WindSpeed,           //3
                v.color.r,		            //4 edge attenuation, leaf stiffness
                1 -  v.color.b,             //5 branch attenuation. High values close to stem, low values furthest from stem.
                // For some reason, Crysis uses solid blue for non-moving, and black for most movement.
                // So we invert the blue value here.
                windStrength,               //6 branch amplitude. Play with this until it looks good.
                2,					        //7 Speed. Play with this until it looks good.
                1,					        //8 Detail frequency. Keep this at 1 unless you want to have different per-leaf frequency
                windStrength	            //9 Detail amplitude. Play with this until it looks good.
                );

                
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_TARGET
            {
                fixed4 testColor = tex2D(_MainTex, i.uv);	
                clip(testColor.a - _Cutoff);//对于AlphaTest来说把看不见的片元去掉才能生成正确的阴影图
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
        
    }
    
}
