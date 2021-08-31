Shader "Hidden/depthcopy"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    CGINCLUDE
    #include "UnityCG.cginc"
    
    
    sampler2D _MainTex;
    float4 _MainTex_ST;
    float4 _MainTex_TexelSize;

    float _ESMConst;
    float _BlurSize;
    struct appdata  
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };
    
    struct v2f_blur
    {
        float2 uv : TEXCOORD0;
        float4 uv01: TEXCOORD1;
        float4 uv23: TEXCOORD2;
        float4 vertex : SV_POSITION;
    };
    
    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
    }
    
    v2f_blur blurV(appdata v)
    {
        v2f_blur o;
        o.vertex = UnityObjectToClipPos(v.vertex.xyz);
        float2 uv = TRANSFORM_TEX(v.uv, _MainTex);
        float2 uvOffset = _MainTex_TexelSize.xy * 0.5;
        float2 blurOffet = 1 + _BlurSize;

        o.uv = uv;
        o.uv01.xy = uv - uvOffset * blurOffet;//top right
        o.uv01.zw = uv + uvOffset * blurOffet;//bottom left
        o.uv23.xy = uv - float2(uvOffset.x, -uvOffset.y) * blurOffet;//top left
        o.uv23.zw = uv + float2(uvOffset.x, -uvOffset.y) * blurOffet;//bottom right
        return o;
    }
    
    float4 blurF(v2f_blur i) : SV_Target
    {
        float4 sum = tex2D(_MainTex, i.uv) * 4;
        sum += tex2D(_MainTex, i.uv01.xy);
        sum += tex2D(_MainTex, i.uv01.zw);
        sum += tex2D(_MainTex, i.uv23.xy);
        sum += tex2D(_MainTex, i.uv23.zw);
        return sum * 0.125;
    }
    float4 frag_gaussian5x5(v2f i) : SV_Target
    {
        float4 o = 0;
        float g= tex2D(_MainTex, i.uv);
        const float gussianKernel[25] = {
            0.002969, 0.013306, 0.021938, 0.013306, 0.002969,
            0.013306, 0.059634, 0.098320, 0.059634, 0.013306,
            0.021938, 0.098320, 0.162103, 0.098320, 0.021938,
            0.013306, 0.059634, 0.098320, 0.059634, 0.013306,
            0.002969, 0.013306, 0.021938, 0.013306, 0.002969,
        };
        float2 blurOffset = 1 + _BlurSize;
        for (int x = -2; x <= 2; ++x) {
            for (int y = -2; y <= 2; ++y) {
                float weight = gussianKernel[x * 5 + y + 11];
                o += weight * tex2D(_MainTex, i.uv + float2(x, y) * _MainTex_TexelSize.xy * blurOffset);
            }
        }
        return o;//float4(o.r,g,0,0);
    }
    
    ENDCG
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        // pass 0 blur
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_gaussian5x5
            ENDCG
        }
        
        // Pass 1 VSM 
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            fixed4 frag (v2f i) : SV_Target
            {
                float d = tex2D(_MainTex, i.uv).r;
                #if UNITY_REVERSED_Z
                    float e = exp(-_ESMConst * d);
                #else
                    float e = exp(_ESMConst * d);
                #endif
               // return float4(e,0, 0, 0);
                return float4(d,d*d, 0, 0);
            }
            ENDCG
        }
        pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            fixed4 frag (v2f i) : SV_Target
            {
                float o = 0;
                float e= tex2D(_MainTex, i.uv).r;
                #if UNITY_REVERSED_Z
                    float g= exp(-_ESMConst * e);
                #else
                    float g = exp(_ESMConst * e);
                #endif



                const float gussianKernel[25] = {
                    0.002969, 0.013306, 0.021938, 0.013306, 0.002969,
                    0.013306, 0.059634, 0.098320, 0.059634, 0.013306,
                    0.021938, 0.098320, 0.162103, 0.098320, 0.021938,
                    0.013306, 0.059634, 0.098320, 0.059634, 0.013306,
                    0.002969, 0.013306, 0.021938, 0.013306, 0.002969,
                };
                float2 blurOffset = 1 + _BlurSize;
                for (int x = -2; x <= 2; ++x) {
                    for (int y = -2; y <= 2; ++y) {
                        float weight = gussianKernel[x * 5 + y + 11];
                        o += weight * tex2D(_MainTex, i.uv + float2(x, y) * _MainTex_TexelSize.xy * blurOffset).r;
                    }
                }
                return float4(o.r,g,0,0);
                
                
               // return float4(o,e, 0, 0);
            }
            ENDCG
        }
        
    }
}

