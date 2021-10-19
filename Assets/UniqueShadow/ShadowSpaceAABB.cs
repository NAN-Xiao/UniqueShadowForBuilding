//using System.Collections;
//using System.Collections.Generic;
//using Unity.Mathematics;
//using UnityEngine;
//
//public class ShadowSpaceAABB
//{
//    public Vector3[] m_Corner;
//
//    public Vector3 m_Min;
//
//    public Vector3 m_Max;
//
//    public Vector3 m_Size;
//
//    public Vector3 m_WorldCenter;
//    public Light m_Light;
//    
//    
//    public ShadowSpaceAABB()
//    {
//        m_Corner=new Vector3[8];
//        m_Min=new Vector3();
//        m_Max=new Vector3();
//        m_Size=new Vector3();
//        m_WorldCenter=new Vector3();
//    }
//    /// <summary>
//    /// 世界aabb
//    /// </summary>
//    public void CalculateAABBInWorld(Bounds bounds)
//    {
//         m_Min = bounds.min;
//         m_Max = bounds.max;
//         m_Size = bounds.size;
//         SetCorner(0, m_Min.x, m_Min.y, m_Min.z,ref m_Corner);
//         SetCorner(1, m_Min.x+m_Size.x, m_Min.y, m_Min.z,ref m_Corner);
//         SetCorner(2, m_Min.x+m_Size.x, m_Min.y+m_Size.y, m_Min.z,ref m_Corner);
//         SetCorner(3, m_Min.x, m_Min.y+m_Size.y, m_Min.z,ref m_Corner);
//         SetCorner(4, m_Min.x, m_Min.y, m_Min.z+m_Size.z,ref m_Corner);
//         SetCorner(5, m_Min.x+m_Size.x, m_Min.y, m_Min.z+m_Size.z,ref m_Corner);
//         SetCorner(6, m_Max.x, m_Max.y, m_Max.z,ref m_Corner);
//         SetCorner(7, m_Min.x, m_Min.y+ m_Size.y, m_Min.z+m_Size.z,ref m_Corner);
//
//         #region MyRegion
//
//         //        list.Add(min); //0
////        list.Add(min + new Vector3(size.x, 0, 0)); //1
////        list.Add(min + new Vector3(size.x, size.y, 0)); //2
////        list.Add(min + new Vector3(0, size.y, 0)); //3  
////        
////        list.Add(min + new Vector3(0, 0, size.z)); //4
////
////        list.Add(min + new Vector3(size.x, 0, size.z)); //5
////        list.Add(max); //6
////        list.Add(min + new Vector3(0, size.y, size.z)); //7
////        return list;  
//
//         #endregion
//
//    }
//    public void CalculateAABB(Vector3[] corners)
//    {
//        if (corners==null||corners.Length!=8)
//        {
//            return;
//        }
//
//        float xmin = float.MaxValue;
//        float ymin = float.MaxValue;
//        float zmin = float.MaxValue;
//        
//        float xmax = float.MinValue;
//        float ymax = float.MinValue;
//        float zmax = float.MinValue;
//
//
//        for (int i = 0; i < corners.Length; i++)
//        {
//            Vector3 pointInLightSpace = m_Light.transform.InverseTransformPoint(corners[i]);
//            //min
//            xmin = Mathf.Min(xmin, pointInLightSpace.x);
//            ymin = Mathf.Min(ymin, pointInLightSpace.y);
//            zmin = Mathf.Min(zmin, pointInLightSpace.z);
//            //max
//            xmax = Mathf.Max(xmax, pointInLightSpace.x);
//            ymax = Mathf.Max(ymax, pointInLightSpace.y);
//            zmax = Mathf.Max(zmax, pointInLightSpace.z);
//        }
//        //set size
//        float xsize = (xmax - xmin);
//        float ysize = (ymax - ymin);
//        float zsize = (zmax - zmin);
//        SetCorner(xsize,ysize,zsize,ref m_Size);
//        
//        SetCorner(xmin,ymin,zmin,ref m_Min);
//        SetCorner(xmax,ymax,zmax,ref m_Max);
//      
//       
//        
//        SetCorner(0, m_Min.x, m_Min.y, m_Min.z,ref m_Corner);
//        SetCorner(1, m_Min.x+xsize, m_Min.y, m_Min.z,ref m_Corner);
//        SetCorner(2, m_Min.x+xsize, m_Min.y+ysize, m_Min.z,ref m_Corner);
//        SetCorner(3, m_Min.x, m_Min.y+ysize, m_Min.z,ref m_Corner);
//        
//        SetCorner(4, m_Min.x, m_Min.y, m_Min.z+zsize,ref m_Corner);
//        SetCorner(5, m_Min.x+xsize, m_Min.y, m_Min.z+zsize,ref m_Corner);
//        SetCorner(6, m_Max.x, m_Max.y, m_Max.z+zsize,ref m_Corner);
//        SetCorner(7, m_Min.x, m_Min.y+ysize, m_Min.z+zsize,ref m_Corner);
//        m_WorldCenter = m_Light.transform.TransformPoint(new Vector3(m_Min.x+xsize / 2,ymax+ysize / 2,zmax));
//    }
//
//
//    public void CalculateViewFustrum()
//    {
//        var tan = Mathf.Tan(Mathf.Deg2Rad * (camera.fieldOfView / 2f));
//        float aspect = camera.aspect;
//        float nz = camera.nearClipPlane;
//        float ny = nz * tan;
//        float nx = ny * aspect;
//
//        float fz = clip;
//        float fy = fz * tan;
//        float fx = fy * aspect;
//        Vector3[] viewCorner=new Vector3[8];
//        //视锥远裁剪右上角
//        SetCorner(fx, fy, fz,ref m_Min);
//        //视锥近裁剪左下角
//        SetCorner(0, -nx, -ny, nz,ref viewCorner);
//        SetCorner(1, -nx, -ny, nz,ref viewCorner);
//        SetCorner(2, nx, ny, nz,ref viewCorner);
//        SetCorner(3, -nx, ny, nz,ref viewCorner);
//        SetCorner(4, -fx, -fy, fz,ref viewCorner);
//        SetCorner(5, fx, -fy, fz,ref viewCorner);
//        SetCorner(6, fx, fy, fz,ref viewCorner);
//        SetCorner(7, -fx, fy, fz,ref viewCorner);
//    }
//    
//    
//
//
//    public void TransformToShadow(Light light)
//    {
//        
//    }
//    
//    public void SetCorner(float x, float y, float z,ref Vector3 point)
//    {
//        point.Set(x,y,z);
//    }
//    public void SetCorner(int index,float x, float y, float z,ref Vector3[] courner)
//    {
//        courner[index].Set(x,y,z);
//    }
//}
