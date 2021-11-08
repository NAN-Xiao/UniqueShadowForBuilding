Shader "Faster/Terrain/terrain_Mix"
{
	Properties
	{
		_texture0("Texture0", 2D) = "white" {}
		_texture1("Texture1", 2D) = "white" {}
		_texture2("Texture2", 2D) = "white" {}
		_texture3("Texture3", 2D) = "white" {}
		_mixer("mixer", 2D) = "white" {}
		_BlendRatio("_BlendRatio",float) = 1
		[Toggle]_useTex("usetex",int) = 0
		_noiseTex("_noiseTex", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _USETEX_ON
			#pragma multi_compile_fog
			#include "UnityCG.cginc"
			#include "../CgInc/BombTiling.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1: TEXCOORD1;
				float2 uv2: TEXCOORD2;
				float2 uv3: TEXCOORD3;
				float2 uv4: TEXCOORD4;

			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1: TEXCOORD1;
				float2 uv2: TEXCOORD2;
				float2 uv3: TEXCOORD3;
				float2 uv4: TEXCOORD4;

			};

			sampler2D _texture0, _texture1, _texture2, _texture3, _mixer;
			float4 _texture0_ST, _texture1_ST, _texture2_ST, _texture3_ST, _mixer_ST;
			
			//float _BlendRatio;
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv0 = TRANSFORM_TEX(v.uv0, _texture0);
				o.uv1 = TRANSFORM_TEX(v.uv1, _texture1);
				o.uv2 = TRANSFORM_TEX(v.uv2, _texture2);
				o.uv3 = TRANSFORM_TEX(v.uv3, _texture3);
				o.uv4 = TRANSFORM_TEX(v.uv4, _mixer);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{


				#if _USETEX_ON
					fixed3 col0 = BombTiling(_texture0,_noiseTex, i.uv0).rgb;
					fixed3 col1 = BombTiling(_texture1,_noiseTex, i.uv1).rgb;
					fixed3 col2 = BombTiling(_texture2,_noiseTex, i.uv2).rgb;
					fixed3 col3 = BombTiling(_texture3, _noiseTex,i.uv3).rgb;
					fixed4 mix = BombTiling(_mixer,_noiseTex, i.uv4);
				#else
					fixed3 col0 = BombTilingWithVoronoi(_texture0, i.uv0).rgb;
					fixed3 col1 = BombTilingWithVoronoi(_texture1, i.uv1).rgb;
					fixed3 col2 = BombTilingWithVoronoi(_texture2,  i.uv2).rgb;
					fixed3 col3 = BombTilingWithVoronoi(_texture3, i.uv3).rgb;
					fixed4 mix = tex2D(_mixer,  i.uv4);
				#endif

				col0 *= 1 - mix.r;
				col1 *= mix.r;
				col0 += col1;

				col0 *= 1 - mix.g;
				col2 *= mix.g;
				col0 += col2;

				col0 *= 1 - mix.b;
				col3 *= mix.b;
				col0 += col3;
				return float4(col0,1);
			}
			ENDCG
		}
	}
}
