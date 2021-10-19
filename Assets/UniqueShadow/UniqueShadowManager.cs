using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

[ExecuteInEditMode]
public class UniqueShadowManager : MonoBehaviour
{
    public Camera m_Camera;
    public Light m_Light;
    public Camera m_ShadowCamera;
    public Bounds m_ObjBounds;
    public float m_ShadowDistance;

    private List<Renderer> m_Renders = new List<Renderer>();
    private ObjectAABB m_ObjectAABB;

    private ObjectAABB m_ViewAABB;

    //  private Vector3[] m_ObjectAABB=new Vector3[8];
    public float m_zOffset = 0.1f;

    //rts
    public RenderTexture[] m_ShadowRT;

    private void OnEnable()
    {
        m_Camera = Camera.main;
        m_ShadowRT = new RenderTexture [2];
        for (int i = 0; i < m_ShadowRT.Length; i++)
        {
            m_ShadowRT[i] = RenderTexture.GetTemporary(1024, 1024);
            m_ShadowRT[i].format = RenderTextureFormat.Depth;
        }

        m_ObjectAABB = new ObjectAABB();
        m_ViewAABB = new ObjectAABB();
    }

    private void Update()
    {
        UpdateBounds();
//      ShadowUtilties.GetObjectAABB(m_Light,m_ObjBounds, ref m_ObjectAABB);
        RenderShadow();
    }


    void RenderShadow()
    {
        if (m_ShadowCamera == null)
        {
            m_ShadowCamera = new GameObject("___Light_Camera___").AddComponent<Camera>();
            m_ShadowCamera.depth = -1000;
            m_ShadowCamera.orthographic = true;
            m_ShadowCamera.clearFlags = CameraClearFlags.Depth;
        }

        if (m_ObjBounds == null || m_Light == null)
        {
            return;
        }

        m_ObjectAABB.UpdateAABB(m_ObjBounds);
        m_ObjectAABB.TransformLightSpace(m_Light);
        RenderUnique();
        RenderCSM();
    }

    //rt0
    void RenderUnique()
    {
        //setcamera
        m_ShadowCamera.targetTexture = m_ShadowRT[0];

        m_ShadowCamera.transform.position = m_ObjectAABB.m_Center;
        m_ShadowCamera.transform.rotation = m_Light.transform.rotation;
        m_ShadowCamera.aspect = m_ObjectAABB.m_Size.x / m_ObjectAABB.m_Size.y;
        m_ShadowCamera.orthographicSize = m_ObjectAABB.m_Size.y * 0.5f;
        //offset
        m_ShadowCamera.transform.position -= m_ShadowCamera.transform.forward * m_zOffset;
        m_ShadowCamera.farClipPlane = m_ObjectAABB.m_Max.z - m_ObjectAABB.m_Min.z + m_zOffset;
        m_ShadowCamera.Render();
    }

    //rt1
    void RenderCSM()
    {
       
        ShadowUtilties.GetViewFrustum(m_Camera, m_ShadowDistance, ref m_ViewAABB.m_Corners);
        m_ViewAABB.TransformLightSpace(m_Light);
        
        
        m_ShadowCamera.targetTexture = m_ShadowRT[1];
        m_ShadowCamera.transform.position = m_ViewAABB.m_Center;
        m_ShadowCamera.transform.rotation = m_Light.transform.rotation;
        m_ShadowCamera.aspect = m_ViewAABB.m_Size.x / m_ViewAABB.m_Size.y;
        m_ShadowCamera.orthographicSize = m_ViewAABB.m_Size.y * 0.5f;
        //offset
        m_ShadowCamera.transform.position -= m_ShadowCamera.transform.forward * m_zOffset;
        m_ShadowCamera.farClipPlane = m_ViewAABB.m_Max.z - m_ViewAABB.m_Min.z + m_zOffset;
        m_ShadowCamera.Render();
    }


    /// <summary>
    /// 获取所有的render组件
    /// </summary>
    public void UpdateBounds()
    {
        if (m_Renders.Count <= 0)
        {
            var c = gameObject.GetComponentsInChildren<Renderer>();
            if (c.Length > 0)
            {
                m_Renders.AddRange(c);
            }

            var r = gameObject.GetComponent<Renderer>();
            if (r != null)
            {
                m_Renders.Add(r);
            }
        }

        if (m_Renders.Count <= 0)
        {
            return;
        }

        m_ObjBounds = new Bounds(transform.position, Vector3.zero);

        foreach (var r in m_Renders)
        {
            m_ObjBounds.Encapsulate(r.bounds);
        }
    }


//
//
//   public void SetVector(int x, int y, int z, ref Vector3 point)
//   {
//      point.Set(x,y,z);
//   }

