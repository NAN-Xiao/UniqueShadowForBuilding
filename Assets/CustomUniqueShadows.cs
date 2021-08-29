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

    float m_far;

    float m_radius;
    //public

    public Light m_shadowLight;

    public int m_shadowMapSize = 2048;
    public RenderTexture m_shadowMap;

    public float orthographicSize;

    List<Material> m_mts;

    Matrix4x4 m_shadowMatrix;
    float m_shadowFilterWidth=10;


    private float m_bias;

    const string UNIQUE_SHADOW = "UNIQUE_SHADOW";
    const string _UniqueShadowMatrix = "_UniqueShadowMatrix";
    const string _UniqueShadowFilterWidth = "_UniqueShadowFilterWidth";
    const string _UniqueShadowTexture = "_UniqueShadowTexture";
    // Start is called before the first frame update
    void Start()
    {
        //test
        InitCamera();
        GetRenderTarget();

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

        m_shadowFilterWidth /= m_shadowMapSize;
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
        m_shadowCamera.transform.position = m_bounds.center - m_shadowLight.transform.forward * m_radius;
        m_shadowCamera.transform.rotation = m_shadowLight.transform.rotation;
        m_shadowCamera.orthographicSize = m_radius;
        m_shadowCamera.farClipPlane = Vector3.Distance(m_shadowCamera.transform.position, m_bounds.center) + m_radius;

        var shadowProjection = Matrix4x4.Ortho(-m_radius, m_radius, -m_radius, m_radius, m_shadowCamera.nearClipPlane, m_shadowCamera.farClipPlane);

        m_bias = m_shadowLight.shadowBias;
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

        SetUniforms();
    }
    void SetUniforms()
    {
        for (int i = 0, n = m_mts.Count; i < n; ++i)
        {
            var m = m_mts[i];
            m.EnableKeyword(UNIQUE_SHADOW);
            m.SetMatrix(_UniqueShadowMatrix, m_shadowMatrix);
            m.SetFloat(_UniqueShadowFilterWidth, m_shadowFilterWidth);
            m.SetTexture(_UniqueShadowTexture, m_shadowMap);
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
            m_shadowMap.filterMode = FilterMode.Point;
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


        if (m_bounds != null)
        {

            Gizmos.DrawWireSphere(m_bounds.center, m_bounds.extents.magnitude);
            Gizmos.color = Color.red;
            Gizmos.DrawWireSphere(m_bounds.center, 0.5f);

        }


    }
}
