using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class ShadowCamera1 : MonoBehaviour
{

    Camera m_shadowCamera;
    RenderTexture m_shadowMap;
    float m_far;
    Matrix4x4 m_shadowMatrix;
    // Start is called before the first frame update
    void Start()
    {
        m_shadowCamera = GetComponent<Camera>();
        m_shadowMap = new RenderTexture(2048, 2048, 16, RenderTextureFormat.Shadowmap);
        m_shadowCamera.targetTexture = m_shadowMap;
    }


    


    // Update is called once per frame
    void Update()
    {
      
    }
}
