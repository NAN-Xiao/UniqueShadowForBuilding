Shader "Faster/Terrain/mountain"
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
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        LOD 100
        
        Pass
        {
            ZWrite On
            ColorMask 0
        }
        Pass
        {    
            // Tags {
                //     "LightMode" = "ForwardBase"
            // }
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "lighting.cginc"

            

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

                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal:NORMAL;
                float4 color:COLOR;
                float4 worldPos:TEXCOORD5;
            };

            sampler2D _Splat0;
            sampler2D _Splat1;
            sampler2D _Splat2;
            sampler2D _Control;
            

            float4 _Splat0_ST;
            float4 _Splat1_ST;
            float4 _Splat2_ST;
            float4 _Control_ST;
            float4 _Tint;
            v2f vert (appdata v)
            {
                v2f o=(v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv0 = TRANSFORM_TEX(v.texcoord0, _Splat0);
                o.uv1 = TRANSFORM_TEX(v.texcoord0, _Splat1);
                o.uv2 = TRANSFORM_TEX(v.texcoord0, _Splat2);
                o.uv3 = TRANSFORM_TEX(v.texcoord0,_Control);
                
                o.normal=mul((float3x3)unity_ObjectToWorld,v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex);
                o.color=_Tint*v.color;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
                
                float3 normal=normalize(i.normal);
                float nl =max(0,dot(normal, lightDir));
                float4 Mask =tex2D(_Control, i.uv3);;
                fixed3 lay1 = tex2D(_Splat0, i.uv0);
                fixed3 lay2 = tex2D(_Splat1, i.uv1);
                fixed3 lay3 = tex2D(_Splat2, i.uv2);
                fixed3 c;
                c = (lay1.xyz * Mask.r + lay2.xyz * Mask.g + lay3.xyz * Mask.b );
                half3 ambient =ShadeSH9(float4(normal,1));
                c.rgb*=nl*lightColor+ambient;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return  float4(c,Mask.a);
            }
            ENDCG
        }
    }
}
