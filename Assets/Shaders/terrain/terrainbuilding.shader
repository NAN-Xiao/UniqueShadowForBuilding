Shader "Faster/Terrain/Ground" {

    Properties
    {
        _TintColor("_Tint",Color)=(1,1,1,1)
        _MainTex("_MainTex", 2D) = "white" {}
        
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "QUEUE"="Transparent-500" "LightMode" = "ForwardBase"}
        LOD 100
        Pass
        {
            ZWrite Off
            Blend srcalpha OneMinusSrcAlpha
            ColorMask RGB
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile_fwdbase
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile_fog
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "lighting.cginc"


            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _TintColor;
            struct appdata {
                fixed4 vertex : POSITION;

                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
            };


            struct v2f
            {
                float2 uv : TEXCOORD0;
                
                #ifndef LIGHTMAP_OFF
                    float2 lightmapUV:TEXCOORD5;
                #endif
                float4 pos : SV_POSITION;
                
                UNITY_FOG_COORDS(6)
                SHADOW_COORDS(15)
            };



            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord0, _MainTex);
                
                UNITY_TRANSFER_FOG(o, o.pos);
                #ifndef LIGHTMAP_OFF
                    o.lightmapUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                TRANSFER_SHADOW(o)  
                return o;
            }
            fixed4 frag(v2f i) : SV_Target
            {
                
                fixed4 c = tex2D(_MainTex, i.uv.xy)*_TintColor;
                fixed shadow = SHADOW_ATTENUATION(i); 
                c.rgb*= shadow;
                UNITY_APPLY_FOG(i.fogCoord, c.rgb);
                return c;
            }
            ENDCG
        }
    }
  //  FallBack "Specular"
}