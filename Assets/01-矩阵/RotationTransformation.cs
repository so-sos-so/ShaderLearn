using UnityEngine;

namespace _01_矩阵
{
    public class RotationTransformation : Transformation
    {
        public Vector3 Rotation;
        
        public override Matrix4x4 Matrix
        {
            get
            {
                Matrix4x4 result = Matrix4x4.identity;
                float radZ = Rotation.z * Mathf.Deg2Rad;
                float radY = Rotation.y * Mathf.Deg2Rad;
                float radX = Rotation.x * Mathf.Deg2Rad;
                float sinZ = Mathf.Sin(radZ);
                float cosZ = Mathf.Cos(radZ);
                float sinY = Mathf.Sin(radY);
                float cosY = Mathf.Cos(radY);
                float sinX = Mathf.Sin(radX);
                float cosX = Mathf.Cos(radX);

                result.SetRow(0, new Vector4(
                    cosY * cosZ,
                    cosX * sinZ + sinX * sinY * cosZ,
                    sinX * sinZ - cosX * sinY * cosZ,
                    0
                ));

                result.SetRow(1, new Vector4(
                    -cosY * sinZ,
                    cosX * cosZ - sinX * sinY * sinZ,
                    sinX * cosZ + cosX * sinY * sinZ,
                    0
                ));

                result.SetRow(2, new Vector4(
                    sinY,
                    -sinX * cosY,
                    cosX * cosY,
                    0
                ));
                return result;
            }
        }
    }
}