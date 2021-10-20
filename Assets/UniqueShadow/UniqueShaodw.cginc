#ifndef UNITQUESHADOW

   #define UNITQUESHADOW
   #include "UnityCG.cginc"
   
   UNITY_DECLARE_SHADOWMAP(_UniqueShadowTexture);
   //   sampler2D _UniqueShadowTexture;

   float _UniqueShadowFilterWidth;
   float4x4 _UniqueShadowMatrix[2];
   float _UniqueShadowStrength;
   float _UniqueShadowMapSize;
   float _ESMConst;
   float _VSMMin;
   
   float4x4 _W2CameraPos;
   float _SplitFar;
   half4 UniqueShadowUVW(float4 vpos)
   {
      //      float4 WorldPos=mul(unity_ObjectToWorld,vpos);
      return mul(unity_ObjectToWorld,vpos);;//mul(_UniqueShadowMatrix[0], float4(WorldPos.xyz, 1.f));
   }
   float SampleUniqueShadow(float4 WorldPos)
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

      //_SplitFar=;
      float4 f=mul(_W2CameraPos, WorldPos);
      // float w=saturate((-f.z)/_SplitFar);
      //f/=f.w;
      float v=UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,uv1);
      float ab=UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,uv0);
      float shadow=ab*(-f.z>_SplitFar)+v*(-f.z<_SplitFar);
      return lerp(1,ab*(-f.z>_SplitFar)+v*(-f.z<_SplitFar),_UniqueShadowStrength);//  lerp(v,ab,w);
   }
   
   #define UNITY_SHADOW_COORDS(i)                                   half4 uniqueShadowPos : TEXCOORD##i ;
   #define UNIQUE_SHADOW_TRANSFER(v)			                       o.uniqueShadowPos =UniqueShadowUVW(v.vertex);
   #define UNITY_SHADOW_ATTENUATION(i)                              SampleUniqueShadow(i.uniqueShadowPos);
#endif

