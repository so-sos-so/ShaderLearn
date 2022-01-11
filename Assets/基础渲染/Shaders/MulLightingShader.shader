Shader "Custom/MulLightingShader"
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

            /**
             *每个顶点渲染一个光源意味着你可以在顶点程序中执行光照计算。
             *然后对所得颜色进行插值，并将其传递到片段程序。这非常廉价，
             *以至于Unity在base pass中都包含了这种灯光。
             *发生这种情况时，Unity会使用VERTEXLIGHT_ON关键字寻找base pass着色器变体。
             */
            // 仅点光源支持顶点光照。因此，定向灯和聚光灯不能使用。
            //要使用顶点光，我们必须在base pass中添加一个多编译语句。
            // 它只需要一个关键字VERTEXLIGHT_ON。另一个选择是根本没有关键字。为了表明这一点，我们使用_。
            #pragma multi_compile _ VERTEXLIGHT_ON

            #define FORWARD_BASE_PASS
            
            #include "MyLighting.cginc"
            ENDCG
        }
        
        Pass {
            // 将新的灯光模式设置为ForwardAdd。Unity将使用此通道来渲染其他光源。
            Tags{
                "LightMode" = "ForwardAdd"    
                }
            
            //新和旧像素数据的组合方式由两个因素决定。
            //新数据和旧数据乘以这些因素，然后相加就成为最终结果。
            //默认模式是不混合，等效于One Zero。
            //这样通过的结果将替换帧缓冲区中以前的任何内容。
            //要添加到帧缓冲区，我们必须指示它使用“ One One”混合模式。这称为additive blending。
            Blend One One
            ZWrite Off
            
            CGPROGRAM

            #pragma vertex vertex
            #pragma fragment fragment

            #pragma multi_compile_fwdadd

            #include "MyLighting.cginc"
            
            ENDCG
        }
    }
}
