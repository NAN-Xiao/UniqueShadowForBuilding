#ifndef UNITQUESHADOW
    #pragma exclude_renderers d3d11 gles
    #define UNITQUESHADOW
    #include "UnityCG.cginc"
    
    
    static half2 poisson4[4] =
    {
        half2( -0.94201624, -0.39906216 ),
        half2( 0.94558609, -0.76890725 ),
        half2( -0.094184101, -0.92938870 ),
        half2( 0.34495938, 0.29387760 )
    };
    static half2 poisson8[8] =
    {
        { -0.7494944f, 0.1827986f, },
        { -0.8572887f, -0.4169083f, },
        { -0.1087135f, -0.05238153f, },
        { 0.1045462f, 0.9657645f, },
        { -0.0135659f, -0.698451f, },
        { -0.4942278f, 0.7898396f, },
        { 0.7970678f, -0.4682421f, },
        { 0.8084122f, 0.533884f },
    };
    
    
    static const float2 nvsf_Poisson32[] = 
    {
        { -0.975402, -0.0711386 },
        { -0.920347, -0.41142 },
        { -0.883908, 0.217872 },
        { -0.884518, 0.568041 },
        { -0.811945, 0.90521 },
        { -0.792474, -0.779962 },
        { -0.614856, 0.386578 },
        { -0.580859, -0.208777 },
        { -0.53795, 0.716666 },
        { -0.515427, 0.0899991 },
        { -0.454634, -0.707938 },
        { -0.420942, 0.991272 },
        { -0.261147, 0.588488 },
        { -0.211219, 0.114841 },
        { -0.146336, -0.259194 },
        { -0.139439, -0.888668 },
        { 0.0116886, 0.326395 },
        { 0.0380566, 0.625477 },
        { 0.0625935, -0.50853 },
        { 0.125584, 0.0469069 },
        { 0.169469, -0.997253 },
        { 0.320597, 0.291055 },
        { 0.359172, -0.633717 },
        { 0.435713, -0.250832 },
        { 0.507797, -0.916562 },
        { 0.545763, 0.730216 },
        { 0.56859, 0.11655 },
        { 0.743156, -0.505173 },
        { 0.736442, -0.189734 },
        { 0.843562, 0.357036 },
        { 0.865413, 0.763726 },
        { 0.872005, -0.927 },
    };
    
    sampler2D _UniqueShadowTexture;
    float _UniqueShadowFilterWidth;
    float4x4 _UniqueShadowMatrix;
    float _UniqueShadowStrength;
    float _UniqueShadowMapSize;
    float _ESMConst;

    float _VSMMin;

    inline float remapping(float shadow_factor, float minVal)
    {
        return saturate((shadow_factor - minVal) / (1.0 - minVal));
    }


    float  Chebyshev(float2 moments, float mean, float minVariance, float reduceLightBleeding)
    {
        float variance = moments.y - (moments.x * moments.x);
        variance = max(variance, minVariance);
        float d = mean - moments.x;

        float pMax = remapping(variance / (variance + (d * d)), reduceLightBleeding);

        #if UNITY_REVERSED_Z
            return mean > moments.x ? 1 : pMax;
            float p = step(moments.x, mean);
            return max(p, pMax);
        #else
            return mean <= moments.x ? 1 : pMax;
            float p = step(mean, moments.x);
            return max(p, pMax);
        #endif
    }



    float random(float3 seed, int i)
    {
        float4 seed4 = float4(seed,i);
        float dot_product = dot(seed4,float4(12.9898f,78.233f,45.164f,94.673f));
        return frac(sin(dot_product) * 43758.5453);
    }
    
    float4 TransformWorldToShadowCoord(float3 positionWS)
    {
        return mul(_UniqueShadowMatrix, float4(positionWS, 1.0));
    }


    float2 SampleVSMPreFilteredShadowmap(float worldpos)//(TEXTURE2D_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData)
    {
        float4 shadowCoord=TransformWorldToShadowCoord(worldpos);
        float depth = shadowCoord.z/shadowCoord.w;
        float2 moments =tex2D(_UniqueShadowTexture, shadowCoord).xy;

        return moments;
        float p = Chebyshev(moments, depth, 0.0001f, _VSMMin);//
        return p;
    }





    half UniqueShadowESM(half3 worldPos)
    {
        float4 shadowCoord=TransformWorldToShadowCoord(worldPos);
        // half shadow = 0.f;
        half shadow =( tex2D(_UniqueShadowTexture, shadowCoord)).r;

        #if UNITY_REVERSED_Z
            // e^(cz) * e^(-cd)//
            shadow = saturate(exp(_ESMConst * shadowCoord.z) * shadow);
            //shadow = saturate(exp(_ESMConst * shadowCoord.z - attenuation));
        #else
            // e^(-cz) * e^(cd)//
            shadow = saturate(exp(-_ESMConst * shadowCoord.z) * shadow);
            //shadow = saturate(exp(shadow - _ESMConst * shadowCoord.z));
        #endif

        return shadow;
    }
    
    half SampleUnique(half3 worldPos)
    {
        float4 shadowCoord=TransformWorldToShadowCoord(worldPos);
        // shadowCoord.xyz/shadowCoord.w;
        half4 uv = shadowCoord;
        half shadow = 0.f;
        
        
        for(int i = 0; i < 8; ++i) 
        {
            uv.xy = shadowCoord.xy + poisson8[i] * _UniqueShadowFilterWidth;
            shadow +=shadowCoord.z+0.002> DecodeFloatRGBA(tex2D(_UniqueShadowTexture, uv))? 1.0 : 0.0;
        }
        return lerp(1,shadow/8,_UniqueShadowStrength);;
        
    }


    float RotatedPoissonDisk(half3 worldPos)
    {
        float4 shadowCoord=TransformWorldToShadowCoord(worldPos);
        float shadow = 0.0;
        for(int i=0;i<4;i++)
        {
            float angle = 2.0f * UNITY_PI * random(floor(worldPos.xyz * 1000.0), i);
            float s = sin(angle);
            float c = cos(angle);
            float x=poisson8[i * 2] * c + poisson8[i * 2 + 1] * s;
            float y=poisson8[i * 2] *-s + poisson8[i * 2 + 1] * c;
            float2 rotatedOffset = float2(x,y);
            shadow +=shadowCoord.z+0.002> DecodeFloatRGBA(tex2D(_UniqueShadowTexture, shadowCoord + rotatedOffset*_UniqueShadowFilterWidth))? 1.0 : 0.0;
        }
        shadow *= 0.25;
        return lerp(1,shadow,_UniqueShadowStrength);
    }


#endif