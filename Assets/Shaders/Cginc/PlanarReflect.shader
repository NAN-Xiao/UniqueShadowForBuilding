Shader "Hidden/PlanarReflect"
{

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        //平面反射
        Pass
        {
            Name "PlanarReflect"
            Blend srcalpha oneminussrcalpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
            };
            
            struct v2f
            {
                float4 screenPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _ReflectionTex;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_ReflectionTex, i.screenPos.xy / i.screenPos.w);
                
                //col.a=0.1;
                //或者
                //fixed4 col = tex2Dproj(_ReflectionTex, i.screenPos);
                return col;
            }
            ENDCG
        }
    }
}
