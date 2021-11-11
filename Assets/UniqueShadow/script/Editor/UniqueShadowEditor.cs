using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(UniqueShadowManager))]
public class UniqueShadowEditor : Editor
{
    private UniqueShadowManager _target;
    private void OnEnable()
    {
        _target = base.target as UniqueShadowManager;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (_target.m_ShadowRT != null&&_target.m_ShadowRT.format!=RenderTextureFormat.Shadowmap)
        {
            EditorGUI.DrawPreviewTexture(GUILayoutUtility.GetAspectRect((float)_target.m_ShadowRT.width / _target.m_ShadowRT.height), _target.m_ShadowRT);
        }
        if (_target.m_depthTex != null)
        {
            GUILayout.Label("CameraDepthTex:");
            EditorGUI.DrawPreviewTexture(GUILayoutUtility.GetAspectRect((float)_target.m_depthTex.width / _target.m_depthTex.height), _target.m_depthTex);
        }
        if (_target.m_collectTex != null)
        {
            EditorGUILayout.Space(10);
            GUILayout.Label("CollectShadowTex:");
            EditorGUI.DrawPreviewTexture(GUILayoutUtility.GetAspectRect((float)_target.m_collectTex.width / _target.m_collectTex.height), _target.m_collectTex);
        }
    }
}
