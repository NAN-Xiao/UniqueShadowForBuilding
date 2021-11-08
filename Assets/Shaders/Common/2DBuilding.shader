Shader "2DBuilding"
{
    Properties
    {
        _NightColor("_NightColor",color)=(1,1,1,1)
        _DustColor("_DustColor",color)=(1,1,1,1)
        
        _FlgColor("FlagColor",color)=(1,1,1,1)
        _UtilColor("_UtilColor",color)=(1,1,1,1)
        _LightColor("_LightColor",color)=(1,1,1,1)
        _SkyInten ("_SkyInten",range(0,1))=0
        _Lightinten ("_Lightinten",range(0,1))=0
        [Toggle]_flash("_Flash",int)=0
        _FlashSpeed("_FlashSpeed",float)=1
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex (" _Mask", 2D) = "white" {}


        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100

        Pass
        {
            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            // #pragma shader_feature _Flash_On
            #include "UnityCG.cginc"
            uniform sampler2D _DitherMaskLOD2D;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex,_MaskTex;
            float4 _MainTex_ST;
            float _Lightinten,_SkyInten,_flash,_FlashSpeed;
            float _LightMin;
            float4 _NightColor,_DustColor,_FlgColor,_UtilColor,_LightColor;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 mask = tex2D(_MaskTex, i.uv);


                col.a*=min(1,mask.r*2);
                col.rgb+=  _FlgColor*saturate(mask.r-0.5)*2;
                col.rgb=lerp( col.rgb, _UtilColor.rgb*mask.g*col.rgb*1.51,mask.g);
                float3 night=col.rgb*(_NightColor.rgb);
                float3 dust= col.rgb*(_DustColor.rgb);
                col.rgb=lerp(dust,col.rgb,max(0,_SkyInten-0.5)*2);
                col.rgb=lerp(night,col.rgb,max(0,_SkyInten*0.5)*2);
                
                float sinTimer=(sin(_Time.w*_FlashSpeed)*0.5+0.5)*2;
                _Lightinten+=(sinTimer+1)*0.6;
                col.rgb+=( _LightColor*mask.b*_Lightinten)*_flash;
                #ifdef LOD_FADE_CROSSFADE
                    float4 vpos=i.vertex;
                    vpos /= 4; // the dither mask texture is 4x4
                    vpos.y = frac(vpos.y) * 0.0625 /* 1/16 */ + unity_LODFade.y; // quantized lod fade by 16 levels
                    clip(tex2D(_DitherMaskLOD2D, vpos).a - 0.5);
                #endif

                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                
                return col;
            }
            ENDCG
        }
    }
}
