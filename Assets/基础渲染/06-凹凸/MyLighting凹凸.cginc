// 防止重复include此文件
#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

fixed4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST;
float _Smoothness;
float _Metallic;
sampler2D _NormalMap;
float _BumpScale;
sampler2D _DetailTex;
float4 _DetailTex_ST;
sampler2D _DetailNormalMap;
float _DetailBumpScale;
// float4(1 / width, 1 / height, width, height)
// float4 _HeightMap_TexelSize;

struct VertexData
{
    float4 position : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};

struct Interpolators
{
    float4 position : SV_POSITION;
    float4 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    #if defined(VERTEXLIGHT_ON)
     float3 vertexLightColor : TEXCOORD3;
    #endif
    float4 tangent : TEXCOORD4;
};

void ComputeVertexLightColor (inout Interpolators i)
{
    #if defined(VERTEXLIGHT_ON)
    // float3 lightPos = float3(unity_4LightPosX0.x,unity_4LightPosY0.x,unity_4LightPosZ0.x);
    // float3 lightVec = lightPos - i.worldPos;
    // float3 lightDir = normalize(lightVec);
    // float ndotl = DotClamped(i.normal, lightDir);
    // float attenuation = 1 / (1 + dot(lightVec, lightVec)) * unity_4LightAtten0;
    // i.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;
    // 等效于下面的
    i.vertexLightColor = Shade4PointLights(
            unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
            unity_LightColor[0].rgb, unity_LightColor[1].rgb,
            unity_LightColor[2].rgb, unity_LightColor[3].rgb,
            unity_4LightAtten0, i.worldPos, i.normal
        );
    #endif
}

//SV代表系统值，POSITION代表最终顶点位置
Interpolators vertex(VertexData data)
{
    Interpolators result;
    result.uv.xy = TRANSFORM_TEX(data.uv, _MainTex);
    result.uv.zw = TRANSFORM_TEX(data.uv, _DetailTex);
    result.position = mul(unity_MatrixMVP, data.position);
    result.worldPos = mul(unity_ObjectToWorld, data.position);
    result.tangent = float4(UnityObjectToWorldDir(data.tangent.xyz), data.tangent.w );
    /**
     https://app.yinxiang.com/shard/s13/nl/18256316/4240e3e0-98a1-446a-8f3d-dd0fb5d501d3/
     */
    // result.normal = mul(transpose(unity_WorldToObject), float4(data.normal, 0));
    // result.normal = normalize(result.normal);
    result.normal = UnityObjectToWorldNormal(data.normal);
    ComputeVertexLightColor(result);
    return result;
}

UnityLight CreateLight (Interpolators i)
{
    UnityLight light;
    // 加个宏判断是点还是方向光
    #if defined(POINT) || defined(SPOT) || defined(POINT_COOKIE)
    /**
     *_WorldSpaceLightPos0变量包含当前灯光的位置。但是在定向光的情况下，它实际上只保持了定向光的方向。
     *现在，我们使用了点光源，该变量只包含其名称所表示的位置数据。
     *因此，我们必须自己计算光的方向。通过减去片段的世界位置并将结果归一化化来完成位置计算。
     */
    float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
    light.dir = normalize(lightVec);
    #else
    light.dir = _WorldSpaceLightPos0.xyz;
    #endif
    // 衰减 根据球的表面积为 4πr² ，忽略常数，则衰减与 r²成反比
    // 加1是为了在距离为0的时候，最大值是1
    // float attenuation = 1 / (dot(lightVec, lightVec) + 1);
    // AutoLight.cginc中的UNITY_LIGHT_ATTENUATION可以帮助计算衰减
    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);
    return light;
}

UnityIndirect CreateIndirectLight (Interpolators i)
{
    UnityIndirect indirect;
    indirect.diffuse = 0;
    indirect.specular = 0;
    #if defined(VERTEXLIGHT_ON)
    indirect.diffuse = i.vertexLightColor;
    #endif
    return indirect;
}

void InitFragmentNormal(inout Interpolators i)
{
    float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
    float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
    float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);
    tangentSpaceNormal = tangentSpaceNormal.xzy;
    float3 binormal = cross(i.normal, i.tangent.xyz) * i.tangent.w * unity_WorldTransformParams.w;
    
    i.normal = normalize(
        tangentSpaceNormal.x * i.tangent +
        tangentSpaceNormal.y * i.normal +
        tangentSpaceNormal.z * binormal
    );
}

float4 fragment(Interpolators i) : SV_TARGET
{
    /**
     *在顶点程序中生成正确的法线后，它们将通过插值器传递。
     *不过，由于不同单位长度向量之间的线性内插不会产生另一个单位长度向量。它会更短。
     *尽管这会产生更好的结果，但其实不做的话，误差通常也很小。
     *如果你更重视性能，则可以不对片段着色器进行重新归一化。这是针对移动设备的比较常见优化。
     */
    InitFragmentNormal(i);
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    // float3 reflectionDir = reflect(-lightDir, i.normal);
    // return pow(DotClamped(reflectionDir, viewDir), _Smoothness * 100);

    float3 aldebo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;

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
    aldebo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;

    // float3 halfVector = normalize(viewDir + lightDir);
    // float3 specular = specularTint * lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 100);
    //
    // float3 diffuse = aldebo * DotClamped(lightDir , i.normal) * lightColor;
    // return float4(diffuse + specular , 1);
    // 上述可以直接使用brdf

    return UNITY_BRDF_PBS(aldebo, specularTint, oneMinusReflectivity, _Smoothness, i.normal, viewDir, CreateLight(i), CreateIndirectLight(i));
}
#endif