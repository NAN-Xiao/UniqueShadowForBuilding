Shader "Faster/Terrain/stencilmask"
{
    Properties
    {
      
        _Ref("refvalue",float)=1
        _Com("Compare",int)=1
        _stencilOperation("stencilOperation",int)=1
        _ZWrite("_ZWrite",int)=1
        _SrcBlend("_SrcBlend",int)=1
        _DstBlend("_DstBlend",int)=0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZWrite[_ZWrite]
        Blend [_SrcBlend] [_DstBlend]   
        Pass
        {
            Tags{"Queue"="Transparent" "LightMode" = "UniversalForward"}
            Stencil
            {
                Ref [_Ref]
                Comp [_Com]
                Pass [_stencilOperation]
            }            
            colormask 0
            cull front
        }
    }
}
