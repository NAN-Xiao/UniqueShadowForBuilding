Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _UniqueShadowTexture ("Texture", 2D) = "white" {}
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
            sampler2D _UniqueShadowTexture;
            //TEXTURE2D_SHADOW(_UniqueShadowTexture);//
            //SAMPLER_CMP(sampler_UniqueShadowTexture);
            float _UniqueShadowFilterWidth;
            float4x4 _UniqueShadowMatrix;


            static half2 poisson[8] =
            {
                half2(0.02971195f, -0.8905211f),
                half2(0.2495298f, 0.732075f),
                half2(-0.3469206f, -0.6437836f),
                half2(-0.01878909f, 0.4827394f),
                half2(-0.2725213f, -0.896188f),
                half2(-0.6814336f, 0.6480481f),
                half2(0.4152045f, -0.2794172f),
                half2(0.1310554f, 0.2675925f),
            };

            ///https://github.com/opengl-tutorials/ogl/blob/master/tutorial16_shadowmaps/ShadowMapping.fragmentshader#L20-L37

            static half2 PoissonDisk[16] =
            {
                half2( -0.94201624, -0.39906216 ), 
                half2( 0.94558609, -0.76890725 ), 
                half2( -0.094184101, -0.92938870 ), 
                half2( 0.34495938, 0.29387760 ), 
                half2( -0.91588581, 0.45771432 ), 
                half2( -0.81544232, -0.87912464 ), 
                half2( -0.38277543, 0.27676845 ), 
                half2( 0.97484398, 0.75648379 ), 
                half2( 0.44323325, -0.97511554 ), 
                half2( 0.53742981, -0.47373420 ), 
                half2( -0.26496911, -0.41893023 ), 
                half2( 0.79197514, 0.19090188 ), 
                half2( -0.24188840, 0.99706507 ), 
                half2( -0.81409955, 0.91437590 ), 
                half2( 0.19984126, 0.78641367 ), 
                half2( 0.14383161, -0.14100790 )
            };

            float random(float3 seed, int i)
            {
                float4 seed4 = float4(seed,i);
                float dot_product = dot(seed4, float4(12.9898,78.233,45.164,94.673));
                return frac(sin(dot_product) * 43758.5453);
            }


            half SampleUnique(half4 shadowCoord)
            {



                half4 uv = shadowCoord;
                half shadow = 0.f;
                UNITY_LOOP
                for(int i = 0; i < 8; ++i)
                {
                    uv.xy = shadowCoord.xy + poisson[i]*_UniqueShadowFilterWidth;
                    shadow += (shadowCoord.z  > DecodeFloatRGBA(tex2D(_UniqueShadowTexture,uv)) ? 1.0 : 0.0);   
                }        
                return shadow /8.0f;
            }

            float4 TransformWorldToShadowCoord(float3 positionWS)
            {
                return mul(_UniqueShadowMatrix, float4(positionWS, 1.0));
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 shadowcoord:texcoord2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.shadowcoord=TransformWorldToShadowCoord(mul(unity_ObjectToWorld,v.vertex));
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture//
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb*=SampleUnique(i.shadowcoord);
                //  col.rgb=LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_UniqueShadowTexture,i.shadowcoord));
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
