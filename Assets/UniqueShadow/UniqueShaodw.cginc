#ifndef UNITQUESHADOW

   #define UNITQUESHADOW
   #include "UnityCG.cginc"


   static half2 poisson4[4] =
   {
      half2( -0.94201624, -0.39906216 ),
      half2( 0.94558609, -0.76890725 ),
      half2( -0.094184101, -0.92938870 ),
      half2( 0.34495938, 0.29387760 )
   };

   UNITY_DECLARE_SHADOWMAP(_UniqueShadowTexture);
   //sampler2D _UniqueShadowTexture;
   float _UniqueShadowFilterWidth;
   float4x4 _UniqueShadowMatrix[2];
   float _UniqueShadowStrength;

   float4 _UniqueShadowMapSize;
   float _ESMConst;
   float _VSMMin;
   float _SoftShadow;
   float4x4 _W2CameraPos;
   float _SplitFar;

   
    //shadowcaster
    #ifdef _UniqueShadowCaster
    float3 _CustomLightDir;
                float _NorBias;
    #endif




   float SampleShaodowPoisson(float4 coord)
   {
      float shadow=0;
      for(int i=0;i<4;i++)
      {
         float4 uv=coord;
         uv.xy+=poisson4[i]*_SoftShadow;
         shadow+= UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,uv);
      }
      return shadow*=0.25;
   }

   float SampleShadowPCF3x3_4Tap(float3 uvd){
      _UniqueShadowMapSize+=_SoftShadow;
      float offsetX = _UniqueShadowMapSize.x * 0.5;
      float offsetY = _UniqueShadowMapSize.y * 0.5;
      float4 result;
      result.x = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uvd.x - offsetX, uvd.y - offsetY, uvd.z));
      result.y = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uvd.x + offsetX, uvd.y - offsetY, uvd.z));
      result.z = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uvd.x - offsetX, uvd.y + offsetY, uvd.z));
      result.w = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uvd.x + offsetX, uvd.y + offsetY, uvd.z));
      return dot(result,0.25);
   }


   half4 UniqueShadowUVW(float4 vpos)
   {
      //      float4 WorldPos=mul(unity_ObjectToWorld,vpos);
      return mul(unity_ObjectToWorld,vpos);;//mul(_UniqueShadowMatrix[0], float4(WorldPos.xyz, 1.f));
   }


   float3 SampleUniqueShadow(float4 WorldPos)
   {
      float4 sc0=mul(_UniqueShadowMatrix[0], float4(WorldPos.xyz, 1.f));
      sc0.xy=sc0.xy*0.5f+0.5;
      sc0.x*=0.5;
      
      float4 sc1=mul(_UniqueShadowMatrix[1], float4(WorldPos.xyz, 1.f));
      sc1.xy=sc1.xy*0.5+0.5;
      sc1.x*=0.5;
      sc1.x+=0.5;
      
      float weidth=length(WorldPos-_WorldSpaceCameraPos);
      float4 coord=sc0*(weidth>_SplitFar)+sc1*(weidth<_SplitFar);
      float3 shadow=SampleShadowPCF3x3_4Tap(coord);
      return  lerp(1,shadow,_UniqueShadowStrength);//  lerp(v,ab,w);
   }
   
   #define UNITY_SHADOW_COORDS(i)                                   half4 uniqueShadowPos : TEXCOORD##i ;
   #define UNIQUE_SHADOW_TRANSFER(v)			                       o.uniqueShadowPos =UniqueShadowUVW(v.vertex);
   #define UNITY_SHADOW_ATTENUATION(i)                              SampleUniqueShadow(i.uniqueShadowPos);
   
   
   
         #ifdef _UniqueShadowCaster
       float4 UniqueShaodwNormalBias(float4 vertex,float3 normal)
    {
            float3 WorldN=mul((float3x3)unity_ObjectToWorld,normal);
                float Acos=dot(WorldN,WorldN);
                float Asin=sqrt(1-Acos*Acos);
                float bias=_NorBias*Asin;
                float4 worldPos=mul(unity_ObjectToWorld,vertex);
                worldPos.xyz-=WorldN*bias;
				return  mul(UNITY_MATRIX_VP,worldPos);
    }

   #define  UNIQUE_SHADOW_NORBIAS(o)                               o.pos= UniqueShaodwNormalBias(v.vertex, v.normal)
   #endif
   
   

#endif

