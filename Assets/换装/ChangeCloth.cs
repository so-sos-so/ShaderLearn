using System;
using System.Collections.Generic;
using UnityEngine;

public class ChangeCloth : MonoBehaviour
{
    public Transform RootTrans;
    private Transform clothRoot;

    public Transform[] Cloths;
    
    // Start is called before the first frame update
    void Start()
    {
        clothRoot = new GameObject("ClothRoot").transform;
        clothRoot.SetParent(RootTrans);
        clothRoot.localPosition = Vector3.zero;
        foreach (var cloth1 in Cloths)
        {
            var cloth = Instantiate(cloth1, clothRoot).GetComponentInChildren<SkinnedMeshRenderer>();
            cloth.bones = GetBones(RootTrans, cloth);
        }
    }

    private void OnGUI()
    {
        if (GUI.Button(new Rect(100, 100, 200, 100), "更换"))
        {
            foreach (Transform child in clothRoot)
            {
                Destroy(child.gameObject);
            }
            foreach (var cloth1 in Cloths)
            {
                var cloth = Instantiate(cloth1, clothRoot).GetComponentInChildren<SkinnedMeshRenderer>();
                cloth.bones = GetBones(RootTrans, cloth);
            }
        }
    }

    private Transform[] GetBones(Transform root, SkinnedMeshRenderer target)
    {
        Transform[] targetBones = target.bones;
        List<Transform> result = new List<Transform>();
        foreach (var targetBone in targetBones)
        {
            var bone = DepthFind(root, targetBone.name);
            if (bone == null)
            {
                print($"找不到{targetBone.name}");
                break;
            }
            result.Add(bone);
        }
        return result.ToArray();
    }

    private Transform DepthFind(Transform trans, string name)
    {
        foreach (Transform child in trans)
        {
            if (child.name == name)
                return child;
            if (child.childCount > 0)
            {
                var target = DepthFind(child, name);
                if (target != null) return target;
            }
        }
        return null;
    }
}
