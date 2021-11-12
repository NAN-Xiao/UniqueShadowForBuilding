Shader "textureblur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        CGINCLUDE

          #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform float _BlurRadius;
            
        
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv0 : TEXCOORD0;
                 float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                    float2 uv4 : TEXCOORD4;
                float4 vertex : SV_POSITION;
            };

            v2f vert_horizontal (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv0 =v.uv;
                  o.uv1 =v.uv+float2(-2,0)*_BlurRadius;
                    o.uv2 =v.uv+float2(-1,0)*_BlurRadius;
                      o.uv3 =v.uv+float2(2,0)*_BlurRadius;
                        o.uv4 =v.uv+float2(1,0)*_BlurRadius;
                return o;
            }
             v2f vert_vertical (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv0 =v.uv;
                  o.uv1 =v.uv+float2(0,-2)*_BlurRadius;
                    o.uv2 =v.uv+float2(0,-1)*_BlurRadius;
                      o.uv3 =v.uv+float2(0,2)*_BlurRadius;
                        o.uv4 =v.uv+float2(0,1)*_BlurRadius;
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                
               
                fixed4 col = tex2D(_MainTex, i.uv0)*0.4;
                     col+=  tex2D(_MainTex, i.uv1)*0.1;
                      col+= tex2D(_MainTex, i.uv2)*0.2;
                       col+= tex2D(_MainTex, i.uv3)*0.1;
                        col+= tex2D(_MainTex, i.uv4)*0.2;
                        
            
                return col;
            }
        ENDCG
        
          ZTest Always
        Cull Off
        ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_horizontal
            #pragma fragment frag
            ENDCG
        }
        
           Pass
        {
            CGPROGRAM
            #pragma vertex vert_vertical
            #pragma fragment frag
             ENDCG
        }
    }
}
