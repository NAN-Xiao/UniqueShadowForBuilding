﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

public class UniqueShadow : MonoBehaviour
{
    //private

    private Camera m_shadowCamera;
    // public Vector3 m_boundsCenter;
    private Bounds m_bounds;
    private Renderer[] m_renders;
    
    private float m_radius;
    private List<Material> m_mts;
    private Matrix4x4 m_shadowMatrix;

    private Material m_depthCopy;
    
    //private float m_bias;

    //public
    public Light m_shadowLight;
    public int m_shadowMapSize = 2048;
    public RenderTexture m_shadowMap_template;
    public RenderTexture m_shadowMap_template2;

    public RenderTexture m_shadowMap_final;
    public float m_softFactor = 2.0f;
    public float _far=1.0f;
    [Range(0f,0.01f)]
    public float m_bias = 0.002f;

    [Range(0f, 1.0f)] 
    public float strength = 1.0f;
    public float m_blur;
   // public int m_esmcount=8;

    public float m_VSMMin = 1;


    const string UNIQUE_SHADOW = "UNIQUESHADOW";
    const string _UniqueShadowMatrix = "_UniqueShadowMatrix";
    const string _UniqueShadowFilterWidth = "_UniqueShadowFilterWidth";
    const string _UniqueShadowTexture = "_UniqueShadowTexture";
    const string _UniqueShadowStrength = "_UniqueShadowStrength";
    const string _UniqueShadowMapSize = "_UniqueShadowMapSize";
     const string _ESMConst = "_ESMConst";
     const string DepthCopy = "Hidden/depthcopy";
     const string _BLURSIZE = "_BlurSize";
    void Start()
    {
        InitCamera();
        GatherRendersInfo();
    }
    void Update()
    {
        UpdateBounds();
        UpdateCamera();
       
    }

    void UpdateCamera()
    {
        if (null==m_shadowLight)
        {
            Debug.LogError("no set any main shadow light");
            return;
        }
        //var lightdir = m_shadowLight.transform.position- transform.position;
        m_shadowCamera.transform.position = m_bounds.center - m_shadowLight.transform.forward * (m_radius+_far);
        m_shadowCamera.transform.rotation = m_shadowLight.transform.rotation;
        m_shadowCamera.orthographicSize = m_radius;
        m_shadowCamera.farClipPlane = Vector3.Distance(m_shadowCamera.transform.position, m_bounds.center)+m_radius*0.5f;

        var shadowProjection = Matrix4x4.Ortho(
            -m_radius,
            m_radius,
            -m_radius,
            m_radius,
            m_shadowCamera.nearClipPlane,
            m_shadowCamera.farClipPlane);

       
        var db = SystemInfo.usesReversedZBuffer ? m_bias : -m_bias;
        var m_shadowSpaceMatrix = Matrix4x4.identity;
        m_shadowSpaceMatrix.SetRow(0, new Vector4(0.5f, 0.0f, 0.0f, 0.5f));
        m_shadowSpaceMatrix.SetRow(1, new Vector4(0.0f, 0.5f, 0.0f, 0.5f));
        m_shadowSpaceMatrix.SetRow(2, new Vector4(0.0f, 0.0f, 0.5f, 0.5f + db));
        m_shadowSpaceMatrix.SetRow(3, new Vector4(0.0f, 0.0f, 0.0f, 1.0f));
        var camproj = m_shadowCamera.projectionMatrix;
        if (SystemInfo.usesReversedZBuffer)
        {
            camproj[2, 0] = -shadowProjection[2, 0];
            camproj[2, 1] = -shadowProjection[2, 1];
            camproj[2, 2] = -shadowProjection[2, 2];
            camproj[2, 3] = -shadowProjection[2, 3];
        }

        m_shadowMatrix = m_shadowSpaceMatrix * camproj * m_shadowCamera.worldToCameraMatrix;
   
        m_shadowCamera.Render();
        if (m_shadowMap_final==null)
        {
            var descriptor = m_shadowMap_template.descriptor;
         
            m_shadowMap_final = RenderTexture.GetTemporary(descriptor);
            m_shadowMap_final.format = RenderTextureFormat.RG16;
            //m_shadowMap_final.format = RenderTextureFormat.RGHalf;
            m_shadowMap_template2 = RenderTexture.GetTemporary(m_shadowMap_final.descriptor);
        }
      
        m_depthCopy.SetFloat(_BLURSIZE,m_blur);
        m_depthCopy.SetFloat("_MainTex_TexelSize",m_shadowMapSize);
        //esm
        Graphics.Blit(m_shadowMap_template, m_shadowMap_template2, m_depthCopy,1);
       Graphics.Blit(m_shadowMap_template2, m_shadowMap_final, m_depthCopy, 0);

        SetUniforms();  
    }

