Shader "Depth2World"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        ShadowDepth ("Texture", 2D) = "white" {}
        CameraDepth ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        
        Pass //0
        {
            CGPROGRAM
            

            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ SUPPORT_SHADOWMAP
            #pragma multi_compile  UNIQUESHADOW
            
            #include "UnityCg.cginc"
            #include "AutoLight.cginc"
            #include "Assets/Shaders/Cginc/UniqueShaodw.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent:TANGENT;
                float2 uv : TEXCOORD0;

            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            sampler2D _MainTex;
            uniform float4x4 _ViewProjInv;
            uniform  float ContertDis;
            v2f vert (appdata v)
            {
                v2f o=(v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =v.uv;
                
                return o;
            }
            
            fixed4 frag (v2f i) : COLOR
            {
                float depth_ = tex2D(_MainTex, i.uv).r;
                float4 clip=Invers2WorldPos(float3(i.uv.xy,depth_));
                float4 worldPos=mul(_ViewProjInv,clip);
                worldPos/=worldPos.w;
                float shadow= SampleUniqueShadow(worldPos);
                return shadow;
            }
            ENDCG
        }
    }
}
