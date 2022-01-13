using System;
using System.Collections;
using UnityEngine;

namespace Mesh._01_生成网格
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class Grid : MonoBehaviour
    {
        public int xSize, ySize;
        private Vector3[] vertices;

        private void Awake()
        {
            Generate();
        }

        private UnityEngine.Mesh mesh;
        
        IEnumerator Generate()
        {
            vertices = new Vector3[(xSize + 1) * (ySize + 1)];
            GetComponent<MeshFilter>().mesh = mesh = new UnityEngine.Mesh();
            mesh.name = "Grid";
            for (int x = 0 , index = 0; x < xSize; x++)
            {
                for (int y = 0; y < ySize; y++, index++)
                {
                    vertices[index] = new Vector3(x, y);
                    yield return new WaitForSeconds(0.05f);
                }
            }
            mesh.vertices = vertices;
        }

        private void OnDrawGizmos()
        {
            if(vertices == null) return;
            foreach (var vert in vertices)
            {
                Gizmos.DrawSphere(vert, 0.1f);
            }
        }
    }
}