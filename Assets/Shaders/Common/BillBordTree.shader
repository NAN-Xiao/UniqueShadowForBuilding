Shader "Faster/Common/BillboardTree" {
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        [Toggle(Lock)] Lock("Lock", int) = 0
        [Toggle(AlignScreen)] AlignScreen("AlignScreen", int) = 1
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent" "DisableBatching"="True"}
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ Lock AlignScreen
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            

            
            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color:COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert(a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                

                float4 outPos;
                
                #ifdef AlignScreen
                    float sx=UNITY_MATRIX_M[0][0];
                    float sy=UNITY_MATRIX_M[1][1];
                    float sz=UNITY_MATRIX_M[2][2];
                    float3x3 scale=float3x3(sx,0,0,0,sy,0,0,0,sz);
                    outPos= mul(UNITY_MATRIX_P, 
                    mul(UNITY_MATRIX_MV, float4(0.0, 0.0, 0.0, 1.0))
                    + float4(mul(scale,float3(v.vertex.x, v.vertex.y,  v.vertex.z)), 0.0));
                    o.color=float4(0,1,0,1);
                #endif
                #ifndef AlignScreen
                    float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                    float3 normal=normalize(viewer);
                    float3 up= abs(normal.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                    float3 right=normalize(cross(normal,up));
                    o.color=float4(1,0,0,1);
                    #ifndef Lock
                        up=normalize(cross(normal,right));
                        o.color=float4(0,0,1,1);
                    #endif
                    float3 worldPos=right*v.vertex.x+up*v.vertex.y+normal*v.vertex.z;
                    outPos= UnityObjectToClipPos(float4(worldPos,1));
                #endif
                o.pos=outPos;
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i); 
                fixed4 c = tex2D(_MainTex, i.uv);
                float4 val = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                c.rgb *= val.rgb;
                c.rgb*=i.color.rgb;
                return c;
            }
            
            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
