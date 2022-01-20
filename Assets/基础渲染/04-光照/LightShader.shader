Shader "Custom/LightShader"
{
    Properties
    {
        _Tint ("颜色", Color) = (1,1,1,1)
        _MainTex ("贴图", 2D) = "white" {}
        _Smoothness ("光滑度", Range(0,1)) = 0.5
        _Metallic ("金属度", Range(0,1)) = 0
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
            
            //#include "UnityStandardBRDF.cginc"
            //#include "UnityStandardUtils.cginc"
            #include "UnityPBSLighting.cginc"

            fixed4 _Tint;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Smoothness;
            float _Metallic;

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
                result.position = mul(unity_MatrixMVP, data.position);
                result.worldPos = mul(unity_ObjectToWorld, data.position);
                /**
                 https://app.yinxiang.com/shard/s13/nl/18256316/4240e3e0-98a1-446a-8f3d-dd0fb5d501d3/
                 */
                // result.normal = mul(transpose(unity_WorldToObject), float4(data.normal, 0));
                // result.normal = normalize(result.normal);

                result.normal = UnityObjectToWorldNormal(data.normal);
                return result;
            }
            
            float4 fragment(Interpolators i) : SV_TARGET
            {
                /**
                 *在顶点程序中生成正确的法线后，它们将通过插值器传递。
                 *不过，由于不同单位长度向量之间的线性内插不会产生另一个单位长度向量。它会更短。
                 *尽管这会产生更好的结果，但其实不做的话，误差通常也很小。
                 *如果你更重视性能，则可以不对片段着色器进行重新归一化。这是针对移动设备的比较常见优化。
                 */
                i.normal = normalize(i.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                // float3 reflectionDir = reflect(-lightDir, i.normal);
                // return pow(DotClamped(reflectionDir, viewDir), _Smoothness * 100);

                float3 aldebo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
                
                // 能量守恒，根据高光的颜色减少aldebo的颜色
                // aldebo *= 1 - max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));
                // 下面是unity内置的能量守恒
                
                /**
                 *此功能将反照率和镜面反射颜色作为输入，并输出调整后的反照率。
                 *但是它还有第三个输出参数，称为一减反射率。这是减去镜面反射强度的乘积，
                 *是我们将反照率乘以的因子。这是额外的输出，因为其他照明计算也需要反射率。
                 */
                // aldebo = EnergyConservationBetweenDiffuseAndSpecular(aldebo, _SpecularTint.rgb, oneMinusReflectivity);
                
                float3 specularTint;
                float oneMinusReflectivity;
                aldebo = DiffuseAndSpecularFromMetallic(aldebo, _Metallic, specularTint, oneMinusReflectivity);
                
                // float3 halfVector = normalize(viewDir + lightDir);
                // float3 specular = specularTint * lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 100);
                //
                // float3 diffuse = aldebo * DotClamped(lightDir , i.normal) * lightColor;
                // return float4(diffuse + specular , 1);
                // 上述可以直接使用brdf

                UnityLight light;
                light.color = lightColor;
                light.dir = lightDir;
                light.ndotl = DotClamped(i.normal, lightDir);

                UnityIndirect indirect;
                indirect.diffuse = 0;
                indirect.specular = 0;
                
                return UNITY_BRDF_PBS(aldebo, specularTint, oneMinusReflectivity, _Smoothness, i.normal, viewDir, light, indirect);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}