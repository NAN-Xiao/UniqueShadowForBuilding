Shader "222"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UniqueShadowTexture("u_UniqueShadowTexture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UniqueShaodw.cginc"
            #pragma multi_compile _ SUPPORT_SHADOWMAP 
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_SHADOW_COORDS(2)
                float4 posWorld : TEXCOORD3;

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o=(v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNIQUE_SHADOW_TRANSFER(v)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb*=UNITY_SHADOW_ATTENUATION(i);
                return col;
            }
            ENDCG
        }
        
    }
}
