using UnityEngine;

namespace _01_矩阵
{
    public abstract class Transformation : MonoBehaviour
    {
        public abstract Vector3 Apply(Vector3 point);
    }
}