Shader "Faster/Terrain/terrain_Mix_Light" {

    Properties
    {
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
        [Toggle(Simplify)] Simplify("Simplify",int)=0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque"}
        LOD 100
        Pass
        {
            Tags {  "LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile _ Simplify
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "lighting.cginc"


            sampler2D _Splat0;
            sampler2D _Splat1;
            sampler2D _Splat2;
            sampler2D _Splat3;
            sampler2D _Control;
            

            float4 _Splat0_ST;
            float4 _Splat1_ST;
            float4 _Splat2_ST;
            float4 _Splat3_ST;
            

            float4 _Color0;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;

            float4 _Tint;
            struct appdata {
                fixed4 vertex : POSITION;
                fixed3 normal : NORMAL;
                // fixed4 tangent : TANGENT;*/
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
                #ifndef LIGHTMAP_OFF
                    float2 lightmapUV:TEXCOORD5;
                #endif
                float3 worldNormal :TEXCOORD7;
                float4 worldPos:TEXCOORD8;
                UNITY_FOG_COORDS(6)
                SHADOW_COORDS(15)    
            };



            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _Splat0);
                o.uv1 = TRANSFORM_TEX(v.texcoord0, _Splat1);
                o.uv2 = TRANSFORM_TEX(v.texcoord0, _Splat2);
                o.uv3 = TRANSFORM_TEX(v.texcoord0, _Splat3);
                o.uv4 = v.texcoord0;// TRANSFORM_TEX(v.texcoord, _Control);
                o.worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o, o.pos);
                #ifndef LIGHTMAP_OFF
                    o.lightmapUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                
                TRANSFER_SHADOW(o) 
                return o;
            }
            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 Mask;
                Mask.xyz = tex2D(_Control, i.uv4.xy).xyz;
                Mask.w = 1.0 - Mask.x - Mask.y - Mask.z;
                float3 normal=normalize(i.worldNormal);
                fixed3 c;
                #ifndef Simplify
                    fixed3 lay1 = tex2D(_Splat0, i.uv0.xy);
                    fixed3 lay2 = tex2D(_Splat1, i.uv1.xy);
                    fixed3 lay3 = tex2D(_Splat2, i.uv2.xy);
                    fixed3 lay4 = tex2D(_Splat3, i.uv3.xy);

                    
                    
                    c = (lay1.xyz * Mask.r + lay2.xyz * Mask.g + lay3.xyz * Mask.b + lay4.xyz * Mask.a);
                #else
                    c = (_Color0.xyz * Mask.r + _Color1.xyz * Mask.g + _Color2.xyz * Mask.b + _Color3.xyz * Mask.a);
                #endif
                #ifndef LIGHTMAP_OFF
                    fixed3 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV));
                    c.rgb *= lm;
                #endif
                float3 lightdir = normalize(_WorldSpaceLightPos0);
                float3 diff = dot(lightdir, normal)*_LightColor0.rgb;
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos.xyz);
                half3 ambient=ShadeSH9(float4(normal,1));
                c *= diff+ambient;
                c*= atten;
                
                
                UNITY_APPLY_FOG(i.fogCoord, c);
                return float4(c*_Tint.rbg,1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}