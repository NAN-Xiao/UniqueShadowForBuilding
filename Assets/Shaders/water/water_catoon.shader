Shader "Faster/Terrain/CartoonWater"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Albedo (RGB)", 2D) = "white" { }
        _WaterShallowColor("WaterShallowColor", Color) = (1, 1, 1, 1)   //深色
        _WaterDeepColor("WaterDeepColor", Color) = (1, 1, 1, 1)         //浅色
        _TranAmount("TranAmount", Range(0, 1)) = 0.5                    //透明度
        _DepthRanger("DepthRanger", float) = 1                          //深度范围
        _NormalTex("Normal", 2D) = "bump" { }                           //法线贴图
        _WaterSpeed("WaterSpeed", float) = 0.02                         //水流动速度
        _Refract("Refract", float) = 0.5                                //折射
        _Specular("Specular", float) = 1                                //高光
        _Gloss("Gloss", float) = 0.5                                    //高光范围
        _SpecularColor("SpeculaColor", Color) = (1, 1, 1, 1)                   //高光颜色
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        ZWrite Off
        LOD 200

        CGPROGRAM

        #pragma surface surf WaterLight vertex:vert alpha noshadow
        sampler2D_float _CameraDepthTexture;
        sampler2D _NormalTex;
        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _WaterShallowColor;
        fixed4 _WaterDeepColor;
        half _TranAmount;
        float _DepthRanger;
        half _WaterSpeed;
        float _Refract;
        half _Specular;
        fixed4 _SpecularColor;
        half _Gloss;
        struct Input
        {
            float2 uv_MainTex;
            float4 proj;
            float2 uv_NormalTex;
        };

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)
        fixed4 LightingWaterLight(SurfaceOutput s, fixed3 lightDir, half3 viewDir, fixed atten)
        {
            float diffuseFactor = max(0, dot(lightDir, s.Normal));
            half3 halfDir = normalize(lightDir + viewDir);
            float ndh = max(0, dot(halfDir, s.Normal));
            float specular = pow(ndh, s.Specular * 128) * s.Gloss;
            fixed4 c;
            c.rgb = (s.Albedo * _LightColor0.rgb * diffuseFactor + _SpecularColor.rgb * specular * _LightColor0.rgb) * atten;
            c.a = s.Alpha + specular * _SpecularColor.a;
            return c;
        }
        void vert(inout appdata_full v, out Input i)
        {
            UNITY_INITIALIZE_OUTPUT(Input, i);
            i.proj = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
            COMPUTE_EYEDEPTH(i.proj.z); 
        }
        void surf(Input IN, inout SurfaceOutput o)
        {
            float depth = tex2Dproj(_CameraDepthTexture, IN.proj).r;
            float linearEyeDepth = LinearEyeDepth(depth); 
            float deltaDepth = linearEyeDepth - IN.proj.z;   
            float4 bumpOffset1 = tex2D(_NormalTex, IN.uv_NormalTex + float2(_WaterSpeed * _Time.y, 0));
            float4 bumpOffset2 = tex2D(_NormalTex, float2(1 - IN.uv_NormalTex.y, IN.uv_NormalTex.x) + float2(_WaterSpeed * _Time.y, 0));  //翻转uv
            float4 offsetColor = (bumpOffset1 + bumpOffset2) * 0.5;
            float2 offset = UnpackNormal(offsetColor).xy * _Refract;
            float4 bumpColor1 = tex2D(_NormalTex, IN.uv_NormalTex + offset + float2(_WaterSpeed * _Time.y, 0));
            float4 bumpColor2 = tex2D(_NormalTex, float2(1 - IN.uv_NormalTex.y, IN.uv_NormalTex.x) + offset + float2(_WaterSpeed * _Time.y, 0));
            fixed4 c = lerp(_WaterShallowColor, _WaterDeepColor, min(_DepthRanger, deltaDepth) / _DepthRanger);

            o.Albedo = c.rgb;
            o.Normal = UnpackNormal((bumpColor1 + bumpColor2) * 0.5);
            o.Gloss = _Gloss;
            o.Specular = _Specular;
            o.Alpha = c.a * _TranAmount;
        }
        ENDCG

    }
    FallBack "Diffuse"
}