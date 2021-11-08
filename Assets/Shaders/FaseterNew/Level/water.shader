
Shader "Faster/URP/Level/Water"
{
	Properties
	{ 	_WaterColor("Water Color",Color) = (1,1,1,1)//水的颜色
		// _Rot("Rotation",float)=0
		_Color1("depth Depth",Color) = (0,0,0,0)//水的深度的颜色
		_Color2("fresh Depth",Color) = (0,0,0,0)//水的深度的颜色
		_Color3("form Depth",Color) = (0,0,0,0)//水的深度的颜色
		_Alpha("depth",Range(0,2)) = 1//水面的正题透明度
		_Alpha2("depthColor",Range(0,1)) = 1//水面的正题透明度
		_Alpha3("formdepth",Range(0,2)) = 1//水面的正题透明度
		_Alpha4("WaveRang",Range(0,2)) = 1//水面的正题透明度
		_NormalTex("NormalTex",2D)="white"{}
		_FoamTex("_FoamTex",2D)="white"{}
		_WaveTex("WaveTex",2D)="white"{}
		//_SkyBox("skybox",cube)= "white" {}
		_WaveSpeed("_WaveSpeed",vector)=(0,0,0,0)
		_LightDir("_LightDir",vector)=(0,0,0,0)
		_Roughness("Roughness",Range(0,1))=0
	}
	SubShader
	{
		Tags {"Queue"="Transparent" "RenderPipeline" = "UniversalPipeline"}
		LOD 300
		cull off
		Pass
		{
			Name "ForwardBase"
			Tags{"LightMode" = "UniversalForward"}

			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
			#include "Assets/Shaders/Cginc/HLSL/BRDFCORE.hlsl"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent:TANGENT;

			};

			struct VertexOutput
			{
				float4 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float4 projection : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float3 worldBinormal:TEXCOORD3;
				float3 worldTangent:TEXCOORD4;
				float3 worldPos : TEXCOORD5;
				float sh :TEXCOORD6;
				float2 uv2:TEXCOORD7;
			};

			
			CBUFFER_START(UnityPerMaterial)
			float4 _WaterColor;
			float4 _Color1;
			float4 _Color2;
			float4 _Color3;
			float _Alpha;
			float _Alpha2;
			float _Alpha3;
			float _Alpha4;
			float4 _WaveSpeed;
			float4 _NormalTex_ST;
			float4 _FoamTex_ST;
			float4 _WaveTex_ST;
			// float _Rot;
			float4 _LightDir;
			float _Roughness;
			CBUFFER_END

			
			TEXTURE2D(_NormalTex);
			SAMPLER(sampler_NormalTex);
			TEXTURE2D_X_FLOAT(_CameraDepthTexture);
			SAMPLER(sampler_CameraDepthTexture);


			TEXTURE2D(_FoamTex);
			SAMPLER(sampler_FoamTex);

			// TEXTURECUBE(_SkyBox);
			// SAMPLER(sampler_SkyBox);
			TEXTURE2D(_WaveTex);
			SAMPLER(sampler_WaveTex);

			VertexOutput vert(appdata v)
			{
				VertexOutput o;
				float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
				float3 worldNormal = TransformObjectToWorldDir(v.normal);
				float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;


				o.uv.xy=TRANSFORM_TEX(v.uv,_NormalTex);
				o.uv.zw=TRANSFORM_TEX(v.uv,_FoamTex);

				o.uv2=TRANSFORM_TEX(v.uv,_WaveTex);
				o.worldNormal = normalize(worldNormal);
				o.worldTangent = normalize(worldTangent);
				o.worldBinormal = normalize(worldBinormal);

				o.worldPos=TransformObjectToWorld(v.vertex.xyz);
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.projection = ComputeScreenPos(o.pos);
				o.sh=SampleSHVertex(o.worldNormal);
				return o;
			}

			half4 frag(VertexOutput i) : COLOR
			{

				// float sr=sin(_Rot);
				// float cr=cos(_Rot);
				// float2x2 m=float2x2(cr,-sr,sr,cr);
				// i.uv=mul(m,i.uv);

				float4 speed=_WaveSpeed*_Time.x;
				float4 normal1=(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv.xy+speed.xy));
				float4 normal2=(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,1-i.uv.xy+speed.zw));
				
				

				normal1+=normal2;
				normal1*=0.5;
				float3 normal=(UnpackNormal(normal1));
				

				float3 screenColor=SampleSceneColor((i.projection/i.projection.w).xyz+(normal.xyz*0.1));

				float3x3 TBN=float3x3(normalize(i.worldTangent), normalize(i.worldBinormal), normalize(i.worldNormal));
				TBN = transpose(TBN);
				normal=normalize(mul(TBN,normal));
				
				float3 lightDir=normalize(_LightDir.xyz);
				float3 lightColor=_MainLightColor.rgb;
				float3 viewDir=normalize(_WorldSpaceCameraPos-i.worldPos.xyz);
				float3 h=normalize(viewDir+lightDir);
				float NoH=max(0,dot(normal,h));
				float NoV=max(0,dot(normal,viewDir));
				float D=GGX_Mobile(_Roughness,NoH);
				half3 sh = SampleSHPixel(i.sh,normal);
				_WaterColor.rgb+=sh;
				//_WaterColor.rgb=_WaterColor.rgb*dif+spec*lightColor;
				float2 screenPos= i.projection.xy/ i.projection .w;
				float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
				float depthValue = LinearEyeDepth(depth, _ZBufferParams);
				depthValue-=i.projection.w;

				float alpha =saturate(depthValue/_Alpha );
				alpha*=alpha*alpha;
				float alpha2=saturate(_Alpha2*depthValue);
				
				float alpha3=saturate(depthValue/_Alpha3);

				//return float4(alpha3,alpha3,alpha3,1);
				float3 ref=reflect(-viewDir,normal);
				//	float3 sky =SAMPLE_TEXTURECUBE(_SkyBox,sampler_SkyBox,ref);
				
				float mip_roughness = _Roughness * (1.7 - 0.7 * _Roughness);
				half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;
				half3 rgbm = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0,ref, mip).rgb;
				half3 col;
				col.rgb = lerp(_Color1.rgb,_Color2.rgb, 1-alpha2);
				col.rgb+=rgbm;
				col.rgb+=screenColor*_WaterColor.a;
				col.rgb*=col;
				float timer=abs(frac(_Time.x*5));
				float4 foam=SAMPLE_TEXTURE2D(_FoamTex,sampler_FoamTex,(i.uv.zw+normal.yz*0.1));
				foam+=SAMPLE_TEXTURE2D(_FoamTex,sampler_FoamTex,(i.uv.zw+normal.xy*0.1));
				
				
				float3 wave=SAMPLE_TEXTURE2D(_WaveTex,sampler_WaveTex,i.uv2+float2(depthValue*_Alpha4+timer,0)+(normal.xy*0.2)).rgb;

				col.rgb+=D*lightColor;
				_WaterColor.rgb*=col.rgb;
				_WaterColor.rgb+=(foam*(1-alpha3)*_Color3*_Color3.a).rgb;
				wave*=max(0,1-depthValue);
				_WaterColor.rgb+=wave;
				return float4(_WaterColor.rgb,alpha*_WaterColor.a);
			}
			ENDHLSL
		}
	}
}