#ifndef LIGHTFUCTION
#define LIGHTFUCTION
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
half DiffuseLambert(half3 lightdir, half3 normal)
{

    half diff = max(0, dot(lightdir, normal));

    return diff;
    }

#endif