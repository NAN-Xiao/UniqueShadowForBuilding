#ifndef LIGHTFUCTION
    #define LIGHTFUCTION

    UNITY_DECLARE_TEX2DARRAY(custom_lightmaps);

    CBUFFER_START(customlights)
    int lightmapIndx;
    vector lightmapScaleAndOffset    
    CBUFFER_END
    float3 SamplerLightmaps(float uv)
    {
        float3 lightmapsampler=float3(uv,lightmapIndx);
        float3 color= UNITY_SAMPLE_TEX2DARRAY(custom_lightmaps,lightmapsampler).rgb;
        return color;
    }
#endif