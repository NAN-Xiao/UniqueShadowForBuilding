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
    [Range(0,1f)] public float m_Strength;
    public float m_SoftShadow=0.001f;
    [Range(0, 0.1f)] public float m_Bias2AABB;
    [Range(0, 0.1f)] public float m_Bias2View;
    [Range(0, 1f)] public float m_NormalBias=0.4f;
    public float m_ShadowDistance;
    public float m_zOffset = 0.1f;
    private List<Renderer> m_Renders = new List<Renderer>();
    private ObjectAABB m_ObjectAABB;
    private ObjectAABB m_ViewAABB;
    //rts
    public RenderTexture m_ShadowRT;
    //private
    private Matrix4x4[] m_shadowVP = new Matrix4x4[2];
    private int _ShadowMapID;
    private int _ShadowMatrixsID;
    private int _ShadowFarID;
    private int _ShadowNearID;
    private int _StrengthFarID;
    private int _SoftID;
    private void OnEnable()
    {
        m_Camera = Camera.main;
        m_ShadowRT = RenderTexture.GetTemporary(2048, 1024);
        m_ShadowRT.format = RenderTextureFormat.Shadowmap;
        m_ShadowRT.name = "_uniqueShadowMap";
        m_ShadowRT.filterMode = FilterMode.Bilinear;
        m_ShadowRT.wrapMode = TextureWrapMode.Clamp;
        m_ObjectAABB = new ObjectAABB();
        m_ViewAABB = new ObjectAABB();
        InitShaderProperties();
    }
    
    
    private void Update()
    {
        UpdateBounds();
        RenderShadow();
        //set shader
        if (m_ShadowRT != null)
        {
            foreach (var r in m_Renders)
            {
                r.sharedMaterial.SetTexture(_ShadowMapID, m_ShadowRT);
                r.sharedMaterial.SetVector("unity_LightShadowBias",new Vector4(0,0,0,m_NormalBias));
            }
        }
        Shader.SetGlobalMatrixArray(_ShadowMatrixsID, m_shadowVP);
        float clip = m_ViewAABB.m_Size.x > m_ViewAABB.m_Size.y ? m_ViewAABB.m_Size.x : m_ViewAABB.m_Size.y;
       // clip = clip > m_ViewAABB.m_Size.z ? clip : m_ViewAABB.m_Size.z;
        Shader.SetGlobalFloat(_ShadowFarID, m_ShadowDistance);
        Shader.SetGlobalMatrix("_W2CameraPos", m_Camera.worldToCameraMatrix);
        Shader.SetGlobalFloat(_StrengthFarID, m_Strength);
        Shader.SetGlobalFloat(_SoftID, m_SoftShadow);
        Shader.SetGlobalVector("_UniqueShadowSize", new Vector2(1024,1024));
    }
    void RenderShadow()
    {
        if (m_ShadowCamera == null)
        {
            m_ShadowCamera = new GameObject("___Light_Camera___").AddComponent<Camera>();
            m_ShadowCamera.depth = -1000;
            m_ShadowCamera.orthographic = true;
            m_ShadowCamera.clearFlags = CameraClearFlags.SolidColor;
        }
        if (m_ObjBounds == null || m_Light == null)
        {
            return;
        }
        m_ObjectAABB.UpdateAABB(m_ObjBounds);
        m_ObjectAABB.TransformLightSpace(m_Light);
        m_ShadowCamera.targetTexture = m_ShadowRT;
        m_ShadowCamera.transform.forward = m_Light.transform.forward;
        m_ShadowCamera.nearClipPlane = 0.01f;
        m_ShadowCamera.backgroundColor = Color.white;
        //unique
        RenderUnique();
        var proj = m_ShadowCamera.projectionMatrix;
        proj.m22 +=m_Bias2AABB;
        var vp0 = GL.GetGPUProjectionMatrix(proj, false) *
                  m_ShadowCamera.worldToCameraMatrix;
        m_shadowVP[0] = vp0;
        //csm
        RenderCSM();
        proj = m_ShadowCamera.projectionMatrix;
        proj.m22 +=m_Bias2View;
        var vp1 = GL.GetGPUProjectionMatrix(proj, false) *
                  m_ShadowCamera.worldToCameraMatrix;
        m_shadowVP[1] = vp1;
    }
    //rt0
    void RenderUnique()
    {
        //setcamera
        m_ShadowCamera.transform.position = m_ObjectAABB.m_Center;
        m_ShadowCamera.aspect = m_ObjectAABB.m_Size.x / m_ObjectAABB.m_Size.y;
        m_ShadowCamera.orthographicSize = m_ObjectAABB.m_Size.y * 0.5f;
        m_ShadowCamera.rect = new Rect(0f, 0, 0.5f, 1);
        //offset
        m_ShadowCamera.transform.position -= m_ShadowCamera.transform.forward * m_zOffset;
        m_ShadowCamera.farClipPlane = m_ObjectAABB.m_Max.z - m_ObjectAABB.m_Min.z -m_zOffset;
        m_ShadowCamera.Render();
    }
    //rt1
    void RenderCSM()
    {
        ShadowUtilties.GetViewFrustum(m_Camera, m_ShadowDistance, ref m_ViewAABB.m_Corners);
        m_ViewAABB.TransformLightSpace(m_Light);
        m_ShadowCamera.transform.position = m_ViewAABB.m_Center;
        m_ShadowCamera.aspect = m_ViewAABB.m_Size.x / m_ViewAABB.m_Size.y;
        m_ShadowCamera.orthographicSize = m_ViewAABB.m_Size.y * 0.5f;
        m_ShadowCamera.rect = new Rect(0.5f, 0, 1, 1);
        //offset
        m_ShadowCamera.transform.position -= m_ShadowCamera.transform.forward * m_zOffset;
        m_ShadowCamera.farClipPlane = m_ViewAABB.m_Max.z - m_ViewAABB.m_Min.z +m_zOffset;
        m_ShadowCamera.Render();
    }
    
    
    void InitShaderProperties()
    {
        _ShadowMapID = Shader.PropertyToID("_UniqueShadowTexture");
        _ShadowMatrixsID = Shader.PropertyToID("_UniqueShadowMatrix");
        _ShadowFarID = Shader.PropertyToID("_SplitFar");
        _StrengthFarID =Shader.PropertyToID("_UniqueShadowStrength"); 
        _SoftID=Shader.PropertyToID("_SoftShadow"); 
    }
    /// <summary>
    /// 获取所有的render组件
    /// </summary>
    void UpdateBounds()
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
    
    
    
    #region Gizmos for Debug
    void OnDrawGizmos()
    {
        /// Gizmos.DrawWireSphere(m_ObjBounds.center,m_ObjBounds.extents.sqrMagnitude);


        DrawObjecAABB();
        DrawCamera();
        Gizmos.color = Color.red;
//        ShadowUtilties.GetViewFrustum(m_Camera, m_ShadowDistance, ref m_ViewAABB.m_Corners);
//        m_ViewAABB.TransformLightSpace(m_Light);
//        Gizmos.DrawSphere(m_ShadowCamera.transform.TransformPoint(m_ViewAABB.m_Min),0.1f);
    }
    void DrawCamera()
    {
        ShadowUtilties.GetViewFrustum(m_Camera, m_ShadowDistance, ref m_ViewAABB.m_Corners);
        Vector3[] points = m_ViewAABB.m_Corners;

        Gizmos.color = Color.cyan;
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
        Gizmos.DrawSphere(m_ViewAABB.m_Center, 0.05f);
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
        Gizmos.DrawSphere(m_ObjectAABB.m_Center, 0.05f);
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
    #endregion
}