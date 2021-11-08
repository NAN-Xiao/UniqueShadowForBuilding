#ifndef SHAMBIENT
	#define SHAMBIENT
	
	
	#include "UnityCG.cginc"
	uniform float3 c0;
	uniform float3 c1;
	uniform	float3 c2;
	uniform float3 c3;
	uniform	float3 c4;
	uniform	float3 c5;
	uniform	float3 c6;
	uniform	float3 c7;
	uniform	float3 c8;
	
#define M_PI 3.14159265358
#define Y0(v) (1.0 / 2.0) * sqrt(1.0 / M_PI)
#define Y1(v) sqrt(3.0 / (4.0 * M_PI)) * v.y
#define Y2(v) sqrt(3.0 / (4.0 * M_PI)) * v.z
#define Y3(v) sqrt(3.0 / (4.0 * M_PI)) * v.x
#define Y4(v) 1.0 / 2.0 * sqrt(15.0 / M_PI) * v.x * v.y
#define Y5(v) 1.0 / 2.0 * sqrt(15.0 / M_PI) * v.z * v.y
#define Y6(v) 1.0 / 4.0 * sqrt(5.0 / M_PI) * (-1 + 3 * v.z * v.z)
#define Y7(v) 1.0 / 2.0 * sqrt(15.0 / M_PI) * v.z * v.x
#define Y8(v) 1.0 / 4.0 * sqrt(15.0 / M_PI) * (v.x * v.x - v.y * v.y)

	
	float3 AmbientSH(float3 v)
	{
	    v=normalize(v);
	    // half4 vb= v.xyzz*no
	    //float3 approx = c0 * Y0(v) + c1 * Y1(v) + c2 * Y2(v) + c3 * Y3(v) + c4 * Y4(v) + c5 * Y5(v) + c6 * Y6(v) + c7 * Y7(v) + c8 * Y8(v);
		float3 approx = c0 * Y0(v) + c1 * Y1(v) + c2 * Y2(v) + c3 * Y3(v) + c4 * Y4(v) + c5 * Y5(v) + c6 * Y6(v) + c7 * Y7(v) + c8 * Y8(v);
		return approx;//lerp(original, approx, _Mode);
	}
	
#endif