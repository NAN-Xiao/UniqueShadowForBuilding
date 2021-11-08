Shader "Faster/Cartoon/Character"
{
  Properties
  {
    _Color("color",color)=(1,1,1,1)
    [Space]
    [Header(Map)]
    _MainTex ("Texture", 2D) = "white" {}
    _LineTex ("_LineTex", 2D) = "white" {}
    _DarkTex ("_DarkTex", 2D) = "white" {}
    [Space]
    [Header(Line)]
    _OutLineColor("OutLineColor",color)=(0,0,0,0)
    _OutLineWidth("_OutLineWidth",range(0,0.1))=0.1
    _InLineWidth("_InLineWidth",range(0.001,1))=0.1
    [Space]
    [Header(Speculer)]
    _SpeculerColor("_SpeculerColor",color)=(1,1,1,1)
    _SpeculerThreshold("_SpeculerThreshold",float)=1
    _SpeculerIntensity("_SpeculerIntensity",float)=1
    [Space]
    [Header(Shadow)]
    _ShadowThief("_ShadowThief",float)=1
    _ShadowThreshold("_ShadowThreshold",float)=1
    [Space]
    [Header(Fresnel)]
    _FresnelThief("_FresnelThief",float)=1
    _FresnelThreshold("_FresnelThreshold",float)=1
    _FresnelIntensity("_FresnelIntensity",float)=1
    [Space]
    [Header(Rim)]
    _RimThresThief("_RimThresThief",float)=1
    _RimThreshold("_RimThreshold",float)=1
    _RimIntensity("_RimIntensity",float)=1

    
  }
  SubShader
  {
    Tags { "RenderType"="Opaque" }
    LOD 100
    Pass
    {
      cull front
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      // make fog work
      #pragma multi_compile_fog
      #include "UnityCg.cginc"


      struct appdata
      {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        float4 normal : NORMAL;
        float4 color : COLOR;
      };

      struct v2f
      {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
        float3 worldnormal:TEXCOORD2;
        float3 worldPos:TEXCOORD3;
        float2 uv2 : TEXCOORD4;
      };

      sampler2D _MainTex,_LutTex,_LineTex,_DarkTex;
      float4 _MainTex_ST;
      float _OutLineWidth;
      float4 _Color,_OutLineColor;
      v2f vert (appdata v)
      {
        v2f o=(v2f)0;
        o.worldPos=mul(unity_ObjectToWorld,v.vertex);
        float3 ori=(float3)0;
        ori.x=unity_ObjectToWorld[0][3];
        ori.x=unity_ObjectToWorld[1][3];
        ori.x=unity_ObjectToWorld[2][3];
        float viewdis=distance(_WorldSpaceCameraPos,ori);///clamp(,1,0);
        float width=clamp(viewdis*viewdis,1,2)*_OutLineWidth;//clamp(-viewdis,11,0.1);
        o.vertex = UnityObjectToClipPos(v.vertex+normalize((v.color-0.5)*2)*width);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.worldnormal=mul(unity_ObjectToWorld,v.normal);
        o.worldPos=mul(unity_ObjectToWorld,v.vertex);
        return o;
      }

      fixed4 frag (v2f i) : SV_Target
      {
        return _OutLineColor;
      }
      ENDCG
    }
    Pass
    {
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      // make fog work
      #pragma multi_compile_fog
      #include "UnityCg.cginc"
      #include "Lighting.cginc"
      //  #include "AutoLight.cginc"

      struct appdata
      {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        float2 uv2 : TEXCOORD1;
        float4 normal : NORMAL;
        // float4 color:COLOR;
      };

      struct v2f
      {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
        float3 worldnormal:TEXCOORD2;
        float3 worldPos:TEXCOORD3;
        float2 uv2 : TEXCOORD4;
        // float4 color:COLOR;
      };

      sampler2D _MainTex,_LutTex,_LineTex,_DarkTex;
      float4 _MainTex_ST;
      float4 _Color;
      float _InLineWidth;
      float _SpeculerThreshold;
      float _SpeculerIntensity;
      float4 _SpeculerColor;
      float _ShadowThief;
      float _ShadowThreshold;
      
      float _FresnelThief;
      float _FresnelThreshold;
      float _FresnelIntensity;
      
      float _RimThresThief;
      float _RimThreshold;
      float _RimIntensity;

      v2f vert (appdata v)
      {
        v2f o=(v2f)0;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.uv2=v.uv2;
        o.worldnormal=mul((float3x3)unity_ObjectToWorld,v.normal);
        o.worldPos=mul(unity_ObjectToWorld,v.vertex);
        // o.color=v.color;
        return o;
      }

      fixed4 frag (v2f i) : SV_Target
      {
        
        float3 lightdir = normalize(_WorldSpaceLightPos0.xyz);
        float3 viewdir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
        float3 halfVector = normalize(lightdir + viewdir); 
        float3 normal=normalize(i.worldnormal);
        float ndl=max(0,dot(normal,lightdir));
        float ndh=max(0,dot(normal,halfVector));
        float ndv=max(0,dot(normal,viewdir));
        //colorbase
        float4 albdo = tex2D(_MainTex, i.uv);
        float3 DarkColor=tex2D(_DarkTex,i.uv);
        float4 LineColor=(tex2D(_LineTex,i.uv));
        float3 edge=1-ceil(LineColor.a-_InLineWidth);
        float3 shadow=smoothstep(_ShadowThief,_ShadowThreshold,ndl*(LineColor.g*0.5+0.5)-_ShadowThreshold);
        
        float3 rimlight=smoothstep(_RimThresThief,_RimThreshold,_RimThreshold-ndv)*_RimIntensity*DarkColor;

        float3 speclur=saturate(ceil(ndh-(1-LineColor.r*_SpeculerThreshold))*_SpeculerIntensity);
        float3 speclur2=saturate(ceil(ndh-(1-LineColor.g*_SpeculerThreshold))*_SpeculerIntensity);
        speclur*=speclur2;
        speclur*=albdo;
        speclur*=_SpeculerColor;

        float3 Fresnel=smoothstep(_FresnelThief,_FresnelThreshold,max(0,1-ndv)-_FresnelThreshold)*_FresnelIntensity;
        
        Fresnel*=albdo;
        float4 col;
        col.a=1;
        
        shadow+=Fresnel*shadow+rimlight;
        float3 diffuse=(albdo*(shadow*0.5+0.5));
        diffuse=shadow*albdo+ albdo*DarkColor*(1-shadow)*0.5+speclur;
        col.rgb= ((1-edge)+(edge*0.5)*DarkColor)*diffuse;
        return col;

      }
      ENDCG
    }
  }
  Fallback "Diffuse"
}
