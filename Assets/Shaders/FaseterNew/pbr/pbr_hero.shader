
Shader "Faster/URP/PBR/Hero"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Tint("Tint", Color) = (1 ,1 ,1 ,1)
        _NormalMap("_NormalMap", 2D) = "white" {}
        [Gamma] _Metallic("Metallic", Range(0, 1)) = 0 //金属度要经过伽马校正
        _Smoothness("Smoothness", Range(0,1)) = 0.5
        _MetalTex("_MetalTex",2D) = "white" {}
        [HDR]_EmissionColor("_EmissionColor",color)=(1,1,1,1)
        _Channel("Channel",2D) = "black" {}
        _SkinColor0("_SkinColor0", Color) = (0 ,0 ,0 ,0)
        _SkinColor1("_SkinColor1", Color) = (0 ,0 ,0 ,0)
        _SkinColor2("_SkinColor2", Color) = (0 ,0 ,0 ,0)
        _SkinColorOffset("_SkinColorOffset",vector)=(1,1,1,1)
        _SpecularOcclusionLut3D("_s_SpecularOcclusionLut3D",2D) = "white" {}
        _OcclusionScale("__OcclusionScale",float)=1
        _X("X",float)=1
        _Y("Y",float)=1
        _specBoardLine("_specBoardLine",float)=1
        _LUT("LUT", 2D) = "white" {}
        [Toggle(USENORMAL)]_useNormalMap("_useNormalMap",float)=1
        [Toggle(Anisotropy)]_anisotropy("Anisotropy",float)=1 
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Name "ForwardBase"
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM


            #pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile __ USENORMAL
            #pragma multi_compile __ Anisotropy
            #pragma multi_compile_instancing
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Cginc/HLSL/BRDFCORE.hlsl"
            struct appdata
            {
                float3 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent:TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 shadowCoord:TEXCOORD2;//仅仅是阴影
                #ifndef USENORMAL
                    #ifdef Anisotropy
                        float3 worldNormal : TEXCOORD3;
                        float3 worldBinormal:TEXCOORD4;
                        float3 worldTangent:TEXCOORD5;
                    #else
                        float3 worldNormal : TEXCOORD3;
                    #endif
                #else 
                    float3 worldNormal : TEXCOORD3;
                    float3 worldBinormal:TEXCOORD4;
                    float3 worldTangent:TEXCOORD5;
                #endif
                float3 sh:TEXCOORD6;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _Tint;
            float _Metallic;
            float _Smoothness;
            float4 _EmissionColor;
            float _OcclusionScale;
            float4 _SkinColor0,_SkinColor1,_SkinColor2;
            float4 _SkinColorOffset;
            float4 _MainTex_ST;
            CBUFFER_END


            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURE2D(_MetalTex);
            SAMPLER(sampler_MetalTex);
            TEXTURE2D(_Channel);
            SAMPLER(sampler_Channel);


            
            
            

            

            float _X,_Y,_specBoardLine;
            v2f vert(appdata v) 
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex);
                o.worldPos = TransformObjectToWorld( v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
                float3 worldNormal = TransformObjectToWorldDir(v.normal.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                // o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                #ifndef USENORMAL
                    #ifdef Anisotropy
                        o.worldNormal = normalize(worldNormal);
                        o.worldTangent = normalize(worldTangent);
                        o.worldBinormal = normalize(worldBinormal);
                    #else
                        o.worldNormal = normalize(worldNormal);
                    #endif
                #else
                    o.worldNormal = normalize(worldNormal);
                    o.worldTangent = normalize(worldTangent);
                    o.worldBinormal = normalize(worldBinormal);
                #endif
                o.shadowCoord= TransformWorldToShadowCoord(o.worldPos);
                o.sh=SampleSHVertex(o.worldNormal);
                return o;
            }

            
            half4 frag(v2f i) : SV_Target
            {
                Light mainLight = GetMainLight(i.shadowCoord);
                half3 atten =  mainLight.shadowAttenuation;
                float3 lightDir = normalize(mainLight.direction);
                float3 viewDir = normalize(GetWorldSpaceViewDir(i.worldPos)).xyz;
                float3 lightColor = mainLight.color;
                float3 halfVector = normalize(lightDir + viewDir);  //半角向量

                float3 Albedo = _Tint.rgb * SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv).rgb;
                float4 Mallic=SAMPLE_TEXTURE2D(_MetalTex,sampler_MetalTex,i.uv);

                float4 channel=SAMPLE_TEXTURE2D(_Channel,sampler_MainTex,i.uv);
                

                float occlution=Mallic.b;
                _Metallic*=Mallic.g;
                _Smoothness*=Mallic.r;

                float _sss=channel.r;
                float _emission=channel.a;
                float3 normal;
                float3 binormal;
                
                
                #ifndef USENORMAL
                    #ifdef Anisotropy
                        normal =UnpackNormal( SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap, i.uv));
                        half3 wn;
                        float3x3 TBN=float3x3(normalize(i.worldTangent), normalize(i.worldBinormal), normalize(i.worldNormal));
                        TBN = transpose(TBN);
                        normal=mul(TBN,normal);
                    #else
                        normal=normalize(i.worldNormal);
                    #endif
                #else
                    normal =UnpackNormal( SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap, i.uv));
                    half3 wn;
                    float3x3 TBN=float3x3(normalize(i.worldTangent), normalize(i.worldBinormal), normalize(i.worldNormal));
                    TBN = transpose(TBN);
                    normal=mul(TBN,normal);
                #endif

                float perceptualRoughness = max(0.1, 1-_Smoothness);
                float roughness = perceptualRoughness*perceptualRoughness;
                float squareRoughness = roughness * roughness;




                float nl = max(saturate(dot(normal, lightDir)), 0.000001);//防止除0
                float nv = max(saturate(dot(normal, viewDir)), 0.000001);
                float vh = max(saturate(dot(viewDir, halfVector)), 0.000001);
                float lh = max(saturate(dot(lightDir, halfVector)), 0.000001);
                float nh = max(saturate(dot(normal, halfVector)), 0.000001);
                float3 F0 = lerp(0.04, Albedo, _Metallic);
                
                
                //  return float4(NDF,NDF,NDF,1);
                float3 skin0=lerp(Albedo,_SkinColor0.rbg,nv);
                float3 skin1=lerp(skin0,_SkinColor1.rbg,nl*1.2);
                float3 skin2=lerp(skin1,_SkinColor2.rbg,nl*1.5);
                //d_ggx copy from ue4
                float D = D__GGX(roughness,nh);
                #ifdef Anisotropy
                    half NDF0 = D_GGXaniso(_X, _Y, 1, normal, i.worldTangent, i.worldBinormal);
                    half NDF = D_GGXaniso(_X, _Y, nh, halfVector, i.worldTangent, i.worldBinormal) / NDF0;
                    half ndfs = (NDF - _specBoardLine);
                    D=lerp(D,ndfs,_sss);
                #endif
                
                // return float4(D,D,D,1);
                
                float G =Vis_Schlick(squareRoughness,nl,nv)*(4*nl*nv);//G_SchlicksmithGGX(squareRoughness,nl,nv);


                // return float4(G,G,G,1);
                float3 F= F_Schlick(vh,F0);
                float3 SpecularResult =(D * G * F )/(4*nv*nl);
                
                float3 kd = (1 - F)*(1 - _Metallic);
                //直接光照部分
                float3 light=lerp(nl*lightColor,(nl*0.3+0.7)+skin2,_sss);
                float3 specColor =SpecularResult *PI;
                float3 diffColor =  Albedo *kd;
                float3 DirectLightResult =( diffColor + specColor)*light;
                //   UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                DirectLightResult*=atten*occlution;
                //SSS form https://zhuanlan.zhihu.com/p/139836594?utm_source=wechat_timeline
                //  float3 ss=SGDiffuseLight(normal,lightDir,halfVector,_SkinColor.rgb);
                //环境光照 ibl部分
                half3 ambient_contrib =SampleSHPixel(i.sh,normal);
                float3 ambient = 0;//0.03 * Albedo;
                float3 iblDiffuse = max(half3(0, 0, 0), ambient.rgb + ambient_contrib);
                float mip_roughness = roughness * (1.7 - 0.7 * roughness);
                float3 reflectVec = reflect(-viewDir, normal);
                half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;
                half4 rgbm = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0,reflectVec, mip);
                float3 iblSpecular = DecodeHDREnvironment(rgbm, unity_SpecCube0_HDR);

                F=EnvBRDFApprox(F0,roughness,nv);
                float3 iblDiffuseResult = iblDiffuse * kd * Albedo;
                float3 iblSpecularResult = iblSpecular * F;
                float3 IndirectResult =(iblDiffuseResult+iblSpecularResult)*GetSpecularOcclusion(nv,squareRoughness,occlution);//;specularOcclusionCorrection(occlution*atten,_Metallic, 1-_Smoothness);
                float4 result = float4(DirectLightResult +IndirectResult, 1);
                result.rgb+=_emission*_EmissionColor.rgb;
                return result;
            }

            ENDHLSL
        }
        
    }
    Fallback "Universal Render Pipeline/Lit"
}