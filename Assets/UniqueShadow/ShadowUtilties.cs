using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class ShadowUtilties
{
    /// <summary>
    /// 获取物体在世界空间的AABB
    /// </summary>
    public static void GetObjectAABB(Bounds bounds, ref Vector3[] corners)
    {
        var min = bounds.min;
        var size = bounds.size;
        SetCorners(0, min.x, min.y, min.z, ref corners);
        SetCorners(1, min.x + size.x, min.y, min.z, ref corners);
        SetCorners(2, min.x + size.x, min.y + size.y, min.z, ref corners);
        SetCorners(3, min.x, min.y + size.y, min.z, ref corners);

        SetCorners(4, min.x, min.y, min.z + size.z, ref corners);
        SetCorners(5, min.x + size.x, min.y, min.z + size.z, ref corners);
        SetCorners(6, min.x + size.x, min.y + size.y, min.z + size.z, ref corners);
        SetCorners(7, min.x, min.y + size.y, min.z + size.z, ref corners);
    }


    /// <summary>
    /// 获取摄像机的阴影视锥在世界空间下的八个角点
    /// clip阴影距离的远裁剪面
    /// </summary>
    public static  void GetViewFrustum(Camera camera, float clip, ref Vector3[] viewcorner)
    {

        var tan = Mathf.Tan(Mathf.Deg2Rad * (camera.fieldOfView / 2f));

        float aspect = camera.aspect;
        float nz = camera.nearClipPlane;
        float ny = nz * tan;
        float nx = ny * aspect;

        float fz = clip;
        float fy = fz * tan;
        float fx = fy * aspect;

        Vector3 pos1 = new Vector3(-nx, -ny, nz);
        Vector3 pos2 = new Vector3(nx, -ny, nz);
        Vector3 pos3 = new Vector3(nx, ny, nz);
        Vector3 pos4 = new Vector3(-nx, ny, nz);

        Vector3 pos5 = new Vector3(-fx, -fy, fz);
        Vector3 pos6 = new Vector3(fx, -fy, fz);
        Vector3 pos7 = new Vector3(fx, fy, fz);
        Vector3 pos8 = new Vector3(-fx, fy, fz);

        viewcorner[0] = camera.transform.TransformPoint(pos1);
        viewcorner[1] = camera.transform.TransformPoint(pos2);
        viewcorner[2] = camera.transform.TransformPoint(pos3);
        viewcorner[3] = camera.transform.TransformPoint(pos4);
        viewcorner[4] = camera.transform.TransformPoint(pos5);
        viewcorner[5] = camera.transform.TransformPoint(pos6);
        viewcorner[6] = camera.transform.TransformPoint(pos7);
        viewcorner[7] = camera.transform.TransformPoint(pos8);
    }

    #region MyRegion

     /// <summary>
    /// 获取包view在灯光下的包围盒 返回vector3数组
    /// 下标9为摄像机位置
    /// /// </summary>
//  public  static  Vector3[] GetViewFrustumAABB(List<Vector3> Frustum, Light light)
//    {
//        if (Frustum == null || Frustum.Count != 8)
//        {
//            return null;
//        }
//
//        Vector3[] list = new Vector3[9];
//        float xmin = float.MaxValue, xmax = float.MinValue;
//        float ymin = float.MaxValue, ymax = float.MinValue;
//        float zmin = float.MaxValue, zmax = float.MinValue;
//        foreach (Vector3 cornerPoints in Frustum)
//        {
//            Vector3 pointInLightSpace = light.transform.InverseTransformPoint(cornerPoints);
//            //min
//            xmin = Mathf.Min(xmin, pointInLightSpace.x);
//            ymin = Mathf.Min(ymin, pointInLightSpace.y);
//            zmin = Mathf.Min(zmin, pointInLightSpace.z);
//            //max
//            xmax = Mathf.Max(xmax, pointInLightSpace.x);
//            ymax = Mathf.Max(ymax, pointInLightSpace.y);
//            zmax = Mathf.Max(zmax, pointInLightSpace.z);
//        }
//
//        float xsize = (xmax - xmin);
//        float ysize = (ymax - ymin);
//        float zsize = (zmax - zmin);
//        float nearPlane = 0.1f;
//        var min = new Vector3(xmin, ymin, zmin);
//        var max = new Vector3(xmax, ymax, zmax);
//        var pos = min + new Vector3(xsize / 2, ysize / 2, 0);
//       
//        list[0] = min;
//        list[1] = min + new Vector3(xsize, 0, 0);
//        list[2] = min + new Vector3(xsize, ysize, 0);
//        list[3] = min + new Vector3(0, ysize, 0);
//        
//        list[4] = min + new Vector3(0, 0, zsize);
//        list[5] = min + new Vector3(xsize, 0, zsize);
//        list[6] = max;//
//        list[7] = min + new Vector3(0, ysize, zsize);
//        //最后一个near（min）的中心，用来做摄像机位置
//        list[8] = pos;
//        return list;
//    }

    #endregion
   
    public static void TransformTOLightSpace(Light light, ref Vector3[] corners, out Vector3 min, out Vector3 max,
        out Vector3 size)
    {
        float xmin = float.MaxValue, xmax = float.MinValue;
        float ymin = float.MaxValue, ymax = float.MinValue;
        float zmin = float.MaxValue, zmax = float.MinValue;
        foreach (Vector3 cornerPoints in corners)
        {
            Vector3 pointInLightSpace = light.transform.InverseTransformPoint(cornerPoints);
            //min
            xmin = Mathf.Min(xmin, pointInLightSpace.x);
            ymin = Mathf.Min(ymin, pointInLightSpace.y);
            zmin = Mathf.Min(zmin, pointInLightSpace.z);
            //max
            xmax = Mathf.Max(xmax, pointInLightSpace.x);
            ymax = Mathf.Max(ymax, pointInLightSpace.y);
            zmax = Mathf.Max(zmax, pointInLightSpace.z);
        }

        min = new Vector3(xmin, ymin, zmin);
        size = new Vector3(xmax - xmin, ymax - ymin, zmax - zmin);
        max = new Vector3(xmax, ymax, zmax);
        SetCorners(0, min.x, min.y, min.z, ref corners);
        SetCorners(1, min.x + size.x, min.y, min.z, ref corners);
        SetCorners(2, min.x + size.x, min.y + size.y, min.z, ref corners);
        SetCorners(3, min.x, min.y + size.y, min.z, ref corners);

        SetCorners(4, min.x, min.y, min.z + size.z, ref corners);
        SetCorners(5, min.x + size.x, min.y, min.z + size.z, ref corners);
        SetCorners(6, min.x + size.x, min.y + size.y, min.z + size.z, ref corners);
        SetCorners(7, min.x, min.y + size.y, min.z + size.z, ref corners);
    }

    /// <summary>
    /// 设置数组
    /// </summary>
    public static void SetCorners(int index, float x, float y, float z, ref Vector3[] corners)
    {
        corners[index].Set(x, y, z);
    }
}