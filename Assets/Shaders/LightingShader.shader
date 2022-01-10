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
            
            #include "MyLighting.cginc"
            ENDCG
        }    
    }
}
