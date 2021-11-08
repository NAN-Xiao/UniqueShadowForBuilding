Shader "Faster/Particales/Add"
{
    Properties
    {
        _Color("Color",color)=(1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [Toggle(RECTCLIP)]_UseRectClip("UseRectClip",int)=0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100
        Blend SrcAlpha One
        zwrite off
        cull off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma shader_feature _ RECTCLIP

            #include "UnityCG.cginc"
            #include "Assets/Shaders/CgInc/UIClip.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 color : Color;
                float4 vertex : SV_POSITION;
                float3 pos:TEXCOORD1;

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color * _Color;
                o.pos=v.vertex;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv)*i.color;
                #ifdef RECTCLIP
                    col.a=RectClip(i.pos,col.a);
                #endif
                return col;
            }
            ENDCG
        }
    }
}
