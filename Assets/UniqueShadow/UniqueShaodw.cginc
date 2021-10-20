#ifndef UNITQUESHADOW

   #define UNITQUESHADOW
   #include "UnityCG.cginc"
   
   UNITY_DECLARE_SHADOWMAP(_UniqueShadowTexture);
   //sampler2D _UniqueShadowTexture;
   static half2 poisson4[4] =
   {
      half2( -0.94201624, -0.39906216 ),
      half2( 0.94558609, -0.76890725 ),
      half2( -0.094184101, -0.92938870 ),
      half2( 0.34495938, 0.29387760 )
   };
   float _UniqueShadowFilterWidth;
   float4x4 _UniqueShadowMatrix[2];
   float _UniqueShadowStrength;
   float _UniqueShadowMapSize;
   float _ESMConst;
   float _VSMMin;
   
   float4x4 _W2CameraPos;
   float _SplitFar;

   float SampleShaodowPCF(float4 coord)
   {
      float shadow=0;
      for(int i=0;i<4;i++)
      {
         float4 uv=coord;
         uv.xy+=poisson4[i]*0.0002f;
         shadow+= UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,uv);
      }
      return shadow*=0.25;
   }

   half4 UniqueShadowUVW(float4 vpos)
   {
      //      float4 WorldPos=mul(unity_ObjectToWorld,vpos);
      return mul(unity_ObjectToWorld,vpos);;//mul(_UniqueShadowMatrix[0], float4(WorldPos.xyz, 1.f));
   }
   float3 SampleUniqueShadow(float4 WorldPos)
   {
      float4 sc0=mul(_UniqueShadowMatrix[0], float4(WorldPos.xyz, 1.f));
      float4 uv0=sc0*0.5f+0.5;
      uv0.x*=0.5;
      uv0.z=sc0.z;
      
      float4 sc1=mul(_UniqueShadowMatrix[1], float4(WorldPos.xyz, 1.f));
      float4 uv1=sc1*0.5f+0.5;
      uv1.x*=0.5;
      uv1.x+=0.5;
      uv1.z=sc1.z;

      float4 f=mul(_W2CameraPos, WorldPos);
      
      // float v=UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,uv1);
      // float ab=UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,uv0);
      float v=  SampleShaodowPCF(uv1);
      float ab=  SampleShaodowPCF(uv0);
      // float3 v=tex2D(_UniqueShadowTexture,uv1);
      // float3 ab=tex2D(_UniqueShadowTexture,uv0);
      //v=0;
      float3 shadow=ab*(-f.z>_SplitFar)+v*(-f.z<_SplitFar);
      return lerp(1,ab*(-f.z>_SplitFar)+v*(-f.z<_SplitFar),_UniqueShadowStrength);//  lerp(v,ab,w);
   }
   
   #define UNITY_SHADOW_COORDS(i)                                   half4 uniqueShadowPos : TEXCOORD##i ;
   #define UNIQUE_SHADOW_TRANSFER(v)			                       o.uniqueShadowPos =UniqueShadowUVW(v.vertex);
   #define UNITY_SHADOW_ATTENUATION(i)                              SampleUniqueShadow(i.uniqueShadowPos);
#endif

