Shader "Faster/Particales/dissolve_blend" {
	Properties{
		_Diffuse("Diffuse", 2D) = "white" {}
		_Noise("Noise", 2D) = "white" {}
		_edge("0_勾边大小", float) = 0.1
		_1_("1_勾边亮度", float) = 100
		_2_diffuse("2_diffuse强度", float) = 10
		_3_color("3_color", Color) = (0.8,0.3,0.1,1)
		_4_("4_扭曲强度", Range(0, 1)) = 0.2
		_V("V", float) = 0
		_U("U", float) = 0
		
	}
	SubShader{
		Tags{"Queue"="Transparent"}
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		ZWrite Off
		Pass {
			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			struct VertexInput 
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
				half4 color : COLOR;
			};
			struct VertexOutput
			{
				half4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half4 color : COLOR;
			};
			sampler2D _Noise; 
			sampler2D _Diffuse; 
			CBUFFER_START(UnityPerMaterial)
			half4 _Diffuse_ST;
			half4 _Noise_ST;
			half _edge;
			half _1_;
			half _2_diffuse;
			half4 _3_color;
			half _4_;
			half _V;
			half _U;
			half _Cutoff;
			CBUFFER_END

			VertexOutput vert(VertexInput v) 
			{
				VertexOutput o = (VertexOutput)0;
				o.uv = TRANSFORM_TEX(v.uv, _Diffuse);
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.color = v.color ;
				return o;
			}
			half4 frag(VertexOutput i) : COLOR
			{
				half2 uv = i.uv * half2(_U,_V);
				half3 col = tex2D(_Diffuse, uv).rgb;
				// half4 _mask = tex2D(_Noise, i.uv0);
				// //_4_溶解系数
				// half3 col2 = step(1 - _mask.r + (i.color.a), 1)- step( 1-_mask.r + (i.color.a), 1+_edge);
				// col2 *= col;
				// col2 *= _1_;
				// col2 += col* i.color.rgb;
				// clip(1-step(1 - _mask.r + (i.color), 1 + _edge)-0.2f);
				return half4 (col.rgb, 1);
			}
			ENDHLSL
		}
	}
	FallBack "Diffuse"
}
