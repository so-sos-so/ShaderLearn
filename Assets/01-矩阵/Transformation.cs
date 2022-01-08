using UnityEngine;

namespace _01_矩阵
{
    public abstract class Transformation : MonoBehaviour
    {
        public abstract Matrix4x4 Matrix { get; }

        public Vector3 Apply(Vector3 point)
        {
            return Matrix * point;
        }
    }
}