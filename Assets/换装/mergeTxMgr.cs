using UnityEngine;
using UnityEngine.UI;
using System;
public class mergeTxMgr
{

    public static mergeTxMgr Instance = new mergeTxMgr();
    
    public byte[] data;
    /// <param name="tex"> 256 的</param>
    /// <param name="length"> 要合成的大图长度</param>
    /// <returns></returns>
    public int getBlcokBytes(Texture2D tex, int length)
    {
        int blcokBytes = 0;
        data = null;
        switch (tex.format)
        {
            case TextureFormat.DXT1:
            case TextureFormat.ETC_RGB4:
            case TextureFormat.ETC2_RGB:
                blcokBytes = 8;
                data = new byte[length / 2 * length];
                break;
            case TextureFormat.DXT5:
            case TextureFormat.ETC2_RGBA8:
            case TextureFormat.ASTC_4x4:
                blcokBytes = 16;
                data = new byte[length * length];
                break;
            default:
                UnityEngine.Debug.LogError("不支持的合图格式："+ tex.format);
                return 0;
        }
        //128 && 256 && 512  合起来填充的1024 的  记住传参要合理
        return blcokBytes;
    }
    /// <summary>
    /// 一律按合成图的左下角为顶点坐标进行传值
    /// </summary>
    /// <param name="Vx">合成图的左顶点在大图上的X坐标  </param>
    /// <param name="Vy">合成图的左顶点在大图上的Y坐标</param>
    /// <param name="dst"></param>
    /// <param name="bytes"></param>
    /// <param name="length">合成的大图长度</param>
    /// <param name="tex">所要合成的小图</param>
    public void getByteInTx(float Vx, float Vy, byte[] dst,int bytes, int length, Texture2D tex)
    {
        var len = tex.width;
        var Proportion = length / len; 
        Vx = Vx * Proportion;
        Vy = Vy * Proportion;
        if (Vx >= Proportion || Vy >= Proportion)
        {
            return;
        }
        CombineBlocks(tex.GetRawTextureData(), dst, (int)Vx * tex.width, (int)Vy * tex.width, tex.width, 4, bytes, length);
    }

    void CombineBlocks(byte[] src, byte[] dst, int dstx, int dsty, int width, int block, int bytes, int length)
    {
        var dstbx = dstx / block;
        var dstby = dsty / block;

        for (int i = 0; i < width / block; i++)
        {
            int dstindex = (dstbx + (dstby + i) * (length / block)) * bytes;
            int srcindex = i * (width / block) * bytes;
            Buffer.BlockCopy(src, srcindex, dst, dstindex, width / block * bytes);
        }
    }
}