Shader "Custom/LightingShader"
{
    Properties
    {
        _Tint ("颜色", Color) = (1,1,1,1)
        _MainTex ("贴图", 2D) = "white" {}
        _Metallic ("金属度", Range(0,1)) = 0
        _Smoothness ("光滑度", Range(0,1)) = 0.5
    }
    
    SubShader
    {
        Pass
        {
            Tags{
                "LightMode" = "ForwardBase"    
            }
            
            CGPROGRAM

            // 可以在Inspector面板选择 Compile and Show Code 来查看编译的结果
            // 一般使用OpenGL 会更易懂
            #pragma vertex vertex
            #pragma fragment fragment
            
            #include "UnityStandardBRDF.cginc"

            fixed4 _Tint;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Smoothness;
            fixed4 _Metallic;

            struct VertexData
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };
            
            struct Interpolators
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };
            
            //SV代表系统值，POSITION代表最终顶点位置
            Interpolators vertex(VertexData data)
            {
                Interpolators result;
                result.uv = TRANSFORM_TEX(data.uv, _MainTex);
                //result.uv = data.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                result.position = mul(unity_MatrixMVP, data.position);
                result.normal = UnityObjectToWorldNormal(data.normal);
                result.worldPos = mul(unity_ObjectToWorld, data.position);
                return result;
            }

            //可以省略位置参数吗？
            //由于我们不使用它，因此我们最好将其省略。
            //但是，当涉及多个参数时，这会使某些着色器编译器感到困惑。
            //因此，最好将片段程序输入与顶点程序输出完全匹配起来。
            float4 fragment(Interpolators input) : SV_TARGET
            {
                input.normal = normalize(input.normal);
                float3 lightDir = _WorldSpaceLightPos0;
                fixed3 lightColor = _LightColor0;
                float3 albedo = tex2D(_MainTex, input.uv) * _Tint;
                float3 specularTint = albedo * _Metallic;
                float oneMinusReflectivity = 1 - _Metallic;
                albedo *= oneMinusReflectivity;

                float3 diffuse = albedo * lightColor * DotClamped(lightDir, input.normal);
                
                float3 viewDir = normalize(_WorldSpaceCameraPos - input.worldPos);
                float3 reflectionDir = reflect(-lightDir, input.normal);
                reflectionDir = normalize(lightDir + viewDir);
                return pow(DotClamped(input.normal, reflectionDir), _Smoothness * 100);
                return float4(DotClamped(lightDir, input.normal) * lightColor * albedo,1);
            }
            
            ENDCG
        }    
    }
}