    void SetUniforms()
    {
        for (int i = 0, n = m_mts.Count; i < n; ++i)
        {
            var m = m_mts[i];
            m.EnableKeyword(UNIQUE_SHADOW);
            m.SetMatrix(_UniqueShadowMatrix, m_shadowMatrix);
            m.SetFloat(_UniqueShadowFilterWidth, m_softFactor / m_shadowMapSize);
            m.SetTexture(_UniqueShadowTexture, m_shadowMap_template);
            m.SetFloat(_UniqueShadowStrength, Mathf.Clamp01(strength));
            m.SetFloat(_UniqueShadowMapSize,m_shadowMapSize);
            m.SetFloat("_VSMMin", m_VSMMin);

        }
    }

    void UpdateBounds()
    {
        if (m_renders == null)
        {
            return;
        }

        m_bounds = new Bounds(transform.position, Vector3.one * 0.1f);

        foreach (var m in m_renders)
        {
            m_bounds.Encapsulate(m.bounds);
        }

        m_radius = m_bounds.extents.magnitude;
        //Debug.LogError(m_bounds.extents.magnitude);
    }

    void InitCamera()
    {
        if (m_shadowCamera == null)
        {
            m_shadowCamera = new GameObject("_UniqueShadow").AddComponent<Camera>();
        }

        //  m_shadowCamera.renderingPath = RenderingPath.Forward;
        m_shadowCamera.clearFlags = CameraClearFlags.Depth;
        m_shadowCamera.depthTextureMode = DepthTextureMode.Depth;
        m_shadowCamera.useOcclusionCulling = false;
        m_shadowCamera.cullingMask = ~0;
        m_shadowCamera.orthographic = true;
        m_shadowCamera.depth = -1000;
        m_shadowCamera.aspect = 1f;
        m_shadowCamera.gameObject.hideFlags = HideFlags.HideInHierarchy;
        m_shadowCamera.enabled=false;
        GetRenderTarget();
    }

    void GetRenderTarget()
    {
        if (m_shadowMap_template == null)
        {
//            var fm = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.Shadowmap)
//                ? RenderTextureFormat.Shadowmap
//                : RenderTextureFormat.Depth;

            m_shadowMap_template = RenderTexture.GetTemporary(m_shadowMapSize, m_shadowMapSize, 16, RenderTextureFormat.Shadowmap);
            m_shadowMap_template.filterMode = FilterMode.Point;
            m_shadowMap_template.wrapMode = TextureWrapMode.Clamp;
        }
        m_shadowCamera.targetTexture = m_shadowMap_template;
    }

    void InitMaterial()
    {
        if (m_depthCopy == null)
        {
            m_depthCopy=new Material(Shader.Find(DepthCopy));
        }

        if (m_depthCopy==null)
        {
            Debug.LogError("creat material fail");
        }
            
    }
    
    private void OnDisable()
    {
        RenderTexture.ReleaseTemporary(m_shadowMap_template);
        m_shadowMap_template = null;
        for (int i = 0, n = m_mts.Count; i < n; ++i)
        {
            var m = m_mts[i];
            m.DisableKeyword(UNIQUE_SHADOW);
          //  m.SetTexture(_UniqueShadowTexture, Texture2D.whiteTexture);
        }
       
      
    }


    void GatherRendersInfo()
    {
        m_renders = transform.GetComponentsInChildren<Renderer>();
        m_mts = new List<Material>();
        foreach (var r in m_renders)
        {
            var mt = r.sharedMaterials;
            foreach (var m in mt)
            {
                if (m_mts.Contains(m)) continue;
                m_mts.Add(m);
            }
        }

        InitMaterial();
    }

    private void OnDrawGizmos()
    {
        if (m_bounds != null)
        {
            Gizmos.DrawWireSphere(m_bounds.center, m_bounds.extents.magnitude);
            Gizmos.color = Color.red;
            Gizmos.DrawWireSphere(m_bounds.center, 0.5f);
        }
    }
}