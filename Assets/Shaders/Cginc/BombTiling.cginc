#ifndef BombTiling_CGINC
#define BombTiling_CGINC


sampler2D _noiseTex;
uniform float _BlendRatio;
float sum(float4 v)
{
	return v.x + v.y + v.z;
}
float4 hash4(float2 p)
{
	float t1 = 1.0 + dot(p, float2(37.0, 17.0));
	float t2 = 2.0 + dot(p, float2(11.0, 47.0));
	float t3 = 3.0 + dot(p, float2(41.0, 29.0));
	float t4 = 4.0 + dot(p, float2(23.0, 31.0));
	return frac(sin(float4(t1, t2, t3, t4)) * 103.0);
}
float4 BombTiling(sampler2D baseTex, sampler2D noiseTex, float2 uv)
{
	float k = tex2D(noiseTex, 0.005 * uv).x;
	float index = k * 8.0;
	float i = floor(index);
	float f = frac(index);
	float2 offa = sin(float2(3.0, 7.0) * (i + 0.0)) * _BlendRatio;
	float2 offb = sin(float2(3.0, 7.0) * (i + 1.0)) * _BlendRatio;
	float2 dx = ddx(uv);
	float2 dy = ddy(uv);
	float4 cola = tex2D(baseTex, uv + offa, dx, dy);
	float4 colb = tex2D(baseTex, uv + offb, dx, dy);
	return lerp(cola, colb, smoothstep(0.2, 0.8, f - 0.1 * sum(cola - colb)));
}

float4 BombTilingWithVoronoi(sampler2D tex, float2 uv) {
	float2 iuv = floor(uv);
	float2 fuv = frac(uv);
	float2 dx = ddx(uv);
	float2 dy = ddy(uv);
	float4 va = 0.0;
	float wt = 0.0;
	float blur = -(clamp(_BlendRatio, -0.5f, 1) + 0.5) * 30.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			float2 g = float2((float)i, (float)j);
			float4 o = hash4(iuv + g);
			float2 r = g - fuv + o.xy;
			float d = dot(r, r);
			float w = exp(blur * d);
			float4 c = tex2D(tex, uv + o.zw, dx, dy);
			va += w * c;
			wt += w;
		}
	}
	return va / wt;
}

#endif