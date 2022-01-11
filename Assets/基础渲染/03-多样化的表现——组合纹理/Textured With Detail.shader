Shader "Custom/Textured With Detail"
{
    Properties
    {
        _Tint ("颜色", Color) = (1,1,1,1)
        _MainTex ("贴图", 2D) = "white" {}
        _DetailTex("细节贴图", 2D) = "gray" {}
    }
    
    SubShader
    {
        Pass
        {
            CGPROGRAM

            // 可以在Inspector面板选择 Compile and Show Code 来查看编译的结果
            // 一般使用OpenGL 会更易懂
            #pragma vertex vertex
            #pragma fragment fragment

            #include "UnityCG.cginc"

            fixed4 _Tint;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailTex;
            float4 _DetailTex_ST;

            struct VertexData
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct Interpolators
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uvDetail : TEXCOORD1;
            };
            
            //SV代表系统值，POSITION代表最终顶点位置
            Interpolators vertex(VertexData data)
            {
                Interpolators result;
                result.uv = TRANSFORM_TEX(data.uv, _MainTex);
                result.uvDetail = TRANSFORM_TEX(data.uv, _DetailTex);
                //result.uv = data.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                result.position = mul(unity_MatrixMVP, data.position);
                return result;
            }

            //可以省略位置参数吗？
            //由于我们不使用它，因此我们最好将其省略。
            //但是，当涉及多个参数时，这会使某些着色器编译器感到困惑。
            //因此，最好将片段程序输入与顶点程序输出完全匹配起来。
            float4 fragment(Interpolators input) : SV_TARGET
            {
                float4 color = tex2D(_MainTex, input.uv) * _Tint;
                color *=  tex2D(_DetailTex, input.uvDetail) * unity_ColorSpaceDouble;
                return color;
            }
            
            ENDCG
        }    
    }
}
