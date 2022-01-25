using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using Object = UnityEngine.Object;

public class merge2 : MonoBehaviour
{
    private Transform clothRoot;
    public Transform[] Cloths;
    public Transform Skin;
    
    void Start()
    {
        clothRoot = new GameObject("ClothRoot").transform;
        clothRoot.SetParent(transform);
        clothRoot.localPosition = Vector3.zero;
        Combine();
    }

    public void Combine()
    {
        // The SkinnedMeshRenderers that will make up a character will be
        List<CombineInstance> combineInstances = new List<CombineInstance>();
        List<SkinnedMeshRenderer> skinnedMeshRenderers = new List<SkinnedMeshRenderer>();
        Material material = null;
        List<Transform> bones = new List<Transform>();
        List<Texture2D> textures = new List<Texture2D>();
        int uvCount = 0;

        List<Vector2[]> uvList = new List<Vector2[]>();
        foreach (var cloth in Cloths)
        {
            SkinnedMeshRenderer smr = cloth.GetComponentInChildren<SkinnedMeshRenderer>();
            skinnedMeshRenderers.Add(smr);
            if (material == null)
                material = Instantiate(smr.sharedMaterial);
            for (int sub = 0; sub < smr.sharedMesh.subMeshCount; sub++)
            {
                CombineInstance ci = new CombineInstance();
                ci.mesh = smr.sharedMesh;
                ci.subMeshIndex = sub;
                combineInstances.Add(ci);
            }

            uvList.Add(smr.sharedMesh.uv);
            uvCount += smr.sharedMesh.uv.Length;

            if (smr.material.mainTexture != null)
            {
                textures.Add(smr.GetComponent<Renderer>().material.mainTexture as Texture2D);
            }

            // we need to recollect references to the bones we are using
            bones.AddRange(GetBones(transform, smr));
            Object.Destroy(cloth.gameObject);
        }

        // Obtain and configure the SkinnedMeshRenderer attached to
        // the character base.
        SkinnedMeshRenderer r = Skin.gameObject.GetComponent<SkinnedMeshRenderer>();
        if (!r)
            r = Skin.gameObject.AddComponent<SkinnedMeshRenderer>();

        r.sharedMesh = new UnityEngine.Mesh();

        //only set mergeSubMeshes true will combine meshs into single submesh
        r.sharedMesh.CombineMeshes(combineInstances.ToArray(), true, false);
        r.bones = bones.ToArray();
        r.material = material;

        int xyMax = 1024;

        // 		Rect[] rec = skinnedMeshAtlas.PackTextures(textures.ToArray(), 0);
        Rect[] rec = new Rect[skinnedMeshRenderers.Count];
        for (int i = 0; i < rec.Length; i++)
        {
            var tex = skinnedMeshRenderers[i].sharedMaterial.mainTexture;
        }
        rec[0].xMin = 0; rec[0].xMax = 0.5f; rec[0].yMin = 0; rec[0].yMax = 0.5f;
        rec[1].xMin = 0.5f; rec[1].xMax = 0.75f; rec[1].yMin = 0f; rec[1].yMax = 0.25f;
        rec[2].xMin = 0.75f; rec[2].xMax = 1; rec[2].yMin = 0.25f; rec[2].yMax = 0.5f;
        // mergeTxMgr.Instance.getBlcokBytes(textures[0], 1024);
        // mergeTxMgr.Instance.getBlcokBytes(textures[1], 1024);
        int blockByte = mergeTxMgr.Instance.getBlcokBytes(textures[2], 1024);
        mergeTxMgr.Instance.getByteInTx(rec[0].xMin, rec[0].yMin, mergeTxMgr.Instance.data, blockByte, xyMax, textures[0]);
        mergeTxMgr.Instance.getByteInTx(rec[1].xMin, rec[1].yMin, mergeTxMgr.Instance.data, blockByte, xyMax, textures[1]);
        mergeTxMgr.Instance.getByteInTx(rec[2].xMin, rec[2].yMin, mergeTxMgr.Instance.data, blockByte, xyMax, textures[2]);
        var combinedTex = new Texture2D(xyMax, xyMax, textures[0].format, false);
        combinedTex.LoadRawTextureData(mergeTxMgr.Instance.data);
        combinedTex.Apply(false, true);


        Vector2[] atlasUVs = new Vector2[uvCount];
        //as combine textures into single texture,so need recalculate uvs			 
        int j = 0;
        for (int i = 0; i < uvList.Count; i++)
        {
            foreach (Vector2 uv in uvList[i])
            {
                atlasUVs[j].x = Mathf.Lerp(rec[i].xMin, rec[i].xMax, uv.x);
                atlasUVs[j].y = Mathf.Lerp(rec[i].yMin, rec[i].yMax, uv.y);
                //Debug.Log("第" + sq + "个矩形" + "xMin == " + rec[i].xMin + "   xMax == " + rec[i].xMax+"  原始uvX =="+uv.x+
                //    "  合并后 == " + atlasUVs[j].x + "yMin == " + rec[i].yMin + "   yMax == " + rec[i].yMax + "  原始uvY ==" 
                //    + uv.y + "  合并后 == " + atlasUVs[j].y);
                j++;
            }
        }

        r.material.mainTexture = combinedTex;
        r.sharedMesh.uv = atlasUVs;
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