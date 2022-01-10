#if !defined(MY_LIGHTING_INCLUDED)

#define MY_LIGHTING_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

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
    #if defined(VERTEXLIGHT_ON)
        float3 vertexLightColor : TEXCOORD3;
    #endif
};

void ComputeVertexLightColor(inout Interpolators i)
{
    #if defined(VERTEXLIGHT_ON)
        i.vertexLightColor = Shade4PointLights(unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,
            unity_LightColor[0].rgb, unity_LightColor[1].rgb,
            unity_LightColor[2].rgb, unity_LightColor[3].rgb,
            unity_4LightAtten0, i.worldPos, i.normal);
    #endif
}

//SV代表系统值，POSITION代表最终顶点位置
Interpolators vertex(VertexData data)
{
    Interpolators result;
    result.uv = TRANSFORM_TEX(data.uv, _MainTex);
    //result.uv = data.uv * _MainTex_ST.xy + _MainTex_ST.zw;
    result.position = mul(unity_MatrixMVP, data.position);
    result.normal = UnityObjectToWorldNormal(data.normal);
    result.worldPos = mul(unity_ObjectToWorld, data.position);
    ComputeVertexLightColor(result);
    return result;
}

UnityLight CreateLight (Interpolators i)
{
    UnityLight light;
    // 点光源的方向
    #if defined(POINT) || defined(SPOT) || defined(POINT_COOKIE)
        light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
    #else
    light.dir = _WorldSpaceLightPos0.xyz;
    #endif
    // float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
    // 光的衰减 向量自己和自己点乘是指向量的长度 加1为了防止距离过进
    // float attenuation = 1 / (1 + dot(lightVec, lightVec));
    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos)
    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);
    return light;
}

UnityIndirect CreateIndirectLight(Interpolators i)
{
    UnityIndirect indirect;
    indirect.diffuse = 0;
    indirect.specular = 0;
    #if defined(VERTEXLIGHT_ON)
        indirect.diffuse = i.vertexLightColor;
    #endif
    /**
     *我们只能在base pass中执行此操作。
     *由于球谐函数与顶点光无关，因此我们不能依赖相同的关键字。
     *相反，我们将检查是否定义了FORWARD_BASE_PASS。
     */
    #if defined(FORWARD_BASE_PASS)
        indirect.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
    #endif
    return indirect;
}

//可以省略位置参数吗？
//由于我们不使用它，因此我们最好将其省略。
//但是，当涉及多个参数时，这会使某些着色器编译器感到困惑。
//因此，最好将片段程序输入与顶点程序输出完全匹配起来。
float4 fragment(Interpolators input) : SV_TARGET
{
    input.normal = normalize(input.normal);
    float3 viewDir = normalize(_WorldSpaceCameraPos - input.worldPos);
    float3 albedo = tex2D(_MainTex, input.uv) * _Tint;
    
    float3 specularTint;
    float oneMinusReflectivity;
    albedo *= DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusReflectivity);
    
    return UNITY_BRDF_PBS(albedo, specularTint, oneMinusReflectivity, _Smoothness,
        input.normal, viewDir, CreateLight(input), CreateIndirectLight(input));
    
}
#endif