using System;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

public delegate float SH_Base(Vector3 v);

public class SphericalHarmonicsBasis
{
    public static float Y0(Vector3 v)
    {
        return 0.2820947917f;
    }

    public static float Y1(Vector3 v)
    {
        return 0.4886025119f * v.y;
    }

    public static float Y2(Vector3 v)
    {
        return 0.4886025119f * v.z;
    }

    public static float Y3(Vector3 v)
    {
        return 0.4886025119f * v.x;
    }

    public static float Y4(Vector3 v)
    {
        return 1.0925484306f * v.x * v.y;
    }

    public static float Y5(Vector3 v)
    {
        return 1.0925484306f * v.y * v.z;
    }

    public static float Y6(Vector3 v)
    {
        return 0.3153915652f * (3.0f * v.z * v.z - 1.0f);
    }

    public static float Y7(Vector3 v)
    {
        return 1.0925484306f * v.x * v.z;
    }

    public static float Y8(Vector3 v)
    {
        return 0.5462742153f * (v.x * v.x - v.y * v.y);
    }

    public static SH_Base[] Eval = { Y0, Y1, Y2, Y3, Y4, Y5, Y6, Y7, Y8 };
}

public class ShCubeLight : MonoBehaviour
{
     public Vector4[] _ShLights;
    public Cubemap cube;

  void OnEnable()
  {
      SetSH();
  }
  

    public void SetSH()
    {
        for (int i = 0; i < _ShLights.Length; ++i)
        {
            Shader.SetGlobalVector("c" + i.ToString(), _ShLights[i]);
        }
    }
    Cubemap RenderCube()
    {
        Camera cam = gameObject.AddComponent<Camera>();
        cam.clearFlags = CameraClearFlags.Skybox;
        cam.farClipPlane = 5000;
        cam.nearClipPlane = 1;
        // cam.cullingMask;
        var cube = new Cubemap(128, TextureFormat.RGB24, false);
        if (cam.RenderToCubemap(cube))
        {
            GameObject.DestroyImmediate(cam);
            return cube;
        }

        return null;
    }

   public void Bake()
    {
       var input = RenderCube();
       cube = input;
       _ShLights = new Vector4[9];

        int sample_count = 4096;
        if (_ShLights.Length != 9)
        {
            Debug.LogWarning("output size must be 9 for 9 coefficients");
            return ;
        }

        //cache the cubemap faces
        List<Color[]> faces = new List<Color[]>();
        
        for (int f = 0; f < 6; ++f)
        {
            faces.Add(input.GetPixels((CubemapFace)f, 0));
        }

        for (int c = 0; c < 9; ++c)
        {
            for (int s = 0; s < sample_count; ++s)
            {
                Vector3 dir = Random.onUnitSphere;
                int index = GetTexelIndexFromDirection(dir, input.height);
                int face = FindFace(dir);

                //read the radiance texel
                Color radiance = faces[face][index];

                //compute shperical harmonic
                float sh = SphericalHarmonicsBasis.Eval[c](dir);

                _ShLights[c].x += radiance.r * sh;
                _ShLights[c].y += radiance.g * sh;
                _ShLights[c].z += radiance.b * sh;
                _ShLights[c].w += radiance.a * sh;
            }

            _ShLights[c].x = _ShLights[c].x * 4.0f * Mathf.PI / (float)sample_count;
            _ShLights[c].y = _ShLights[c].y * 4.0f * Mathf.PI / (float)sample_count;
            _ShLights[c].z = _ShLights[c].z * 4.0f * Mathf.PI / (float)sample_count;
            _ShLights[c].w = _ShLights[c].w * 4.0f * Mathf.PI / (float)sample_count;
        }

        SetSH();

    }
    public  int FindFace(Vector3 dir)
    {
        int f = 0;
        float max = Mathf.Abs(dir.x);
        if (Mathf.Abs(dir.y) > max)
        {
            max = Mathf.Abs(dir.y);
            f = 2;
        }
        if (Mathf.Abs(dir.z) > max)
        {
            f = 4;
        }

        switch (f)
        {
            case 0:
                if (dir.x < 0)
                    f = 1;
                break;

            case 2:
                if (dir.y < 0)
                    f = 3;
                break;

            case 4:
                if (dir.z < 0)
                    f = 5;
                break;
        }

        return f;
    }

    public  int GetTexelIndexFromDirection(Vector3 dir, int cubemap_size)
    {
        float u = 0, v = 0;

        int f = FindFace(dir);
        
        switch (f)
        {
            case 0:
                dir.z /= dir.x;
                dir.y /= dir.x;
                u = (dir.z - 1.0f) * -0.5f;
                v = (dir.y - 1.0f) * -0.5f;
                break;

            case 1:
                dir.z /= -dir.x;
                dir.y /= -dir.x;
                u = (dir.z + 1.0f) * 0.5f;
                v = (dir.y - 1.0f) * -0.5f;
                break;

            case 2:
                dir.x /= dir.y;
                dir.z /= dir.y;
                u = (dir.x + 1.0f) * 0.5f;
                v = (dir.z + 1.0f) * 0.5f;
                break;

            case 3:
                dir.x /= -dir.y;
                dir.z /= -dir.y;
                u = (dir.x + 1.0f) * 0.5f;
                v = (dir.z - 1.0f) * -0.5f;
                break;

            case 4:
                dir.x /= dir.z;
                dir.y /= dir.z;
                u = (dir.x + 1.0f) * 0.5f;
                v = (dir.y - 1.0f) * -0.5f;
                break;

            case 5:
                dir.x /= -dir.z;
                dir.y /= -dir.z;
                u = (dir.x - 1.0f) * -0.5f;
                v = (dir.y - 1.0f) * -0.5f;
                break;
        }

        if (v == 1.0f) v = 0.999999f;
        if (u == 1.0f) u = 0.999999f;

        int index = (int)(v * cubemap_size) * cubemap_size + (int)(u * cubemap_size);

        return index;
    }
}