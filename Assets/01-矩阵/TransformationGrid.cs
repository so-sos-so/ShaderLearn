using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace _01_矩阵
{
    public class TransformationGrid : MonoBehaviour
    {
        public Transform Prefab;
        public int GridResolution = 10;
        private Transform[] grid;
        private List<Transformation> transformations = new List<Transformation>();

        void Start()
        {
            grid = new Transform[GridResolution * GridResolution * GridResolution];
            for (int i = 0, index = 0; i < GridResolution; i++)
            {
                for (int j = 0; j < GridResolution; j++)
                {
                    for (int k = 0; k < GridResolution; k++, index++)
                    {
                        grid[index] = CreateGridPoint(i, j, k);
                    }
                }
            }
        }

        private Transform CreateGridPoint(int x, int y, int z)
        {
            var go = Instantiate(Prefab, transform);
            go.localPosition = GetCoordinates(x, y, z);
            go.GetComponentInChildren<MeshRenderer>().material.color = new Color(x * 1.0f / GridResolution,
                y * 1.0f / GridResolution, z * 1.0f / GridResolution);
            return go;
        }

        private Vector3 GetCoordinates(int x, int y, int z)
        {
            return new Vector3(
                x - (GridResolution - 1) * 0.5f,
                z - (GridResolution - 1) * 0.5f,
                y - (GridResolution - 1) * 0.5f
            );
        }

        // Update is called once per frame
        void Update()
        {
            UpdateTransformation();
            for (int i = 0, index = 0; i < GridResolution; i++)
            {
                for (int j = 0; j < GridResolution; j++)
                {
                    for (int k = 0; k < GridResolution; k++, index++)
                    {
                        grid[index].localPosition = TransformPoint(i, j, k);
                    }
                }
            }
        }

        private Matrix4x4 transformationMat;
        
        private void UpdateTransformation()
        {
            GetComponents(transformations);
            transformationMat = Matrix4x4.identity;
            foreach (var transformation in transformations)
            {
                transformationMat = transformation.Matrix * transformationMat;
            }
        }

        private Vector3 TransformPoint(int x, int y, int z)
        {
            var coordinates = GetCoordinates(x, y, z);
            coordinates = transformationMat.MultiplyPoint(coordinates);
            //coordinates = transformationMat * coordinates;
            return coordinates;
        }
    }
}