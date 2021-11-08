
Shader "Faster/Particales/dissolve_blend" {
	Properties{
		_Diffuse("Diffuse", 2D) = "white" {}
		_Noise("Noise", 2D) = "white" {}
		_edge("0_勾边大小", Float) = 0.1
		_1_("1_勾边亮度", Float) = 100
		_2_diffuse("2_diffuse强度", Float) = 10
		_3_color("3_color", Color) = (0.8,0.3,0.1,1)
		_4_("4_扭曲强度", Range(0, 1)) = 0.2
		_V("V", Float) = 0
		_U("U", Float) = 0
		
	}
		SubShader{
			Tags {
				"IgnoreProjector" = "True"
				"Queue" = "Overlay"
				"RenderType" = "Transparent"
			}
			//   GrabPass{ }
			   Pass {
				   Name "FORWARD"
				   Tags {
					   "LightMode" = "ForwardBase"
				   }
				   Blend SrcAlpha OneMinusSrcAlpha
				   Cull Off
				   ZWrite Off

				   CGPROGRAM
				   #pragma vertex vert
				   #pragma fragment frag
				   #include "UnityCG.cginc"

				   struct VertexInput {
					   float4 vertex : POSITION;

					   float2 texcoord0 : TEXCOORD0;
					   float4 vertexColor : COLOR;
				   };
				   struct VertexOutput {
					   float4 pos : SV_POSITION;
					   float2 uv0 : TEXCOORD0;
					   float4 vertexColor : COLOR;

				   };

				   //     sampler2D _GrabTexture;
						sampler2D _Diffuse;   float4 _Diffuse_ST;
						sampler2D _Noise;   float4 _Noise_ST;
						float _edge;
						float _1_;
						float _2_diffuse;
						float4 _3_color;
						float _4_;
						float _V;
						float _U;

						float _Cutoff;
					  VertexOutput vert(VertexInput v) {
						  VertexOutput o = (VertexOutput)0;
						  o.uv0 = TRANSFORM_TEX(v.texcoord0, _Diffuse);
						  o.vertexColor = v.vertexColor ;

						  o.pos = UnityObjectToClipPos(v.vertex);

						  return o;
					  }
					  float4 frag(VertexOutput i) : COLOR
					  {
						  float2 uv0 = i.uv0 + _Time.y * float2(_U,_V);
						  float3 col = tex2D(_Diffuse, uv0).rgb;
						  float4 _mask = tex2D(_Noise, i.uv0);
						  //_4_溶解系数
						
						 float3 col2 = step(1 - _mask.r + (i.vertexColor.a), 1)- step( 1-_mask.r + (i.vertexColor.a), 1+_edge);
						 col2 *= col;
						 col2 *= _1_;
						  col2 += col* i.vertexColor.rgb;
						  clip(1-step(1 - _mask.r + (i.vertexColor), 1 + _edge)-0.2f);


						  return float4 (col2, 1);// i.vertexColor.a);


					  }
							ENDCG
						}
		}
			FallBack "Diffuse"
}
