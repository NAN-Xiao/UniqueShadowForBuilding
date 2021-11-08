Shader "Faster/Terrain/water_red"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_normalTexture("normalTexture", 2D) = "white" {}
		_gradientTexture("gradientTexture", 2D) = "white" {}
		_lightDir("lightDir",vector)=(1,1,1,1)
		
		_formColor("formColor",color)=(1,1,1,1)
		_specColor("specColor",color)=(1,1,1,1)

		_waveParams("waveParams1",vector) = (1,1,1,1)
		_formParams("formParams2",vector) = (1,1,1,1)
		_speedX("speedX",float)=0
		_speedY("speedY",float)=0
		_specular("specular",float)=0.5
		_gloss("gloss",float)=1
	}
	SubShader
	{
		Tags {"QUEUE"="Transparent"}
		LOD 100
		blend srcalpha oneminussrcalpha
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			//#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color:COLOR;
				float3 normal:NORMAL;
				float4 tangent : TANGENT;

				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float2 uv3 : TEXCOORD2;

				float4 vertex : SV_POSITION;
				float4 color:COLOR;

				float3 bitangent : TEXCOORD3;
				float3 normal : TEXCOORD4;
				float3 posWorld:TEXCOORD5;
				float3 tangent : TEXCOORD6;

			};

			sampler2D _MainTex,_normalTexture,_gradientTexture;
			float4 _MainTex_ST,_normalTexture_ST,_gradientTexture_ST;


			float _specular;
			float _gloss;
			float _speedX,_speedY;

			float4 _formParams;
			float4 _waveParams;
			float4 _lightDir;


			float4 _formColor;
			float4 _specColor;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _normalTexture);
				o.uv2 = TRANSFORM_TEX(v.uv, _gradientTexture);

				o.uv3= TRANSFORM_TEX(v.uv, _MainTex);


				o.color=v.color;
				o.normal = normalize(UnityObjectToWorldNormal(v.normal));
				o.tangent = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.bitangent = normalize(cross(o.normal, o.tangent) * v.tangent.w);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float4 color = i.color;

				float s1 = _Time.x * _speedX;
				float4 normalCol = (tex2D(_normalTexture, i.uv2 +  float2(s1, 0.0)) + tex2D(_normalTexture,  float2(s1 + i.uv.y, i.uv.x)))*0.5;
				normalCol+= tex2D(_normalTexture,  float2(s1 + i.uv2.y, i.uv2.x));
				float3 normal = UnpackNormal(normalCol*0.5);

				float2 formUV = i.uv + normal.xy * color.r * _waveParams.w;
				float3 form = tex2D(_MainTex, formUV).rgb;

				
				float3x3 tangentTransform = float3x3(i.tangent, i.bitangent, i.normal);
				normal = normalize(mul(normal, tangentTransform)); // Perturbed normals

				//normal = normalize(float3(dot(TW0.xyz, normal), dot(TW1.xyz, normal), dot(TW2.xyz, normal)));

				float4 col = tex2D(_gradientTexture,  float2(saturate(color.r), 0.5));

				float waveP1 = 1.0 - color.r + _waveParams.y;
				float waveP2 = _Time.x * _speedY + _waveParams.z * form.b;
				float waveAlpha = 1.0 - saturate((color.r - 0.4) * 3.33333333333);
				float waveCommonParam = (waveP1 + _waveParams.x * sin(waveP2)) * 15.70796326795;
				float waveAdd = waveAlpha <= 0.001 ? 0.0 : (cos(waveCommonParam) + sin(waveCommonParam)) * 0.5 + 1.0;

				float sfadein = 1.0 - saturate((_formParams.x - color.r) / _formParams.x);
				float sfadeout = 1.0 - saturate((color.r - _formParams.y) / _formParams.x);
				float4 colorOffset = _formColor - col;
				col += colorOffset * waveAdd * waveAlpha * form.r * color.b;
				col += colorOffset * sfadein * sfadeout * _formParams.w * form.g * color.g;

				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);;// normalize(float3(cc_cameraPos.xy, 350.0) - float3(TW0.w, TW1.w, TW2.w));

				float3 h = normalize(viewDirection - normalize(_lightDir.xyz));
				float ndh = max(0.0, dot(normal, h));

				col += saturate((color.r - 0.4) * 2.0) * _gloss * pow(ndh, _specular * 192.0) * _specColor;

				col.a *= color.a;
				return col;
				//return fixed4(cos(waveCommonParam), cos(waveCommonParam),cos(waveCommonParam),1);
			}
			ENDCG
		}
	}
}
