using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ObjectAABB
{
    public Vector3[] m_Corners;

    public Vector3 m_Min;
    public Vector3 m_Max;
    public Vector3 m_Size;
    public Vector3 m_Center;


    public ObjectAABB()
    {
        m_Corners = new Vector3[8];
        m_Min = Vector3.zero;
        m_Max = Vector3.zero;
        m_Size = Vector3.zero;
        m_Center = Vector3.zero;
    }

    public void UpdateAABB(Bounds bounds)
    {
        if (bounds != null)
        {
            m_Min = bounds.max;
            m_Size = bounds.size;
            m_Max = bounds.max;
            m_Center = bounds.center;
            ShadowUtilties.GetObjectAABB(bounds,ref m_Corners);
        }
    }
 

    public void TransformLightSpace(Light light)
    {
        ShadowUtilties.TransformTOLightSpace(light,ref m_Corners,out m_Min,out m_Max,out m_Size);
        var c=new Vector3(m_Min.x+m_Size.x/2,m_Min.y+m_Size.y/2,m_Min.z);
        m_Center = light.transform.TransformPoint(c);

    }
}