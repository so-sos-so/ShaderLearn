using UnityEngine;

namespace _01_矩阵
{
    public class ScaleTransformation : Transformation
    {
        public Vector3 Scale = Vector3.one;
        public override Matrix4x4 Matrix
        {
            get
            {
                Matrix4x4 result = Matrix4x4.identity;
                result.m00 = Scale.x;
                result.m11 = Scale.y;
                result.m22 = Scale.z;
                return result;
            }
        }
    }
}