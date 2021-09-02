using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

public enum FilterType
{
    PCF = 0,
    ESM,
    VSM,
}

public enum ShadowMapRes
{
    Low = 0,
    Middle,
    High
}

public class UniqueShadow : MonoBehaviour
{
    //private
    private Camera m_shadowCamera;
    private Bounds m_bounds;
    private List<Renderer> m_renders;
    private float m_radius;
    private List<Material> m_mts;
    private Matrix4x4 m_shadowMatrix;
    private Material m_depthCopy;
    private int m_shadowMapSize = 2048;

    private ShadowMapRes m_curQuality;

    //all render target;
    [SerializeField] private RenderTexture m_renderTarget;
    [SerializeField] private RenderTexture m_shadowMap_template;
    [SerializeField] private RenderTexture m_shadowMap;

    private RenderTextureDescriptor m_descriptor;

    //public
    public FilterType ShadwoFilterType;
    public ShadowMapRes ShadwoQuality = ShadowMapRes.Middle;
    public Light m_shadowLight;
    public float m_softFactor = 2.0f;
    public float _far = 1.0f;
    [Range(0f, 0.01f)] public float m_bias = 0.002f;
    [Range(0f, 1.0f)] public float strength = 1.0f;
    public float m_blur2Copy;
    public float m_VSMMin = 1;

    public float m_ESMConst = 10.0f;

