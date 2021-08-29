using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomUniqueShadows : MonoBehaviour
{
    //private
    Camera m_shadowCamera;

    public Vector3 m_boundsCenter;

    Bounds m_bounds;

    Renderer[] m_renders;


    float m_radius;
    //public

    public Light m_shadowLight;

    public int m_shadowMapSize=2048;
    public RenderTexture m_shadowMap;

    public float orthographicSize;



    // Start is called before the first frame update
    void Start()
    {
        //test
        InitCamera();
        GetRenderTarget();
        m_renders = transform.GetComponentsInChildren<Renderer>();
    }

    // Update is called once per frame
    void Update()
    {
        UpdateBounds();
        UpdateCamera();
    }

    void UpdateCamera()
    {
        //var lightdir = m_shadowLight.transform.position- transform.position;
        m_shadowCamera.transform.position = m_bounds.center-m_shadowLight.transform.forward* m_radius;
        m_shadowCamera.transform.rotation = m_shadowLight.transform.rotation;
        m_shadowCamera.orthographicSize = m_radius;
        m_shadowCamera.farClipPlane = Vector3.Distance(m_shadowCamera.transform.position, m_bounds.center) + m_radius;   
    }
     void SetUniforms()
    {
        for (int i = 0, n = m_materialInstances.Count; i < n; ++i)
        {
            var m = m_materialInstances[i];
            m.EnableKeyword(UNIQUE_SHADOW);
            m.SetMatrix(Uniforms._UniqueShadowMatrix, m_shadowMatrix);
            m.SetFloat(Uniforms._UniqueShadowFilterWidth, m_shadowFilterWidth);
            m.SetTexture(Uniforms._UniqueShadowTexture, m_UniqueShadowTexture);
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
        Debug.LogError(m_bounds.extents.magnitude);


    }

    void InitCamera()
    {
       if(m_shadowCamera==null)
        {
            m_shadowCamera = new GameObject("_UniqueShadow").AddComponent<Camera>();
        }
      //  m_shadowCamera.renderingPath = RenderingPath.Forward;
        m_shadowCamera.clearFlags = CameraClearFlags.Depth;
        m_shadowCamera.depthTextureMode = DepthTextureMode.Depth;
        m_shadowCamera.useOcclusionCulling = false;
        m_shadowCamera.cullingMask = ~0;
        m_shadowCamera.orthographic = true;
        m_shadowCamera.depth = -100;
        m_shadowCamera.aspect = 1f;
      //  m_shadowCamera.enabled = false;

    }

    void GetRenderTarget()
    {
        if (m_shadowMap == null)
        {
            var fm = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.Shadowmap)
             ? RenderTextureFormat.Shadowmap
             : RenderTextureFormat.Depth;

            m_shadowMap = RenderTexture.GetTemporary(m_shadowMapSize, m_shadowMapSize, 16, fm);
            m_shadowMap.filterMode = FilterMode.Bilinear;
            m_shadowMap.wrapMode = TextureWrapMode.Clamp;

        }
        m_shadowCamera.targetTexture = m_shadowMap;
    }

    private void OnDestroy()
    {
        //remove camera;
        //clear mesh;
        //clear bounds;
        
    }


    private void OnDrawGizmos()
    {


        if(m_bounds!=null)
        {

            Gizmos.DrawWireSphere(m_bounds.center, m_bounds.extents.magnitude);
            Gizmos.color = Color.red;
            Gizmos.DrawWireSphere(m_bounds.center, 0.5f);

        }


    }
}
