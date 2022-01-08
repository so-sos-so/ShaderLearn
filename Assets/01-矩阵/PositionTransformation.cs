using UnityEngine;

namespace _01_矩阵
{
    public class PositionTransformation : Transformation
    {
        public Vector3 Position;
        public override Matrix4x4 Matrix
        {
            get
            {
                Matrix4x4 result = Matrix4x4.identity;
                result.m03 = Position.x;
                result.m13 = Position.y;
                result.m23 = Position.z;
                return result;
            }
        }
    }
}