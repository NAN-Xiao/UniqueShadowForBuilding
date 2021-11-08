#ifndef UICLIP
    #define UICLIP
    #include "UnityCG.cginc"
    uniform float4 _MyClip;
    float RectClip(float3 pos, float a)
    {
        a*= step(_MyClip.x,pos.x);
        a*= step(pos.x,_MyClip.z);
        a*= step(pos.y,_MyClip.w);
        a*= step(_MyClip.y,pos.y);
        return a;
    }



#endif