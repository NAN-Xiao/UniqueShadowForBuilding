using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class UniqueShadowCamera : MonoBehaviour
{
   /// <summary>
    /// 当前摄像机
    /// </summary>
    private Camera m_Camera;
 
    /// <summary>
    /// 抗锯齿材质球（后处理用）
    /// </summary>
    public Material ssaa;
 
    /// <summary>
    /// 在天空盒渲染之后保存的图片id（就是特效渲染之前）
    /// </summary>
    private static int m_AfterSkyboxTexId = Shader.PropertyToID("_AfterSkyboxTex");
 
    /// <summary>
    /// 深度图id
    /// </summary>
    private static int m_DepthTexId = Shader.PropertyToID("_DepthTex");
 
    /// <summary>
    /// 在天空盒渲染之后保存的图片（就是特效渲染之前）
    /// </summary>
    public RenderTexture m_AfterSkyboxTex;
 
    /// <summary>
    /// 用于存储深度
    /// </summary>
    public RenderTexture m_depthBufferTex;
 
    /// <summary>
    /// 深度图
    /// </summary>
    public RenderTexture m_DepthTex;
 
    /// <summary>
    /// 当前摄像机渲染最终的图片
    /// </summary>
    private RenderTexture m_CameraRenderTex;
 
    /// <summary>
    /// 在渲染天空盒之后的commandbuff指令
    /// </summary>
    private CommandBuffer m_AfterSkyboxCommandBuffer;
 
    /// <summary>
    /// 处理深度图的commandbuff指令
    /// </summary>
    private CommandBuffer m_DepthBuffer;
 
    private void OnEnable()
    {
        m_Camera = GetComponent<Camera>();
        Init();
    }
 
    private void Init()
    {
        ///rendertargetbuffer///////////////
        //屏幕渲染图
        m_CameraRenderTex = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.Default, RenderTextureReadWrite.Default);
        //////////////////////////////////////////////////////////////////////////////////////////
        //存储深度
        m_depthBufferTex = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth);
        m_depthBufferTex.name = "DepthBuffer";
 
        //深度图
        m_DepthTex = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RHalf);
        m_DepthTex.name = "DepthTex";
 
        //添加处理深度图commandbuffer
        m_DepthBuffer = new CommandBuffer();
        m_DepthBuffer.name = "CommandBuffer_DepthBuffer";
        //把depthbuffer写入m_DepthTex的colorbuffer
        //把depthbuffer合成一张rt和自带的是重新渲染一张rt效果一样
        //我这里定义rt全局id为_DepthTex，shader直接获取这个就可以使用自定义深度图
        m_DepthBuffer.Blit(m_depthBufferTex.depthBuffer, m_DepthTex.colorBuffer);
        m_Camera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, m_DepthBuffer);
        //设置shader全局深度图
        Shader.SetGlobalTexture(m_DepthTexId, m_DepthTex);
 
 
        //半透渲染前的commandbuffer
        m_AfterSkyboxTex = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.Default);
        m_AfterSkyboxTex.name = "AfterSkyboxTex";
        m_AfterSkyboxCommandBuffer = new CommandBuffer();
        m_AfterSkyboxCommandBuffer.name = "AfterSkyBox_CommandBuffer";
        //buffer之类把当前渲染出来的图片保存到m_AfterSkyboxTex
        m_AfterSkyboxCommandBuffer.Blit(BuiltinRenderTextureType.CurrentActive, m_CameraRenderTex);
        //设置摄像机触发commandbuffer时机
        m_Camera.AddCommandBuffer(CameraEvent.AfterSkybox, m_AfterSkyboxCommandBuffer);
        //设置shader全局图片，方便给扭曲效果用
        Shader.SetGlobalTexture(m_AfterSkyboxTexId, m_AfterSkyboxTex);
    }
 
    private void OnPreRender()
    {
        m_Camera.SetTargetBuffers(m_CameraRenderTex.colorBuffer, m_depthBufferTex.depthBuffer);
        }

}
