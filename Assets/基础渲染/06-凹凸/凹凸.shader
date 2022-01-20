Shader "Custom/凹凸"
{
    Properties
    {
        _Tint ("颜色", Color) = (1,1,1,1)
        _MainTex ("贴图", 2D) = "white" {}
        [NoScaleOffset] _NormalMap ("法线图", 2D) = "gray" {}
        _BumpScale ("Bump Scale", float) = 1
        _Smoothness ("光滑度", Range(0,1)) = 0.5
        [Gamma] _Metallic ("金属度", Range(0,1)) = 0
        _DetailTex ("细节贴图", 2D) = "gray" {}
        [NoScaleOffset] _DetailNormalMap ("细节法线贴图", 2D) = "bump" {}
        _DetailBumpScale ("Detail Bump Scale", float) = 1
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            // 可以在Inspector面板选择 Compile and Show Code 来查看编译的结果
            // 一般使用OpenGL 会更易懂
            #pragma vertex vertex
            #pragma fragment fragment
            #pragma target 3.0

            #pragma multi_compile _ VERTEXLIGHT_ON

            #include "MyLighting凹凸.cginc"
            ENDCG
        }

        // forward base pass用于主方向灯。要渲染额外的灯光，我们需要额外的pass。
        // 并将新的灯光模式设置为ForwardAdd。Unity将使用此通道来渲染其他光源。
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardAdd"
            }
            
            /**
             *但现在，我们看到的是辅助光，而不是主光。
             *Unity会同时渲染这两者，但是附加通道最终会覆盖基本通道的结果。
             *这显然是错的， 附加通道必须将其结果添加到基本通道中，而不是替换它。
             *我们可以通过更改附加通道的混合模式来指示GPU执行此操作。

                新和旧像素数据的组合方式由两个因素决定。
                新数据和旧数据乘以这些因素，然后相加就成为最终结果。
                默认模式是不混合，等效于One Zero。
                这样通过的结果将替换帧缓冲区中以前的任何内容。
                要添加到帧缓冲区，我们必须指示它使用“ One One”混合模式。这称为additive blending。
            
            Unity的动态批处理仅适用于最多受单个方向光影响的对象。激活第二盏灯使得该优化变得不可能了。
             */

            Blend One One
            
            // 因为它是针对同一对象的。因此，我们最终记录了完全相同的深度值 因此不需要两次写入深度缓冲区
            ZWrite Off

            CGPROGRAM
            // 可以在Inspector面板选择 Compile and Show Code 来查看编译的结果
            // 一般使用OpenGL 会更易懂
            #pragma vertex vertex
            #pragma fragment fragment
            #pragma target 3.0

            // 指定当前灯光是点光源，用于计算光照衰减
            // #define POINT

            // 如果要支持方向光和点光源，则需要使用变体
            /**
             *我们要为附加通道创建两个着色器变体。
             *一种用于定向光，另一种用于点光源。
             *为此，我们在pass的代码中添加了多编译的编译指示。
             *该语句定义关键字列表。Unity将为我们创建多个着色器变体，每个变体定义这些关键字之一。
             *每个变体都是单独的着色器。它们是单独编译的。它们之间的唯一区别是定义了哪些关键字。
                现在，我们需要DIRECTIONAL和POINT，并且不再需要自己定义POINT。
             */

            #pragma multi_compile_fwdadd
            // 上面相当于下面再增加两个cooike
            // #pragma multi_compile DIRECTIONAL POINT SPOT POINT_COOKIE DIRECTIONAL_COOKIE

            #include "MyLighting凹凸.cginc"
            ENDCG
        }
    }
    FallBack "Diffuse"
}