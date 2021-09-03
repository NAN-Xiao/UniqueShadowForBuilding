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
    
    
    static  float2 nvsf_Poisson32[] = 
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
        return saturate((shadow_factor - minVal) / (1.0f - minVal));
    }
    float random(float3 seed, int i)
    {
        float4 seed4 = float4(seed,i);
        float dot_product = dot(seed4,float4(12.9898f,78.233f,45.164f,94.673f));
        return frac(sin(dot_product) * 43758.5453);
    }
    float4 TransformWorldToShadowCoord(float3 worldPos)
    {
        return mul(_UniqueShadowMatrix, float4(worldPos, 1.0));
    }
    inline float Chebyshev(float2 moments, float mean)
    {
        float variance =max( moments.y - (moments.x * moments.x),0.0002);
        float d = mean - moments.x;
        float pMax = remapping(variance / (variance + (d * d)), _VSMMin);

        #if UNITY_REVERSED_Z
            //return mean > moments.x ? 1 : pMax;
            float p = step(moments.x, mean);
            return max(p, pMax);
        #else
            //return mean <= moments.x ? 1 : pMax;
            float p = step(mean, moments.x);
            return max(p, pMax);
        #endif
    }
    // From http://fabiensanglard.net/shadowmappingVSM/index.php
    float chebyshevUpperBound(float3 worldPos)
    {
        float4 shadowcoord=TransformWorldToShadowCoord(worldPos);
        float2 moments = tex2D(_UniqueShadowTexture,shadowcoord.xy).rg;
        
        // Surface is fully lit. as the current fragment is before the light occluder
        if( shadowcoord.z> moments.x) 
        {
            float p = ( shadowcoord.z <= moments.x);  
        }
        float variance = moments.y - (moments.x*moments.x);
        //variance = max(variance, 0.000002);
        variance = max(variance, 0.00002);

        float d = shadowcoord.z - moments.x;
        float p_max = variance / (variance - d*d);

        return max(p_max,shadowcoord.z);
    }

    //vsm
    float UniqueShadowVSMFilter(float3 worldpos)//(TEXTURE2D_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData)
    {
        float4 shadowCoord=TransformWorldToShadowCoord(worldpos);
        float2 shadow =( tex2D(_UniqueShadowTexture, shadowCoord)).rg;
        float p = Chebyshev(shadow,shadowCoord.z/shadowCoord.w);//
        return p;
    }
    //esm
    half UniqueShadowESMFilter(half3 worldPos)
    {
        float4 shadowCoord=TransformWorldToShadowCoord(worldPos);
        half shadow =( tex2D(_UniqueShadowTexture, shadowCoord)).r;
        #if UNITY_REVERSED_Z
            shadow = saturate(exp(_ESMConst * shadowCoord.z) * shadow);
        #else
            // e^(-cz) * e^(cd)
            shadow = saturate(exp(-_ESMConst * shadowCoord.z) * shadow);
        #endif
        return shadow;
    }
    ///new nvidia paper
    // float ChebyshevUpperBound(float2 moments, float distance)
    // {
        //     // One-tailed inequality valid
        
        //     // Compute variance
        //     float variance = moments.y - (moments.x*moments.x);
        //     variance = max(variance, _VSMMin);  
        //     // Compute probabilistic upper bound.
        //     float d =distance – moments.x;
        //     float p_max = variance / (variance + d*d);
        //     return max(p,p_max);
    // } 

    // float ShadowContribution(float3 worldPos)//float2 LightTexCoord, float DistanceToLight) 
    // {   
        //     float4 shadowCoord=TransformWorldToShadowCoord(worldPos);
        //     float2 Moments=tex2D(_UniqueShadowTexture, shadowCoord.xy).rg;
        //     // Read the moments from the variance shadow map.  
        //     // Compute the Chebyshev upper bound.   
        //     return ChebyshevUpperBound(Moments, shadowCoord.z/shadowCoord.w); 
    // } 
    ///new nvidia paper
    static const int kernelSampleCount = 16;
    static const float2 kernel[kernelSampleCount] = {
        float2(0, 0),
        float2(0.54545456, 0),
        float2(0.16855472, 0.5187581),
        float2(-0.44128203, 0.3206101),
        float2(-0.44128197, -0.3206102),
        float2(0.1685548, -0.5187581),
        float2(1, 0),
        float2(0.809017, 0.58778524),
        float2(0.30901697, 0.95105654),
        float2(-0.30901703, 0.9510565),
        float2(-0.80901706, 0.5877852),
        float2(-1, 0),
        float2(-0.80901694, -0.58778536),
        float2(-0.30901664, -0.9510566),
        float2(0.30901712, -0.9510565),
        float2(0.80901694, -0.5877853),
    };
    half UniqueShadowPCF(half3 worldPos)
    {
        half shadow = 0.f;
        float4 shadowCoord=TransformWorldToShadowCoord(worldPos);
        
        for (int x = 0; x < 4; x++)
        {
            for(int y=0;y<4;y++)
            {
                float2 uv=shadowCoord+float2(x,y)*0.5*_UniqueShadowFilterWidth;
                shadow +=shadowCoord.z+0.002> DecodeFloatRGBA(tex2D(_UniqueShadowTexture, uv))? 1.0 : 0.0;
            }
        }
        return shadow/4;//
    }
    //泊松分佈
    half UniqueShadowPoissonPCF(half3 worldPos)
    {
        float4 shadowCoord=TransformWorldToShadowCoord(worldPos);
        // shadowCoord.xyz/shadowCoord.w;
        half4 uv = shadowCoord;
        half shadow = 0.f;
        for(int i = 0; i < 32; ++i) 
        {
            uv.xy = shadowCoord.xy + nvsf_Poisson32[i] * (_UniqueShadowFilterWidth);
            shadow +=shadowCoord.z+0.002> DecodeFloatRGBA(tex2D(_UniqueShadowTexture, uv))? 1.0 : 0.0;
        }
        shadow/=32;
        return  lerp(1,shadow,_UniqueShadowStrength);
    }

    //旋轉泊松分佈
    float UniqueShadowPoissonPCFRotate(half3 worldPos)
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