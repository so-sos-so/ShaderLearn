using UnityEngine;

namespace _01_矩阵
{
    public class CameraTransformation : Transformation
    {
        public float FocalLength;
        public override Matrix4x4 Matrix
        {
            get
            {
                Matrix4x4 result = Matrix4x4.identity;
                result.SetRow(0, new Vector4(FocalLength, 0, 0, 0));
                result.SetRow(1, new Vector4(0, FocalLength, 0, 0));
                result.SetRow(2, new Vector4(0, 0, 0, 0));
                result.SetRow(3, new Vector4(0, 0, 1, 0));
                return result;
            }
        }
    }
}