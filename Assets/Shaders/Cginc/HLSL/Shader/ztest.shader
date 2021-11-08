Shader "Hidden/URPProcess/Ztest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {   
        Tags { "RenderPipeline" = "UniversalPipeline"}
        LOD 300
        Pass
        {
            ZWrite On
            ColorMask 0
        }
    }
}
