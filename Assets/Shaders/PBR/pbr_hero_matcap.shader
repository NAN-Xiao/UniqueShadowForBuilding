Shader "Faster/PBR/Hero(matcap)"
{
    Properties
    {
        _UniqueShadowTexture("Texture", 2D) = "white" {}
        _ShadowColor("_ShadowColor", Color) = (0,0,0,0)
        [Header(BRDF BASE)]
        [Space(10)]
        _Tint("Tint", Color) = (1 ,1 ,1 ,1)
        _MainTex("Texture", 2D) = "white" {}
        _BumpMap("_BumpMap", 2D) = "white" {}
        _CombMap("_CombMap", 2D) = "white" {}
        _MaskTex("Masktex",2D) = "white" {}
        [Gamma]_Metallic("Metallic", Range(0, 1)) = 0 //金属度要经过伽马校正
        _Smoothness("Smoothness", Range(0,1)) = 0.5
        _AmbientSHCoeff("AmbientSHCoeff",float)=1
        _OcclusionScale("__OcclusionScale",float)=1
        [Space(10)]
        
        
        [Header(Detail Channel)]
        [Space(10)]
        [HDR]_EmissionColor("_EmissionColor",color)=(1,1,1,1)
        _Channel("Channel",2D) = "black" {}
        _CuvratureOffset("_CuvratureOffset",float)=1
        _KelemenLUT("_KelemenLUT",2D) = "white" {}
        _ScatterLUT("_ScatterLUT",2D) = "white" {}
        _Dirt("ddd",vector)=(1,1,1,1)
        [Space(10)]
        [Header(Anisotropy)]
        [Space(10)]
        
        _X("X",float)=1
        _Y("Y",float)=1
        _specBoardLine("_specBoardLine",float)=1
        
        
        _EnvMap("EnvMap",2D)="black" {}
        _EnvIntensity("_EnvIntensity",float)=1
        //        _LUT("LUT", 2D) = "white" {}
        [Toggle(USENORMAL)]_useNormalMap("_useNormalMap",float)=1
        [Toggle(Anisotropy)]_anisotropy("Anisotropy",float)=1 
        [Toggle(UseSHLight)]_shlight("UseSHLight",float)=1 
        [Toggle(UseSSS)]sss("UseSSS",float)=1 
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags {
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM


            #pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile __ USENORMAL
            #pragma multi_compile __ Anisotropy
            #pragma multi_compile _ UseSHLight
            
            #pragma multi_compile _ UseSSS
            #pragma multi_compile _ SUPPORT_SHADOWMAP
            #pragma multi_compile _ UNIQUESHADOW

            #pragma multi_compile_fwdbase
            #include "UnityStandardUtils.cginc" 
            #include "UnityCg.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "Assets/Shaders/Cginc/BRDFCORE.cginc"
            #include "Assets/Shaders/Cginc/ShAmbient.cginc"
            #include "Assets/Shaders/Cginc/UniqueShaodw.cginc"
            
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent:TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                UNIQUE_SHADOW_COORDS(2)//仅仅是阴影
                #if defined(USENORMAL)|| defined(Anisotropy)
                    float3 worldNormal : TEXCOORD3;
                    float3 worldBinormal:TEXCOORD4;
                    float3 worldTangent:TEXCOORD5;
                #else
                    float3 worldNormal : TEXCOORD3;
                #endif
                float3 sh:TEXCOORD6;
                float3x3 rotation:TEXCOORD7;
            };

            float4 _Tint;
            float _Metallic;
            float _Smoothness;
            sampler2D _MainTex,_BumpMap,_MaskTex,_Channel,_SpecularOcclusionLut3D;
            sampler2D _CombMap;
            float4 _MainTex_ST;
            sampler2D _ScatterLUT;
            sampler2D _KelemenLUT; 
            sampler2D _EnvMap;
            float4 _EmissionColor;
            float _OcclusionScale;
            float _CuvratureOffset;
            float4 _ShadowColor;
            float _X,_Y,_specBoardLine;
            float _AmbientSHCoeff;
            float _EnvIntensity;
            float4 _Dirt;
            v2f vert(appdata v) 
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                #if defined (USENORMAL)||defined(Anisotropy) 
                    o.worldNormal = normalize(worldNormal);
                    o.worldTangent = normalize(worldTangent);
                    o.worldBinormal = normalize(worldBinormal);
                #else
                    o.worldNormal = normalize(worldNormal);
                #endif
                o.sh=v.vertex;
                TANGENT_SPACE_ROTATION;
                o.rotation=rotation;
                TRANSFER_SHADOW(o);//仅仅是阴影
                return o;
            }

            
            fixed4 frag(v2f i) : SV_Target
            {
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 lightColor = _LightColor0.rgb;
                float3 halfVector = normalize(lightDir + viewDir);  //半角向量

                float3 Albedo = tex2D(_MainTex, i.uv);
                float4 Mallic=tex2D(_MaskTex,i.uv);

                float3 channel=tex2D(_Channel,i.uv);
                

                float occlution=Mallic.b;
                _Metallic*=Mallic.r;
                
                _Smoothness*=Mallic.g;
                _Smoothness=clamp(_Smoothness,0,0.944);
                float _sss=channel.r;
                half scatter =channel.g;//QULV
                float _emission=channel.b;
                
                float3 normal;
                float3 binormal;
                

                #if defined (USENORMAL)
                    //just normal
                    normal =UnpackNormal( tex2D(_BumpMap, i.uv));
                    float3x3 TBN=float3x3(normalize(i.worldTangent), normalize(i.worldBinormal), normalize(i.worldNormal));
                    TBN = transpose(TBN);
                    normal=mul(TBN,normal);
                #else
                    normal=normalize(i.worldNormal);
                #endif
                float perceptualRoughness =1-_Smoothness;// max(0.04, );
                float roughness = perceptualRoughness*perceptualRoughness;
                float squareRoughness = roughness * roughness;




                float nl = max(saturate(dot(normal, lightDir)), 0.000001);//防止除0
                float nv = max(saturate(dot(normal, viewDir)), 0.000001);
                float vh = max(saturate(dot(viewDir, halfVector)), 0.000001);
                float lh = max(saturate(dot(lightDir, halfVector)), 0.000001);
                float nh = max(saturate(dot(normal, halfVector)), 0.000001);
                float3 F0 = lerp(unity_ColorSpaceDielectricSpec, Albedo, _Metallic);

                

                //d_ggx copy from ue4
                float D = D_GGX(roughness,nh);
                float G =Vis_Schlick(squareRoughness,nl,nv)*(4*nl*nv);
                float3 F= Fresnel_schlick(vh,F0);
                #ifdef Anisotropy
                    half NDF0 = D_GGXaniso(_X, _Y, 1, normal, i.worldTangent,  i.worldBinormal);
                    half NDF = D_GGXaniso(_X, _Y, nh, halfVector, i.worldTangent, i.worldBinormal);
                    half ndfs = (NDF * _specBoardLine);
                    D=ndfs;
                #endif
                
                
                float3 SpecularResult =(D * G * F )/(4*nl*nv);
                float3 kd = (1 - F)*(1 - _Metallic);
                //直接光照部分
                float3 light=nl*lightColor;
                float3 specColor =SpecularResult * UNITY_PI;
                float3 diffColor =  Albedo *kd;// UNITY_PI;
                float3 DirectLightResult = (diffColor + specColor)*light;
                
                
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                float shadow=atten;
                
                #ifdef UseSSS
                    
                    float lutU = dot(normal,lightDir)*0.5+0.5;
                    lutU*=shadow*0.5+0.5;
                    float lutV = scatter +_CuvratureOffset;
                    half3 skin = tex2D(_ScatterLUT,float2(lutU, lutV)).rgb;
                    float3 kelemen = tex2D(_KelemenLUT, float2(nh, perceptualRoughness));
                    float PH = pow(2.0 * kelemen, 10.0);
                    float base = 1.0 - vh;
                    float exponential = MPow5( base);
                    F= exponential + 0.028 * ( 1.0 - exponential );
                    specColor = max(PH * F / dot(halfVector, halfVector), 0);
                    float3 SkinLightResult=(skin+specColor)*(Albedo*kd);

                    DirectLightResult =lerp(DirectLightResult,SkinLightResult,_sss);
                    // float3 transLightDir=lightDir;
                    // //  float tickness=pow(_emission,5);
                    // float transDot=max(0,dot(transLightDir*(1-pow(_emission,2)),-viewDir));
                    // float3 translight=transDot*_Tint;
                    // DirectLightResult =lerp(DirectLightResult,SkinLightResult,_sss)+translight*(1-_emission);
                    
                #endif




                //环境光照
                half3 ambient_contrib =ShadeSHPerPixel(normal,0,i.worldPos);
                float3 ambient = 0;
                float3 iblDiffuse = max(half3(0, 0, 0), ambient.rgb + ambient_contrib);
                #ifdef UseSHLight
                    iblDiffuse+=( AmbientSH(normalize(normal))*UNITY_PI)*_AmbientSHCoeff;
                #endif
                //ibl部分用matcap
                float mip_roughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
                half mip = mip_roughness * 6;
                float3	worldNorm = mul((float3x3)UNITY_MATRIX_V, normal);
                float3 iblDiffuseResult = iblDiffuse *Albedo;
                float3 iblSpecularResult = tex2Dlod(_EnvMap,float4(worldNorm*0.5+0.5,mip))*_EnvIntensity;
                float Ao=GetSpecularOcclusion(nv,roughness,occlution);
                float3 IndirectResult =iblDiffuseResult+iblSpecularResult*Ao;
                float4 result = float4(DirectLightResult +IndirectResult, 1);
                result.rgb+=_emission*_EmissionColor;
                return result;
            }

            ENDCG
        }
        
        // Pass
        // {
            //     Tags { "LightMode" = "ForwardAdd" }
            //     Blend One One
            //     Fog { Color (0,0,0,0) }
            //     ZWrite Off
            //     ZTest LEqual

            //     CGPROGRAM

            

            //     #pragma target 3.0

            //     #pragma vertex vert
            //     #pragma fragment frag

            //     #pragma multi_compile __ USENORMAL
            //     #pragma multi_compile __ Anisotropy
            //     #pragma multi_compile _ UseSHLight
            //     #pragma multi_compile _ UNIQUESHADOW
            //     #pragma multi_compile _ UseSSS
            //     #pragma multi_compile pcf vsm
            //     #pragma multi_compile_fwdadd_fullshadows
            //     #pragma multi_compile_fwdbase
            //     #include "UnityStandardUtils.cginc" 
            //     #include "UnityCg.cginc"
            //     #include "Lighting.cginc"
            //     #include "AutoLight.cginc"
            //     #include "Assets/Shaders/Cginc/BRDFCORE.cginc"
            //     #include "Assets/Shaders/Cginc/ShAmbient.cginc"
            //     #include "Assets/Shaders/Cginc/UniqueShaodw.cginc"
            
            
            //     struct appdata
            //     {
                //         float4 vertex : POSITION;
                //         float3 normal : NORMAL;
                //         float4 tangent:TANGENT;
                //         float2 uv : TEXCOORD0;
            //     };

            //     struct v2f
            //     {
                //         float4 pos : SV_POSITION;
                //         float2 uv : TEXCOORD0;
                //         float3 worldPos : TEXCOORD1;
                //         SHADOW_COORDS(2)//仅仅是阴影
                //         #if defined(USENORMAL)|| defined(Anisotropy)
                //             float3 worldNormal : TEXCOORD3;
                //             float3 worldBinormal:TEXCOORD4;
                //             float3 worldTangent:TEXCOORD5;
                //         #else
                //             float3 worldNormal : TEXCOORD3;
                //         #endif
                //         float3 sh:TEXCOORD6;
                //         float3x3 rotation:TEXCOORD7;
            //     };

            //     float4 _Tint;
            //     float _Metallic;
            //     float _Smoothness;
            //     sampler2D _MainTex,_BumpMap,_MaskTex,_Channel,_SpecularOcclusionLut3D;
            //     sampler2D _CombMap;
            //     float4 _MainTex_ST;
            //     sampler2D _ScatterLUT;
            //    sampler2D _KelemenLUT;
            //     sampler2D _EnvMap;
            //     float4 _EmissionColor;
            //     float _OcclusionScale;
            //     float _CuvratureOffset;
            //     float4 _ShadowColor;
            //     float _X,_Y,_specBoardLine;
            //     float _AmbientSHCoeff;
            //     float _EnvIntensity;
            //     v2f vert(appdata v) 
            //     {
                //         v2f o;
                //         o.pos = UnityObjectToClipPos(v.vertex);
                //         o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                //         o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //         float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                //         float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                //         float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                //         #if defined (USENORMAL)||defined(Anisotropy) 
                //             o.worldNormal = normalize(worldNormal);
                //             o.worldTangent = normalize(worldTangent);
                //             o.worldBinormal = normalize(worldBinormal);
                //         #else
                //             o.worldNormal = normalize(worldNormal);
                //         #endif
                //         o.sh=v.vertex;
                //         TRANSFER_SHADOW(o);//仅仅是阴影
                //         TANGENT_SPACE_ROTATION;
                //         o.rotation=rotation;
                //         return o;
            //     }

            
            //     fixed4 frag(v2f i) : SV_Target
            //     {
                //         float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                //         float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                //         float3 lightColor = _LightColor0.rgb;
                //         float3 halfVector = normalize(lightDir + viewDir);  //半角向量

                //         float3 Albedo = _Tint * tex2D(_MainTex, i.uv);
                //         float4 Mallic=tex2D(_MaskTex,i.uv);

                //         float3 channel=tex2D(_Channel,i.uv);
                

                //         float occlution=Mallic.b;
                //         _Metallic*=Mallic.r;
                
                //         _Smoothness*=Mallic.g;
                //         _Smoothness=clamp(_Smoothness,0,0.944);
                //         float _sss=channel.r;
                //         half scatter =channel.g;//QULV
                //         float _emission=channel.b;
                
                //         float3 normal;
                //         float3 binormal;
                

                //         #if defined (USENORMAL)
                //             //just normal
                //             normal =UnpackNormal( tex2D(_BumpMap, i.uv));
                //             float3x3 TBN=float3x3(normalize(i.worldTangent), normalize(i.worldBinormal), normalize(i.worldNormal));
                //             TBN = transpose(TBN);
                //             normal=mul(TBN,normal);
                //         #else
                //             normal=normalize(i.worldNormal);
                //         #endif
                
                //         float perceptualRoughness =1-_Smoothness;// max(0.04, );
                //         float roughness = perceptualRoughness*perceptualRoughness;
                //         float squareRoughness = roughness * roughness;

                //         float nl = max(saturate(dot(normal, lightDir)), 0.000001);//防止除0
                //         float nv = max(saturate(dot(normal, viewDir)), 0.000001);
                //         float vh = max(saturate(dot(viewDir, halfVector)), 0.000001);
                //         float lh = max(saturate(dot(lightDir, halfVector)), 0.000001);
                //         float nh = max(saturate(dot(normal, halfVector)), 0.000001);
                //         float3 F0 = lerp(unity_ColorSpaceDielectricSpec, Albedo, _Metallic);

                

                //         //d_ggx copy from ue4
                //         float D = D_GGX(roughness,nh);
                //         float G =Vis_Schlick(squareRoughness,nl,nv)*(4*nl*nv);
                //         float3 F= Fresnel_schlick(vh,F0);
                //         #ifdef Anisotropy
                //             half NDF0 = D_GGXaniso(_X, _Y, 1, normal, i.worldTangent,  i.worldBinormal);
                //             half NDF = D_GGXaniso(_X, _Y, nh, halfVector, i.worldTangent, i.worldBinormal);
                //             half ndfs = (NDF * _specBoardLine);
                //             D=ndfs;
                //         #endif
                
                
                //         float3 SpecularResult =(D * G * F )/(4*nl*nv);
                //         float3 kd = (1 - F)*(1 - _Metallic);
                //         //直接光照部分
                //         float3 light=nl*lightColor;
                //         float3 specColor =SpecularResult * UNITY_PI;
                //         float3 diffColor =  Albedo *kd;// UNITY_PI;
                //         float3 DirectLightResult = (diffColor + specColor)*light;
                
                //         //shadow && unique shadow
                //         float shadowmap=1 ;
                //         #ifdef UNIQUESHADOW
                //             shadowmap=UniqueShadowPCF(i.worldPos);
                //             //return float4(shadow,shadow,shadow,1);
                //         #else
                //             UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                //             shadowmap=atten;
                //         #endif
                //         return float4(DirectLightResult,1);
            //     }

            //     ENDCG
        // }
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 3.5

            // -------------------------------------

            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }
    }
}