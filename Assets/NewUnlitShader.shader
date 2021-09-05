Shader "UniqueShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UniqueShadowTexture ("Texture", 2D) = "white" {}
unity_RandomRotation16("Texture", 2D) = "white" {}
       // u_UniqueShadowTexture("u_UniqueShadowTexture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
            #pragma exclude_renderers d3d11 gles
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityShadowLibrary.cginc"
          


    float4x4 _UniqueShadowMatrix;

uniform Texture2D _UniqueShadowTexture	;
uniform SamplerComparisonState sampler_UniqueShadowTexture;
float4 TransformWorldToShadowCoord(float3 worldPos)
  {
        return mul(_UniqueShadowMatrix, float4(worldPos, 1.0));
    }
       

static half2 poisson[40] = {
		half2(0.02971195f, 0.8905211f),
		half2(0.2495298f, 0.732075f),
		half2(-0.3469206f, 0.6437836f),
		half2(-0.01878909f, 0.4827394f),
		half2(-0.2725213f, 0.896188f),
		half2(-0.6814336f, 0.6480481f),
		half2(0.4152045f, 0.2794172f),
		half2(0.1310554f, 0.2675925f),
		half2(0.5344744f, 0.5624411f),
		half2(0.8385689f, 0.5137348f),
		half2(0.6045052f, 0.08393857f),
		half2(0.4643163f, 0.8684642f),
		half2(0.335507f, -0.110113f),
		half2(0.03007669f, -0.0007075319f),
		half2(0.8077537f, 0.2551664f),
		half2(-0.1521498f, 0.2429521f),
		half2(-0.2997617f, 0.0234927f),
		half2(0.2587779f, -0.4226915f),
		half2(-0.01448214f, -0.2720358f),
		half2(-0.3937779f, -0.228529f),
		half2(-0.7833176f, 0.1737299f),
		half2(-0.4447537f, 0.2582748f),
		half2(-0.9030743f, 0.406874f),
		half2(-0.729588f, -0.2115215f),
		half2(-0.5383645f, -0.6681151f),
		half2(-0.07709587f, -0.5395499f),
		half2(-0.3402214f, -0.4782109f),
		half2(-0.5580465f, 0.01399586f),
		half2(-0.105644f, -0.9191031f),
		half2(-0.8343651f, -0.4750755f),
		half2(-0.9959937f, -0.0540134f),
		half2(0.1747736f, -0.936202f),
		half2(-0.3642297f, -0.926432f),
		half2(0.1719682f, -0.6798802f),
		half2(0.4424475f, -0.7744268f),
		half2(0.6849481f, -0.3031401f),
		half2(0.5453879f, -0.5152272f),
		half2(0.9634013f, -0.2050581f),
		half2(0.9907925f, 0.08320642f),
		half2(0.8386722f, -0.5428791f)
	};
       struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 shadowcoord:texcoord2;
                
        
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float SamplerShadow()
{

}


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.shadowcoord=TransformWorldToShadowCoord(mul(unity_ObjectToWorld,v.vertex));
      
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
		        col *= _UniqueShadowTexture.SampleCmp(sampler_UniqueShadowTexture,i.shadowcoord, i.shadowcoord.z);
                
              //  col*=SampleVSMPreFilteredShadowmap(i.worldPos);/
                return col;
            }
            ENDCG
        }
    }
}
