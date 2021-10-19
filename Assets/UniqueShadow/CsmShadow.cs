//using System;
//using System.Collections;
//using System.Collections.Generic;
//using System.Linq;
//using Unity.Mathematics;
//using UnityEngine;
//
//[ExecuteAlways]
//public class CsmShadow 
//{
//    public Camera m_Camera;
//    public float m_ShadowDistance;
//
//    public Light m_Light;
//    private Camera m_LightCamera;
//    private Bounds m_Bounds;
//    private Renderer[] m_Renders;
//
//
//    private List<Vector3> m_ObjectAABB = new List<Vector3>();
//    /// <summary>
//    /// 阴影空间下的视锥包围盒
//    /// </summary>
//    private List<Vector3> m_ShadowViewFrustum = new List<Vector3>();
//
//
//    void UpdateCamera()
//    {
//        ConstructShadowCamera();
//    }
//
//    public void Update()
//    {
//        GetRenders();//只更新一次
//        m_ObjectAABB=UpdateBounds();
//        m_ShadowViewFrustum =ShadowUtilties.GetViewFrustumAABB(UpdateShadowFrustum());
//        if (m_ShadowViewFrustum==null||m_ShadowViewFrustum.Count!=9)
//        {
//            Debug.LogError("视锥包围盒错误");
//            return;
//        }
//    }
//    
//    
//    Camera ConstructShadowCamera(float l,float r,float t,float b,float n,float f)
//    {
//        if (m_Camera == null)
//        {
//            m_Camera= new GameObject("light camera").AddComponent<Camera>();
//        }
//        
//        return m_Camera;
//    }
//
// 
//
//    /// <summary>
//    /// 更新世界坐标下的新计算的包围盒顶点
//    /// </summary>
//    List<Vector3> UpdateBounds()
//    {
//       
//        m_Bounds = new Bounds(transform.position, Vector3.zero);
//        foreach (var R in m_Renders)
//        {
//            m_Bounds.Encapsulate(R.bounds);
//        }
//
//        return ShadowUtilties.GetObjectAABBInWorld(m_Bounds);
//    }
//
//    
//
//    /// <summary>
//    /// 更新世界坐标下的view的八个角点
//    /// </summary>
//    List<Vector3> UpdateShadowFrustum()
//    {
//        if (m_Camera == null || m_ShadowDistance <= 0)
//        {
//            return null;
//        }
//         return ShadowUtilties.GetViewFrustum(m_Camera, m_ShadowDistance);
//    }
//    /// <summary>
//    ///  变换顶点坐标到指定的灯光空间下
//    /// </summary>
//
//    List<Vector3> Tranform2ShadowSpace(List<Vector3> aabb,Light light)
//    {
//        if (aabb!=null||aabb.Count>0)
//        {
//            for (int i = 0; i < aabb.Count; i++)
//            {
//                aabb[i] = light.transform.InverseTransformPoint(aabb[i]);
//            }
//        }
//        return aabb;
//    }
//    /// <summary>
//    /// 获取节点下的所有render组件
//    /// </summary>
//    void GetRenders()
//    {
//        if (m_Renders == null || m_Renders.Length <= 0)
//        {
//            m_Renders = gameObject.GetComponentsInChildren<Renderer>();
//            var mR = gameObject.GetComponent<Renderer>();
//            if (mR != null)
//            {
//                m_Renders.Append(mR);
//            }
//        }
//    }
//
//    /////////////
//    // Gizmos //
//    ////////////
//    #region DrawGizmos
//
//    private void OnDrawGizmos()
//    {
//        var R = GetComponent<Renderer>();
//
//        var m_ShadowViewFrustum = ShadowUtilties.GetObjectAABBInWorld(R.bounds);
//
//
//        DrawAABB();
//
//        DrawFrustum();
//        DrawProjBox(m_Light);
//        Gizmos.color = Color.white;
//    }
//
//    void DrawAABB()
//    {
//        Gizmos.color = Color.red;
//
//        // var m_ShadowViewFrustum = ShadowUtilties.GetObjectAABBInWorld(m_Render.bounds);
//        if (m_ObjectAABB != null && m_ObjectAABB.Count == 8)
//        {
//            Gizmos.DrawSphere(m_ObjectAABB[0], 0.1f);
//            Gizmos.DrawLine(m_ObjectAABB[0], m_ObjectAABB[1]);
//            Gizmos.DrawLine(m_ObjectAABB[1], m_ObjectAABB[2]);
//            Gizmos.DrawLine(m_ObjectAABB[2], m_ObjectAABB[3]);
//            Gizmos.DrawLine(m_ObjectAABB[0], m_ObjectAABB[3]);
//
//
//            Gizmos.DrawLine(m_ObjectAABB[4], m_ObjectAABB[5]);
//            Gizmos.DrawLine(m_ObjectAABB[5], m_ObjectAABB[6]);
//            Gizmos.DrawLine(m_ObjectAABB[6], m_ObjectAABB[7]);
//            Gizmos.DrawLine(m_ObjectAABB[4], m_ObjectAABB[7]);
//
//            Gizmos.DrawLine(m_ObjectAABB[0], m_ObjectAABB[4]);
//            Gizmos.DrawLine(m_ObjectAABB[3], m_ObjectAABB[7]);
//            Gizmos.DrawLine(m_ObjectAABB[2], m_ObjectAABB[6]);
//            Gizmos.DrawLine(m_ObjectAABB[1], m_ObjectAABB[5]);
//        }
//    }
//
//
//    void DrawFrustum()
//    {
//        Gizmos.color = Color.blue;
//        if (m_ShadowViewFrustum != null && m_ShadowViewFrustum.Count == 8)
//        {
//            Gizmos.DrawLine(m_ShadowViewFrustum[0], m_ShadowViewFrustum[1]);
//            Gizmos.DrawLine(m_ShadowViewFrustum[1], m_ShadowViewFrustum[2]);
//            Gizmos.DrawLine(m_ShadowViewFrustum[2], m_ShadowViewFrustum[3]);
//            Gizmos.DrawLine(m_ShadowViewFrustum[0], m_ShadowViewFrustum[3]);
//
//
//            Gizmos.DrawLine(m_ShadowViewFrustum[4], m_ShadowViewFrustum[5]);
//            Gizmos.DrawLine(m_ShadowViewFrustum[5], m_ShadowViewFrustum[6]);
//            Gizmos.DrawLine(m_ShadowViewFrustum[6], m_ShadowViewFrustum[7]);
//            Gizmos.DrawLine(m_ShadowViewFrustum[4], m_ShadowViewFrustum[7]);
//
//            Gizmos.DrawLine(m_ShadowViewFrustum[0], m_ShadowViewFrustum[4]);
//            Gizmos.DrawLine(m_ShadowViewFrustum[3], m_ShadowViewFrustum[7]);
//            Gizmos.DrawLine(m_ShadowViewFrustum[2], m_ShadowViewFrustum[6]);
//            Gizmos.DrawLine(m_ShadowViewFrustum[1], m_ShadowViewFrustum[5]);
//        }
//    }
//
//
//    void DrawProjBox(Light light)
//    {
//        Gizmos.color = Color.green;
//     
//        if (m_ShadowViewFrustum != null || m_ShadowViewFrustum.Count == 9)
//        {
//            var viewAABB = ShadowUtilties.GetViewFrustumAABB(m_ShadowViewFrustum,m_Light);
//            var list=new List<Vector3>();
//            //转到世界空间
//            for (int i = 0; i < viewAABB.Length; i++)
//            {
//                list.Add(light.transform.TransformPoint(viewAABB[i]));
//            }
//            Gizmos.DrawLine(list[0], list[1]);
//            Gizmos.DrawLine(list[1], list[2]);
//            Gizmos.DrawLine(list[2], list[3]);
//            Gizmos.DrawLine(list[0], list[3]);
//
//
//            Gizmos.DrawLine(list[4], list[5]);
//            Gizmos.DrawLine(list[5], list[6]);
//            Gizmos.DrawLine(list[6], list[7]);
//            Gizmos.DrawLine(list[4], list[7]);
//
//            Gizmos.DrawLine(list[0], list[4]);
//            Gizmos.DrawLine(list[3], list[7]);
//            Gizmos.DrawLine(list[2], list[6]);
//            Gizmos.DrawLine(list[1], list[5]);
//
//            Gizmos.DrawSphere(list[8], 0.2f);
//        }
//    }
//
//    #endregion Gizmo
//}