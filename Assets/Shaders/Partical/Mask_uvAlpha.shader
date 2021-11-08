Shader "Faster/Particales/Mask_UVBlend" {
    Properties{
        [HDR] _Color("Color", Color) = (1,1,1,1)
        _Value("Value", Float) = 2

        _Texture("Texture", 2D) = "white" {}
        _SpeedX("SpeedX", Float) = 0
        _SpeedY("SpeedY", Float) = 0
        _Mask("Mask", 2D) = "white" {}
        _MaskX("MaskX", Float) = 0
        _MaskY("MaskY", Float) = 0
        [Toggle(RECTCLIP)]_UseRectClip("UseRectClip",int) = 0
            //	[HideInInspector]_ColorMask("Color Mask", Float) = 14
    }
        SubShader{
            Tags {
                "IgnoreProjector" = "True"
                "Queue" = "Transparent"
                "RenderType" = "Transparent"
            }
            Pass {
                Name "FORWARD"
                Tags {
                    "LightMode" = "ForwardBase"
                }
                     Blend SrcAlpha OneMinusSrcAlpha
                Cull Off
                ZWrite Off
            //	ColorMask[_ColorMask]

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma shader_feature _ RECTCLIP
                #include "UnityCG.cginc"
                #include "Assets/Shaders/CgInc/UIClip.cginc"

                struct VertexInput {
                    float4 vertex : POSITION;
                    float2 texcoord0 : TEXCOORD0;
                    float4 vertexColor : COLOR;
                };
                struct VertexOutput {
                    float4 pos : SV_POSITION;
                    float4 uv : TEXCOORD0;
                    float4 vertexColor : COLOR;
                    float4 mypos:TEXCOORD1;
                };

                  float4 _Color;
                  sampler2D _Texture;   float4 _Texture_ST;

                  float _SpeedX, _SpeedY;
                  sampler2D _Mask;   float4 _Mask_ST;
                  float _MaskX, _MaskY;


                VertexOutput vert(VertexInput v)
                {
                    VertexOutput o = (VertexOutput)0;
                    o.uv.xy = TRANSFORM_TEX(v.texcoord0, _Texture);
                    o.uv.zw = TRANSFORM_TEX(v.texcoord0, _Mask);

                    o.vertexColor = v.vertexColor * _Color;
                    o.mypos = v.vertex;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    return o;
                }
                float4 frag(VertexOutput i) : COLOR
                {
                    float2 speed = float2(_SpeedX,_SpeedY) * _Time.y + i.uv.xy;
                    float2 speed2 = float2(_MaskX, _MaskY) * _Time.y + i.uv.zw;

                    float4 col = tex2D(_Texture, speed);
                    float4 mask = tex2D(_Mask, speed2);
                    col.a *= mask.a;
#ifdef RECTCLIP
                    col.a = RectClip(i.mypos, col.a);
#endif
                    return col * i.vertexColor;
                }
                ENDCG
            }
        }
            FallBack "Diffuse"
}
