using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PlaneShadow : MonoBehaviour
{
    public Color shadowColor=new Color(0,0,0,0.3f);
    public float _ShadowFalloff=0.0f;
    public float _upwardShift=0.01f;

    private Color m_shadowColor;
    private float m_ShadowFalloff;
    private float m_upwardShift;
    private void OnEnable()
    {
        m_shadowColor = shadowColor;
        m_ShadowFalloff = _ShadowFalloff;
        m_upwardShift = _upwardShift;

        Shader.SetGlobalColor("_ShadowColor", m_shadowColor);
        Shader.SetGlobalFloat("_ShadowFalloff", m_ShadowFalloff);
        Shader.SetGlobalFloat("_UpwardShift", m_upwardShift);
    }

#if UNITY_EDITOR
    private void Update()
    {
      

        if(m_shadowColor!=shadowColor)
        {
           m_shadowColor = shadowColor;
            Shader.SetGlobalColor("_ShadowColor", m_shadowColor);
           
        }
        if(m_ShadowFalloff!= _ShadowFalloff)
        {
            m_ShadowFalloff = _ShadowFalloff;
            Shader.SetGlobalFloat("_ShadowFalloff", m_ShadowFalloff);
           
        }
        if(m_upwardShift!=_upwardShift)
        {
            m_upwardShift = _upwardShift;
            Shader.SetGlobalFloat("_UpwardShift", m_upwardShift);
        }
    }
#endif
}
