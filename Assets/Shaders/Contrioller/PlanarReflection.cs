using System;
using System.Collections.Generic;
using UnityEngine;

public enum RefQuality
{
    verylow = 4,
    low = 3,
    middle = 2,
    height = 1,
    veryheight = 0

}

[ExecuteInEditMode]
public class PlanarReflection : MonoBehaviour
{

    public RefQuality _quality;
    [Range(0, 1f)]
    public float BlurRadius;
    public LayerMask masks;

    private RefQuality m_Quality;
    [HideInInspector]
    private Camera reflectionCamera = null;
    private RenderTexture reflectionRT = null;
    private RenderTexture reflectionRT_Temp = null;
    private static bool isReflectionCameraRendering = false;
    private Material reflectionMaterial = null;

    public Shader m_PbrReplaceShader;

    private Material m_guassMaterial;


    void OnDisable()
    {
        if (reflectionCamera != null)
        {
            reflectionCamera.targetTexture = null;
            GameObject.DestroyImmediate(reflectionCamera.gameObject);
        }
        if (reflectionRT != null)
        {
            RenderTexture.ReleaseTemporary(reflectionRT);
        }
        m_PbrReplaceShader = null;
    }
    //   bool _Dirty;
    private void OnWillRenderObject()
    {
        if (isReflectionCameraRendering) return;
        isReflectionCameraRendering = true;
        if (reflectionCamera == null)
        {
            var go = new GameObject("Reflection Camera");
            reflectionCamera = go.AddComponent<Camera>();
            reflectionCamera.CopyFrom(Camera.current);

        }/*  */
        if (m_PbrReplaceShader == null)
        {
            m_PbrReplaceShader = Shader.Find("Faster/PBR/Replace");
        }
        reflectionCamera.SetReplacementShader(m_PbrReplaceShader, "Replace");
        if (reflectionRT == null || m_Quality != _quality)
        {
            m_Quality = _quality;
            int q = 1;

            switch (m_Quality)
            {
                case RefQuality.verylow:
                    q = 16;
                    break;
                case RefQuality.low:
                    q = 8;
                    break;
                case RefQuality.middle:
                    q = 4;
                    break;
                case RefQuality.height:
                    q = 2;
                    break;
                case RefQuality.veryheight:
                    q = 1;

                    break;
            }
            RenderTexture.ReleaseTemporary(reflectionRT);
            reflectionRT = RenderTexture.GetTemporary(Screen.width / q, Screen.height / q, 24);
        }

        UpdateCamearaParams(Camera.current, reflectionCamera);
        reflectionCamera.targetTexture = reflectionRT;
        reflectionCamera.enabled = false;

        var reflectM = CaculateReflectMatrix(transform.up, transform.position);
        reflectionCamera.worldToCameraMatrix = Camera.current.worldToCameraMatrix * reflectM;
        GL.invertCulling = true;
        reflectionCamera.Render();
        GL.invertCulling = false;

        if (reflectionMaterial == null)
        {
            var renderer = GetComponent<Renderer>();
            reflectionMaterial = renderer.sharedMaterial;

        }
        GuassBlur(ref reflectionRT);
        reflectionMaterial.SetTexture("_ReflectionTex", reflectionRT);

        isReflectionCameraRendering = false;

    }

    void GuassBlur(ref RenderTexture rt)
    {

        if (m_guassMaterial == null)
        {
            var s = Shader.Find("Hidden/GaussBlur");
            if (s == null)
            {
                Debug.LogError("Hidden/GaussBlur shader is not finded");
                return;
            }
            else
            {
                m_guassMaterial = new Material(s);
            }
        }
        if (m_guassMaterial)
        {
            if (reflectionRT_Temp == null)
                reflectionRT_Temp = RenderTexture.GetTemporary(rt.descriptor);
            m_guassMaterial.SetFloat("_BlurRadius", BlurRadius);
            for (int i = 0; i < (int)m_Quality; i++)
            {
                Graphics.Blit(rt, reflectionRT_Temp, m_guassMaterial, 0);
                Graphics.Blit(reflectionRT_Temp, rt, m_guassMaterial, 1);
            }
        }

    }
    Matrix4x4 CaculateReflectMatrix(Vector3 normal, Vector3 positionOnPlane)
    {
        var d = -Vector3.Dot(normal, positionOnPlane);
        var reflectM = new Matrix4x4();
        reflectM.m00 = 1 - 2 * normal.x * normal.x;
        reflectM.m01 = -2 * normal.x * normal.y;
        reflectM.m02 = -2 * normal.x * normal.z;
        reflectM.m03 = -2 * d * normal.x;

        reflectM.m10 = -2 * normal.x * normal.y;
        reflectM.m11 = 1 - 2 * normal.y * normal.y;
        reflectM.m12 = -2 * normal.y * normal.z;
        reflectM.m13 = -2 * d * normal.y;

        reflectM.m20 = -2 * normal.x * normal.z;
        reflectM.m21 = -2 * normal.y * normal.z;
        reflectM.m22 = 1 - 2 * normal.z * normal.z;
        reflectM.m23 = -2 * d * normal.z;

        reflectM.m30 = 0;
        reflectM.m31 = 0;
        reflectM.m32 = 0;
        reflectM.m33 = 1;
        return reflectM;
    }

    private void UpdateCamearaParams(Camera srcCamera, Camera destCamera)
    {
        if (destCamera == null || srcCamera == null)
            return;

        destCamera.clearFlags = srcCamera.clearFlags;
        destCamera.backgroundColor = srcCamera.backgroundColor;
        destCamera.farClipPlane = srcCamera.farClipPlane;
        destCamera.nearClipPlane = srcCamera.nearClipPlane;
        destCamera.orthographic = srcCamera.orthographic;
        destCamera.fieldOfView = srcCamera.fieldOfView;
        destCamera.aspect = srcCamera.aspect;
        destCamera.orthographicSize = srcCamera.orthographicSize;
        destCamera.depth = destCamera.depth - 1;
    }


}
