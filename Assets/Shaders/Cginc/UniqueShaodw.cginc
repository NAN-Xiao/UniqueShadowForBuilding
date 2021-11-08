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
   //Texture2D _UniqueShadowTexture;
   #if SUPPORT_SHADOWMAP
      UNITY_DECLARE_SHADOWMAP(_UniqueShadowTexture);
   #else
      sampler2D _UniqueShadowTexture;//sampler;
   #endif
   float _UniqueShadowFilterWidth;
   float4x4 _UniqueShadowMatrix[2];
   float _UniqueShadowStrength;
   float4 _UniqueShadowMapSize;//float4(1/1024,1/1024,1024,1024);
   float _SoftShadow;
   float _SplitFar;
   //shadowcaster
   //#ifdef _UniqueShadowCaster
   float3 _CustomLightDir;
   float4 _BiasData;
   //#endif
   float _ESMConst;
   float _VSMMin;
   
   
   
   float SampleShadowMap(float3 coord)
   {
      float shadow=0;
      #if SUPPORT_SHADOWMAP
         shadow= UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,coord);
      #else
         shadow= coord.z>tex2D(_UniqueShadowTexture,coord).x?1:0;
      #endif
      return shadow;
   }
   
   static float2 GetGroupTapUV(float2 groupCenterCoord,float2 weightsX,float2 weightsY){
      float offsetX = weightsX.y / (weightsX.x+ weightsX.y);
      float offsetY = weightsY.y / (weightsY.x + weightsY.y);
      float2 coord = groupCenterCoord-0.5 + float2(offsetX,offsetY);
      return coord * _UniqueShadowMapSize.xy;
   }
   //Groupweight
   static float4 GetTent3GroupWeights(float4 weightsX,float4 weightsY){
      float4 tapWeights;
      tapWeights.x = dot(weightsX.xyxy,weightsY.xxyy);
      tapWeights.y = dot(weightsX.zwzw,weightsY.xxyy);
      tapWeights.z = dot(weightsX.xyxy,weightsY.zzww);
      tapWeights.w = dot(weightsX.zwzw,weightsY.zzww);
      return tapWeights / dot(tapWeights,1);
   }
   static void GetTent5GroupWeights(
   float4 weightsXA,float2 weightsXB,
   float4 weightsYA,float2 weightsYB,
   out float3 groupWeightsA,out float3 groupWeightsB,out float3 groupWeightsC){
      
      groupWeightsA.x = dot(weightsXA.xyxy,weightsYA.xxyy);
      groupWeightsA.y = dot(weightsXA.zwzw,weightsYA.xxyy);
      groupWeightsA.z = dot(weightsXB.xyxy,weightsYA.xxyy);

      groupWeightsB.x = dot(weightsXA.xyxy,weightsYA.zzww);
      groupWeightsB.y = dot(weightsXA.zwzw,weightsYA.zzww);
      groupWeightsB.z = dot(weightsXB.xyxy,weightsYA.zzww);

      groupWeightsC.x = dot(weightsXA.xyxy,weightsYB.xxyy);
      groupWeightsC.y = dot(weightsXA.zwzw,weightsYB.xxyy);
      groupWeightsC.z = dot(weightsXB.xyxy,weightsYB.xxyy);
      float w = dot(groupWeightsA,1) + dot(groupWeightsB,1) + dot(groupWeightsC,1);
      float iw = rcp(w);
      groupWeightsA *= iw;
      groupWeightsB *= iw;
      groupWeightsC *= iw;
   }
   //weight
   static void GetTent3Weights(float2 kernelOffset,out float4 weightsX,out float4 weightsY){
      float2 a = 0.5 - kernelOffset;
      float2 b = 0.5 + kernelOffset;
      float2 c = max(0,-kernelOffset);
      float2 d = max(0,kernelOffset);
      float2 w1 = a * a * 0.5;
      float2 w2 = (1 + a) * (1 + a) * 0.5 -  w1 - c * c;
      float2 w4 = b * b * 0.5;
      float2 w3 = (1 + b) * (1 + b) * 0.5 -  w4 - d * d;
      weightsX = float4(w1.x,w2.x,w3.x,w4.x);
      weightsY = float4(w1.y,w2.y,w3.y,w4.y);
   }

   static void GetTent5Weights(float kernelOffset,out float4 weightsA,out float2 weightsB){
      float a = 0.5 - kernelOffset;
      float b = 0.5 + kernelOffset;
      float c = max(0,-kernelOffset);
      float d = max(0,kernelOffset);
      float w1 = a * a * 0.5;
      float w2 = (2 * a + 1) * 0.5;
      float w3 = (2 + a) * (2 + a) * 0.5 - w1 - w2 - c * c;

      float w6 = b * b * 0.5;
      float w5 = (2 * b + 1) * 0.5;
      float w4 = (2 + b) * (2 + b) * 0.5 - w5 - w6 - d * d;

      weightsA = float4(w1,w2,w3,w4);
      weightsB = float2(w5,w6);
   }

   //sample
   float SampleShadowPCF3x3_NoSupportShadow(float3 coord)
   {
      float2 base_uv = coord.xy;
      float2 ts = _UniqueShadowMapSize.xy*_SoftShadow;
      float shadow = 0;
      shadow += SampleShadowMap(coord+ float3(0, -ts.y,0));//UNITY_SAMPLE_SHADOW(_ShadowMapTexture, UnityCombineShadowcoordComponents(base_uv, float2(-ts.x, -ts.y), coord.z, receiverPlaneDepthBias));
      shadow += SampleShadowMap(coord+ float3(0, -ts.y,0));
      shadow +=SampleShadowMap(coord+ float3(ts.x, -ts.y,0));//, coord.z, receiverPlaneDepthBias));
      shadow += SampleShadowMap(coord+ float3(-ts.x, 0,0));
      shadow += SampleShadowMap(coord+ float3(0, 0,0));
      shadow +=SampleShadowMap(coord+ float3(ts.x, 0,0));
      shadow += SampleShadowMap(coord+ float3(ts.x, ts.y,0));
      shadow += SampleShadowMap(coord+ float3(0, ts.y,0));
      shadow +=SampleShadowMap(coord+ float3(ts.x, ts.y,0));

      return shadow/9;
   }
   float SampleShadowPCF3x3_4Tap(float3 uvd){
      //offset 就是一图元为单位的uv坐标
      float2 texelCoord = _UniqueShadowMapSize.zw * uvd.xy;
      //以图元为单位计算的可能坐标不是整数。这里取整
      float2 texelOriginal = round(texelCoord);
      //求得uv在某个像素的x。y偏移量
      float2 kernelOffset = texelCoord - texelOriginal;
      float4 weightsX,weightsY;
      //返回x轴和y轴的权重
      GetTent3Weights(kernelOffset,weightsX,weightsY);
      //左下
      float2 uv0 = GetGroupTapUV(texelOriginal + float2(-1,-1),weightsX.xy,weightsY.xy);
      //右下
      float2 uv1 = GetGroupTapUV(texelOriginal + float2(1,-1),weightsX.zw,weightsY.xy);
      //左上
      float2 uv2 = GetGroupTapUV(texelOriginal + float2(-1,1),weightsX.xy,weightsY.zw);
      //右上
      float2 uv3 = GetGroupTapUV(texelOriginal + float2(1,1),weightsX.zw,weightsY.zw);
      
      float4 weights = GetTent3GroupWeights(weightsX,weightsY);
      float4 tap4;
      #if SUPPORT_SHADOWMAP
         tap4.x =  UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv0,uvd.z));//(uv0,uvd.z);
         tap4.y = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv1,uvd.z));
         tap4.z = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv2,uvd.z));
         tap4.w =  UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv3,uvd.z));
      #endif
      return  dot(tap4,weights);
   }
   float SampleShadowPCF5x5_9Tap(float3 uvd){
      float2 texelCoord = _UniqueShadowMapSize.zw * uvd.xy;
      float2 texelOriginal = round(texelCoord);
      float2 kernelOffset = texelCoord - texelOriginal;

      float4 weightsXA,weightsYA;
      float2 weightsXB,weightsYB;

      GetTent5Weights(kernelOffset.x,weightsXA,weightsXB);
      GetTent5Weights(kernelOffset.y,weightsYA,weightsYB);

      float2 uv0 = GetGroupTapUV(texelOriginal + float2(-2,-2),weightsXA.xy,weightsYA.xy);
      float2 uv1 = GetGroupTapUV(texelOriginal + float2(0,-2),weightsXA.zw,weightsYA.xy);
      float2 uv2 = GetGroupTapUV(texelOriginal + float2(2,-2),weightsXB.xy,weightsYA.xy);

      float2 uv3 = GetGroupTapUV(texelOriginal + float2(-2,0),weightsXA.xy,weightsYA.zw);
      float2 uv4 = GetGroupTapUV(texelOriginal + float2(0,0),weightsXA.zw,weightsYA.zw);
      float2 uv5 = GetGroupTapUV(texelOriginal + float2(2,0),weightsXB.xy,weightsYA.zw);

      float2 uv6 = GetGroupTapUV(texelOriginal + float2(-2,2),weightsXA.xy,weightsYB.xy);
      float2 uv7 = GetGroupTapUV(texelOriginal + float2(0,2),weightsXA.zw,weightsYB.xy);
      float2 uv8 = GetGroupTapUV(texelOriginal + float2(2,2),weightsXB.xy,weightsYB.xy);

      float3 groupWeightsA,groupWeightsB,groupWeightsC;
      ///5x5的TentFilter，对应9个Group
      GetTent5GroupWeights(weightsXA,weightsXB,weightsYA,weightsYB,groupWeightsA,groupWeightsB,groupWeightsC);

      float3 tapA,tapB,tapC;
      float d = uvd.z;
      #if SUPPORT_SHADOWMAP
         tapA.x = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv0,d));
         tapA.y = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv1,d));
         tapA.z = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv2,d));

         tapB.x = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv3,d));
         tapB.y = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv4,d));
         tapB.z = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv5,d));

         tapC.x = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv6,d));
         tapC.y = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv7,d));
         tapC.z = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uv8,d));
      #endif
      
      return dot(tapA,groupWeightsA) + dot(tapB,groupWeightsB) + dot(tapC,groupWeightsC); 
   }
   float SampleShadowPCF3x3_Fast(float3 uvd)
   {
      float offsetX = _UniqueShadowMapSize.x * 0.5*_SoftShadow;
      float offsetY = _UniqueShadowMapSize.y * 0.5*_SoftShadow;
      float4 result;
      #if SUPPORT_SHADOWMAP
         result.x = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uvd.x - offsetX, uvd.y - offsetY, uvd.z));
         result.y = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uvd.x + offsetX, uvd.y - offsetY, uvd.z));
         result.z = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uvd.x - offsetX, uvd.y + offsetY, uvd.z));
         result.w = UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,float3(uvd.x + offsetX, uvd.y + offsetY, uvd.z));
      #endif
      return dot(result,0.25);
   }
   float SampleShaodowPoisson(float4 coord)
   {
      float shadow=0;
      for(int i=0;i<4;i++)
      {
         float4 uv=coord;
         uv.xy+=poisson4[i]*_SoftShadow;
         #if SUPPORT_SHADOWMAP
            shadow+= UNITY_SAMPLE_SHADOW(_UniqueShadowTexture,uv);
         #endif
      }
      return shadow*=0.25;
   }


   half4 UniqueShadowUVW(float4 vpos,float3 vnormal)
   {
      half4 positionWS= mul(unity_ObjectToWorld,vpos);
      half3 normalWS =normalize(mul((float3x3)unity_ObjectToWorld,vnormal));
      half3 lightDirection=normalize(_WorldSpaceLightPos0);
      float scale = 1-clamp(dot(normalWS,lightDirection),0,0.95);
      
      //vertexbias;
      positionWS.xyz += lightDirection *_BiasData.x*10*scale;
      //normal bias;
      positionWS.xyz += normalWS *_BiasData.y*scale;
      return positionWS;
   }

   float3 SampleUniqueShadow(float3 WorldPos)
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
      float3 shadow=float3(1,1,1);
      #if SUPPORT_SHADOWMAP
         shadow=SampleShadowPCF5x5_9Tap(coord);
      #else
         shadow=SampleShadowPCF3x3_NoSupportShadow(coord);
      #endif
      return  lerp(1,shadow,_UniqueShadowStrength);
   }
   
   #ifdef UNIQUESHADOW
      #define    SHADOW_COORDS(i) UNIQUE_SHADOW_COORDS(i)
      #define  TRANSFER_SHADOW(o) UNIQUE_SHADOW_TRANSFER(o)	
      #define   UNITY_LIGHT_ATTENUATION(destName, input, worldPos)\
      fixed destName = UNIQUE_SHADOW_ATTENUATION(input)
   #endif


   #define  UNIQUE_SHADOW_COORDS(i)                                   half4 _ShadowCoord : TEXCOORD##i ;
   #define UNIQUE_SHADOW_TRANSFER(o)			                        o._ShadowCoord=UniqueShadowUVW(v.vertex,v.normal);
   #define UNIQUE_SHADOW_ATTENUATION(i)                              SampleUniqueShadow(i._ShadowCoord);
   #define UNIQUE_SAMPLE_SHADOW                                      SampleShadowMap
   
   
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

