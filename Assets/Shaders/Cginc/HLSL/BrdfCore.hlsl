#ifndef MMATH_CGINC
    #define MMATH_CGINC
    //  #include "UnityCG.cginc"

    #define _PI 3.1415
    float3 Diffuse_Lambert( float3 DiffuseColor )
    {
        return DiffuseColor * (1 / _PI);
    }

    float3 MPow5(float3 x) {
        return x * x * x * x * x;
    }

    //D
    float D__GGX(float roughness, float NoH) 
    {
        
        float a2=roughness*roughness;
        float d = (NoH * a2 - NoH) * NoH + 1;
        return a2 / (3.14159 * d * d + 0.000001);
    }

    half GGX_Mobile(half Roughness, float NoH)
    {
        // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
        float OneMinusNoHSqr = 1.0 - NoH * NoH; 
        half a = Roughness * Roughness;
        half n = NoH * a;
        half p = a / (OneMinusNoHSqr + n * n);
        half d = p * p;
        // clamp to avoid overlfow in a bright env
        return min(d, 2048.0);
    }
    float D_GGXaniso(float ax, float ay, float NoH, float3 H, float3 X, float3 Y)
    {
        float XoH = dot(X, H);
        float YoH = dot(Y, H);
        float d = XoH * XoH / (ax * ax) + YoH * YoH / (ay * ay) + NoH * NoH;
        return 1 / (3.14159 * ax * ay * d * d);
    }

    float warp(float x, float w) {
        return (x + w) / (1 + w);
    }
    //vis
    //ue4
    float Vis_SmithJointApprox( float roughness, float NoL,float NoV )
    {
        float a = sqrt(roughness);
        float Vis_SmithV = NoL * ( NoV * ( 1 - a ) + a );
        float Vis_SmithL = NoV * ( NoL * ( 1 - a ) + a );
        return 0.5 * rcp( Vis_SmithV + Vis_SmithL );
    }
    
    float Vis_Schlick( float a2, float NoV, float NoL )
    {
        float k = sqrt(a2) * 0.5;
        float Vis_SchlickV = NoV * (1 - k) + k;
        float Vis_SchlickL = NoL * (1 - k) + k;
        return 0.25 / ( Vis_SchlickV * Vis_SchlickL );
    }

    float Vis_Neumann( float NoV, float NoL )
    {
        return 1 / ( 4 * max( NoL, NoV ) );
    }

    // [Kelemen 2001, "A microfacet based coupled specular-matte brdf model with importance sampling"]
    float Vis_Kelemen( float VoH )
    {
        // constant to prevent NaN
        return rcp( 4 * VoH * VoH + 1e-5);
    }


    // Geometric Shadowing function 
    float G_SchlicksmithGGX(float roughness,float NoL, float NoV)
    {
        float r = (roughness + 1.0);
        float k = (r*r) / 8.0;
        float GL = NoL / (NoL * (1.0 - k) + k);
        float GV = NoV / (NoV * (1.0 - k) + k);
        return GL * GV;
    }
    //form ue4
    float3 Fresnel_schlick(float VoN, float3 rF0) {
        return rF0 + (1 - rF0) * MPow5(1 - VoN);
    }
    //from sbtancepaint
    float3 F_Schlick(float VoH , float3 SpecularColor )
    {
        float3 Fc = MPow5( 1 - VoH );					// 1 sub, 3 mul
        //return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad
        
        // Anything less than 2% is physically impossible and is instead considered to be shadowing
        return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
        
    }


    half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
    {
        // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
        // Adaptation to fit our G term.
        const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
        const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
        half4 r = Roughness * c0 + c1;
        half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
        half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;
        
        // Anything less than 2% is physically impossible and is instead considered to be shadowing
        // Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
        AB.y *= saturate( 50.0 * SpecularColor.g );
        
        return SpecularColor * AB.x + AB.y;
    }


    float3 EnvDFGLazarov( float3 specularColor, float gloss, float NoV )
    {
        float4 p0 = float4( 0.5745, 1.548, -0.02397, 1.301 );
        float4 p1 = float4( 0.5753, -0.2511, -0.02066, 0.4755 );
        float4 t = gloss * p0 + p1;
        float bias = saturate( t.x * min( t.y, exp2( -7.672 * NoV ) ) + t.z );
        float delta = saturate( t.w );
        float scale = delta - bias;
        bias *= saturate( 50.0 * specularColor.y );
        return specularColor * scale + bias;
    }


    //specularOcclusionCorrection form subtancepaint;
    //- Remove AO and shadows on glossy metallic surfaces (close to mirrors)
    float specularOcclusionCorrection(float diffuseOcclusion, float metallic, float roughness)
    {
        return lerp(diffuseOcclusion, 1.0, metallic * (1.0 - roughness) * (1.0 - roughness));
    }
    //copyform ue4
    float GetSpecularOcclusion(float NoV, float RoughnessSq, float AO)
    {
        return saturate( pow( NoV + AO, RoughnessSq ) - 1 + AO );
    }
    //sss
    struct FSphericalGaussian
    {
        float3 Amplitude;  // float3或者float皆可，按需求设定
        float3 Axis;
        float Sharpness;
    };

    float3 EvaluateSG( FSphericalGaussian sg,  float3 dir)
    {
        float cosAngle = dot(dir, sg.Axis);
        return sg.Amplitude * exp(sg.Sharpness * (cosAngle - 1.0f));
    }


    FSphericalGaussian MakeNormalizedSG(float3 LightDir, half Sharpness)
    {
        // 归一化的SG
        FSphericalGaussian SG;
        SG.Axis =LightDir; // 任意方向
        SG.Sharpness = Sharpness; // (1 / ScatterAmt.element)
        SG.Amplitude = SG.Sharpness / ((2 * _PI)  * (1-exp(-2 * SG.Sharpness))); // 归一化处理
        return SG;
    }

    
    float DotCosineLobe (FSphericalGaussian G,float3 N)
    {
        float mdn=dot(G.Axis,N);
        float c0=0.36;
        float cl=0.25/c0;
        float eml=exp(-G.Sharpness);
        float eml2=eml*eml;
        float rl=rcp(G.Sharpness);
        float scale=1.0+2.0*eml2-rl;
        float bias=(eml-eml2)*rl-eml2;
        float x=sqrt(1-scale);
        float x0=c0*mdn;
        float x1=cl*x;
        float n=x0+x1;
        float y =(abs(x0)<=x1)?n*n/x:saturate(mdn);
        return scale*y+bias;
    }

    float3 SGDiffuseLight(float3 N,float3 L,float3 H, half3 ScatterAmt)
    {
        FSphericalGaussian red=MakeNormalizedSG(L,1/max(0,ScatterAmt.x));
        FSphericalGaussian green=MakeNormalizedSG(L,1/max(0,ScatterAmt.y));
        FSphericalGaussian blue=MakeNormalizedSG(L,1/max(0,ScatterAmt.z));

        half3 diffuse= half3(DotCosineLobe(red,N),DotCosineLobe(blue,N),DotCosineLobe(blue,N));
        // half3 diffuse= half3(DotCosineLobe(red,N),0,0);

        //tone mapping
        half3 x=max(0,diffuse-0.04);
        diffuse+=(x*(6.2*x+0.5))/(x*(6.2*x+1.7)+0.06);
        return diffuse;
    }
#endif