    //counst shader proerti
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
        NewCamera();
        GatherRendersInfo();
    }

    void Update()
    {
        UpdateBounds();
        UpdateCamera();
    }

    void UpdateCamera()
    {
        UpdateMatrix();
        m_shadowCamera.Render();

        InspectionShadowMap();
        switch (ShadwoFilterType)
        {
        
            case FilterType.ESM:
                m_depthCopy.SetFloat(_BLURSIZE, m_blur2Copy);
                m_depthCopy.SetFloat("_MainTex_TexelSize", m_shadowMapSize);
                m_depthCopy.SetFloat(_ESMConst, m_ESMConst);
                Graphics.Blit(m_renderTarget, m_shadowMap, m_depthCopy, 2);
                break;
            case FilterType.VSM:
                // CheckShadowMap();
                m_depthCopy.SetFloat(_BLURSIZE, m_blur2Copy);
                m_depthCopy.SetFloat("_MainTex_TexelSize", m_shadowMapSize);
                Graphics.Blit(m_renderTarget, m_shadowMap_template, m_depthCopy, 1);
                Graphics.Blit(m_shadowMap_template, m_shadowMap, m_depthCopy, 0);
                break;
        }
        UpdateUniforms();
    }

    void UpdateMatrix()
    {
        if (null == m_shadowLight)
        {
            Debug.LogError("no set any main shadow light");
            return;
        }

        m_shadowCamera.transform.position = m_bounds.center - m_shadowLight.transform.forward * (m_radius + _far);
        m_shadowCamera.transform.rotation = m_shadowLight.transform.rotation;
        m_shadowCamera.orthographicSize = m_radius;
        m_shadowCamera.farClipPlane = Vector3.Distance(m_shadowCamera.transform.position, m_bounds.center) + m_radius;
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
    }

    /// <summary>
    /// 更新阴影设置
    /// </summary>
    void UpdateUniforms()
    {
        for (int i = 0, n = m_mts.Count; i < n; ++i)
        {
            var m = m_mts[i];
            m.EnableKeyword(UNIQUE_SHADOW);
            switch (ShadwoFilterType)
            {
                
                case FilterType.ESM:
                    m.SetFloat(_ESMConst, m_ESMConst);
                    m.SetTexture(_UniqueShadowTexture, m_shadowMap);
                    break;
                case FilterType.VSM:
                    m.SetFloat("_VSMMin", m_VSMMin);
                    m.SetTexture(_UniqueShadowTexture, m_shadowMap);
                    break;
                default:
                    m.SetTexture(_UniqueShadowTexture, m_renderTarget);
                    break;
            }
            m.SetMatrix(_UniqueShadowMatrix, m_shadowMatrix);
            m.SetFloat(_UniqueShadowStrength, Mathf.Clamp01(strength));
            m.SetFloat(_UniqueShadowMapSize, m_shadowMapSize);
            m.SetFloat(_UniqueShadowFilterWidth, m_softFactor / m_shadowMapSize);
        }
    }

    void UpdateBounds()
    {
        if (m_renders == null||m_renders.Count<=0)
        {
            return;
        }
        m_bounds = new Bounds(transform.position, Vector3.one * 0.1f);
        foreach (var m in m_renders)
        {
            if (m.gameObject.activeSelf)
            {
                m_bounds.Encapsulate(m.bounds);
            }
        }
        m_radius = m_bounds.extents.magnitude;
    }

    void NewCamera()
    {
        if (m_shadowCamera == null)
        {
            m_shadowCamera = new GameObject("_UniqueShadow").AddComponent<Camera>();
        }

        m_shadowCamera.clearFlags = CameraClearFlags.Depth;
        m_shadowCamera.depthTextureMode = DepthTextureMode.Depth;
        m_shadowCamera.useOcclusionCulling = false;
        m_shadowCamera.orthographic = true;
        m_shadowCamera.depth = -1000;
        m_shadowCamera.aspect = 1f;
        //  m_shadowCamera.gameObject.hideFlags = HideFlags.HideInHierarchy;
        //   m_shadowCamera.enabled=false;
        if (m_renderTarget == null)
        {
            m_renderTarget = RenderTexture.GetTemporary(m_shadowMapSize, m_shadowMapSize, 16, RenderTextureFormat.Depth);
            m_renderTarget.filterMode = FilterMode.Point;
            m_renderTarget.wrapMode = TextureWrapMode.Clamp;
        }

        m_shadowCamera.targetTexture = m_renderTarget;
    }

    void InitMaterial()
    {
        if (m_depthCopy == null)
        {
            m_depthCopy = new Material(Shader.Find(DepthCopy));
            if (m_depthCopy == null)
            {
                Debug.LogError("copydepth material is null");
            }
        }
    }


    void InspectionShadowMap()
    {
//        if (m_curQuality != ShadwoQuality || m_shadowMap == null || ShadwoFilterType != FilterType.PCF)
//        {
//            ReCreatShadowMap();
//            m_curQuality = ShadwoQuality;
//            return;
//        }
        if (m_shadowMap_template != null) RenderTexture.ReleaseTemporary(m_shadowMap_template);
        if (m_shadowMap != null) RenderTexture.ReleaseTemporary(m_shadowMap);
    }

    void ReCreatShadowMap()
    {
        if (m_renderTarget==null)
        {
            return;
        }
        
        m_descriptor = m_renderTarget.descriptor;
        if (ShadwoQuality == ShadowMapRes.High)
        {
            m_descriptor.colorFormat = RenderTextureFormat.RGFloat;
        }
        else
        {
            m_descriptor.colorFormat = RenderTextureFormat.RGHalf;
        }

        m_shadowMap_template = RenderTexture.GetTemporary(m_descriptor);
        m_shadowMap = RenderTexture.GetTemporary(m_descriptor);
    }

    //初始化材质和mesh
    void GatherRendersInfo()
    {
        InitMaterial();
        m_renders = transform.GetComponentsInChildren<Renderer>().ToList();
        m_mts = new List<Material>();
        foreach (var r in m_renders)
        {
            if (r.gameObject.active == false)
            {
                continue;
            }

            var mt = r.sharedMaterials;
            foreach (var m in mt)
            {
                if (m_mts.Contains(m)) continue;
                m_mts.Add(m);
            }
        }
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


    private void OnDisable()
    {
        if (m_renderTarget != null) RenderTexture.ReleaseTemporary(m_renderTarget);
        if (m_shadowMap != null) RenderTexture.ReleaseTemporary(m_shadowMap);
        if (m_shadowMap_template != null) RenderTexture.ReleaseTemporary(m_shadowMap_template);
        for (int i = 0, n = m_mts.Count; i < n; ++i)
        {
            var m = m_mts[i];
            m.DisableKeyword(UNIQUE_SHADOW);
        }
    }
}