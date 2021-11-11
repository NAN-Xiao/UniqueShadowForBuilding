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
                UNITY_SHADOW_COORDS(2)//仅仅是阴影
            };
            sampler2D _MainTex;
         
            UNITY_DECLARE_SHADOWMAP(ShadowDepth);
            uniform float4x4 _world2shadow[2];
               uniform float4x4 _ViewProjInv;
            v2f vert (appdata v)
            {
                v2f o=(v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =v.uv;
                TRANSFER_SHADOW(o);//仅仅是阴影
                return o;
            }
            
            fixed4 frag (v2f i) : COLOR
            {
                float4 col=float4(1,1,1,1);
                float depth_ = tex2D(_MainTex, i.uv).r;
                
                float4 clip;
                clip.xy=i.uv.xy*2-1;
                clip.z=depth_;
                clip.w=1;
                
                
                float4 worldPos=mul(_ViewProjInv,clip);
                worldPos/=worldPos.w;
                
                
                
                
                float4 shadowcoord=mul(_UniqueShadowMatrix[1],float4(worldPos.xyz,1));
                shadowcoord/=shadowcoord.w;
                shadowcoord.xy=shadowcoord.xy*0.5+0.5;
                shadowcoord.x*=0.5;
                shadowcoord.x+=0.5;
                float shadow=  SampleUniqueShadow(worldPos);
 
                return shadow;
                
            }
            ENDCG
        }
    }
}
