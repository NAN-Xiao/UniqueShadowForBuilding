Shader "Hidden/_UniqueShadowCaster"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            //sampler2D _MainTex;
            // float4 _MainTex_ST;
            //uniform float3 _UniqueLightDir;
            uniform float _NormalBias;
            v2f vert (appdata v)
            {
                v2f o;
                float3 WorldN=mul((float3x3)unity_ObjectToWorld,v.normal);
                float Acos=dot(WorldN,_WorldSpaceLightPos0);
                float Asin=sqrt(1-Acos*Acos);
                float bias=_NormalBias*Asin;
                float4 worldPos=mul(unity_ObjectToWorld,v.vertex);
                worldPos.xyz-=WorldN*bias;
                o.vertex=mul(UNITY_MATRIX_VP,worldPos);
                o.uv=v.uv;
                return  o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return 0;
            }
            ENDCG
        }
    }
}
