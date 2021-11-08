// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Faster/Terrain/Water"
{
	
	Properties
	{ 	_Color0("Water Color",Color) = (1,1,1,1)//水的颜色
		_Color1("depth Depth",Color) = (0,0,0,0)//水的深度的颜色
		_Color2("fresh Depth",Color) = (0,0,0,0)//水的深度的颜色
		_Alpha("Alpha",Range(0,1)) = 1//水面的正题透明度
		_Alpha2("Alpha",Range(0,1)) = 1//水面的正题透明度
		_ColorDepth("ColorDepth",Range(0,1)) = 0//水的深度
		_NormalTex("_NormalTex",2D)="white"{}
		_Noise("_NormalTex",2D)="white"{}
		_SpeedX("speedX",float)=1
		_SpeedY("speedY",float)=1

	}
	SubShader
	{
		Tags {"Queue" = "Transparent"}

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent:TANGENT;

			};

			struct VertexOutput
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float3 worldBinormal:TEXCOORD3;
				float3 worldTangent:TEXCOORD4;
				float3 worldPos : TEXCOORD5;
			};


			float4 _Color0;
			float4 _Color1;
			float4 _Color2;
			
			float _Alpha,_Alpha2;//水的透明度
			float _ColorDepth;
			float _SpeedX;
			float _SpeedY;
			sampler2D _CameraDepthTexture;
			sampler2D _NormalTex;
			sampler2D _Noise;
			float4 _NormalTex_ST;
			VertexOutput vert(appdata v)
			{
				VertexOutput o;
				float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;


				o.uv=TRANSFORM_TEX(v.uv,_NormalTex);

				o.worldNormal = normalize(worldNormal);
				o.worldTangent = normalize(worldTangent);
				o.worldBinormal = normalize(worldBinormal);
				o.worldPos=mul(unity_ObjectToWorld,v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.scrPos = ComputeScreenPos(o.pos );//将返回片段着色器的屏幕位置
				
				return o;
			}

			fixed4 frag(VertexOutput i) : COLOR
			{
				float2 speed=float2(_SpeedX,_SpeedY)*_Time.x;
				float3 normal=UnpackNormal(tex2D(_NormalTex,i.uv+speed));
				float3 normal2=UnpackNormal(tex2D(_NormalTex,1-i.uv+speed));
				normal+=normal2;
				normal=normalize(normal);
				float3x3 TBN=float3x3(normalize(i.worldTangent), normalize(i.worldBinormal), normalize(i.worldNormal));
				TBN = transpose(TBN);

				normal=mul(TBN,normal);
				float3 lightDir=normalize(_WorldSpaceLightPos0);
				float3 viewDir=normalize(_WorldSpaceCameraPos-i.worldPos.xyz);
				float3 h=normalize(viewDir+lightDir);

				float NoH=dot(normal,h);
				float a2=0.1;
				float d = (NoH * a2 - NoH) * NoH + 1;
				float D= a2 / (3.14159 * d * d + 0.000001);

				float dif=max(0,dot(lightDir,normal));
				float spec=max(0,dot(normal,h));
				half3 ambient_contrib =ShadeSHPerPixel(normal,0,i.worldPos);
				_Color0.rgb=_Color0.rgb+((dif+1)*0.2)+D*0.3;

				_Color0.rgb+=ambient_contrib;
				
				float  depth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).r;//UNITY_PROJ_COORD:深度值 [0,1]
				depth = LinearEyeDepth(depth);//深度根据相机的裁剪范围的值[0.3,1000],是将经过透视投影变换的深度值还原了
				depth -= i.scrPos.w;

				float alpha =saturate(_Alpha * depth);
				float alpha2=saturate(1-alpha)*normal.x;
				float alpha3=saturate(_Alpha2 * depth);

				half3 col;
				col.rgb = lerp(_Color1.rgb, _Color2.rgb, alpha3);
				_Color0.rgb*=col;
				_Color0.rgb+=saturate(alpha2*10);
				return float4(_Color0.rgb, alpha*_Alpha);
			}
			ENDCG
		}
	}
}