    private void OnDrawGizmos()
    {
        /// Gizmos.DrawWireSphere(m_ObjBounds.center,m_ObjBounds.extents.sqrMagnitude);


        DrawObjecAABB();
        DrawCamera();
    }

    void DrawCamera()
    {  
        ShadowUtilties.GetViewFrustum(m_Camera, m_ShadowDistance, ref m_ViewAABB.m_Corners);
        Vector3[] points = m_ViewAABB.m_Corners;
        
        Gizmos.color=Color.cyan;
        Gizmos.DrawLine(points[0], points[1]);
        Gizmos.DrawLine(points[1], points[2]);
        Gizmos.DrawLine(points[2], points[3]);
        Gizmos.DrawLine(points[0], points[3]);

        Gizmos.DrawLine(points[4], points[5]);
        Gizmos.DrawLine(points[5], points[6]);
        Gizmos.DrawLine(points[6], points[7]);
        Gizmos.DrawLine(points[4], points[7]);

        Gizmos.DrawLine(points[0], points[4]);
        Gizmos.DrawLine(points[1], points[5]);
        Gizmos.DrawLine(points[2], points[6]);
        Gizmos.DrawLine(points[3], points[7]);
        
        m_ViewAABB.TransformLightSpace(m_Light);
        points = m_ViewAABB.m_Corners;


        for (int i = 0; i < points.Length; i++)
        {
            var pp = m_Light.transform.TransformPoint(points[i]);
            ShadowUtilties.SetCorners(i, pp.x, pp.y, pp.z, ref points);
        }
        Gizmos.color = Color.green;
        Gizmos.DrawSphere(m_ObjectAABB.m_Center, 0.1f);
        Gizmos.DrawLine(points[0], points[1]);
        Gizmos.DrawLine(points[1], points[2]);
        Gizmos.DrawLine(points[2], points[3]);
        Gizmos.DrawLine(points[0], points[3]);
        Gizmos.color = Color.red;
        Gizmos.DrawLine(points[4], points[5]);
        Gizmos.DrawLine(points[5], points[6]);
        Gizmos.DrawLine(points[6], points[7]);
        Gizmos.DrawLine(points[4], points[7]);
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(points[0], points[4]);
        Gizmos.DrawLine(points[1], points[5]);
        Gizmos.DrawLine(points[2], points[6]);
        Gizmos.DrawLine(points[3], points[7]);
    }

    void DrawObjecAABB()
    {
        // Vector3[] points = m_ObjectAABB;


        m_ObjectAABB.UpdateAABB(m_ObjBounds);
        Vector3[] points = m_ObjectAABB.m_Corners;
        Gizmos.color = Color.red;
        Gizmos.DrawLine(points[0], points[1]);
        Gizmos.DrawLine(points[1], points[2]);
        Gizmos.DrawLine(points[2], points[3]);
        Gizmos.DrawLine(points[0], points[3]);

        Gizmos.DrawLine(points[4], points[5]);
        Gizmos.DrawLine(points[5], points[6]);
        Gizmos.DrawLine(points[6], points[7]);
        Gizmos.DrawLine(points[4], points[7]);

        Gizmos.DrawLine(points[0], points[4]);
        Gizmos.DrawLine(points[1], points[5]);
        Gizmos.DrawLine(points[2], points[6]);
        Gizmos.DrawLine(points[3], points[7]);

        m_ObjectAABB.TransformLightSpace(m_Light);
        points = m_ObjectAABB.m_Corners;


        for (int i = 0; i < points.Length; i++)
        {
            var pp = m_Light.transform.TransformPoint(points[i]);
            ShadowUtilties.SetCorners(i, pp.x, pp.y, pp.z, ref points);
        }


        Gizmos.color = Color.green;
        Gizmos.DrawSphere(m_ObjectAABB.m_Center, 0.1f);
        Gizmos.DrawLine(points[0], points[1]);
        Gizmos.DrawLine(points[1], points[2]);
        Gizmos.DrawLine(points[2], points[3]);
        Gizmos.DrawLine(points[0], points[3]);
        Gizmos.color = Color.red;
        Gizmos.DrawLine(points[4], points[5]);
        Gizmos.DrawLine(points[5], points[6]);
        Gizmos.DrawLine(points[6], points[7]);
        Gizmos.DrawLine(points[4], points[7]);
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(points[0], points[4]);
        Gizmos.DrawLine(points[1], points[5]);
        Gizmos.DrawLine(points[2], points[6]);
        Gizmos.DrawLine(points[3], points[7]);
    }
}