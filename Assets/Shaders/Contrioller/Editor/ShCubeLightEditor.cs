using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(ShCubeLight))]
public class ShCubeLightEditor : Editor
{

    private bool showSH=false;
    private bool showCube;
    public override void OnInspectorGUI()
    {

        ShCubeLight com = target as ShCubeLight;
        if (com==null)
        {
            return;
        }

        if (GUILayout.Button("Bake"))
        {
            com.Bake();
        }
       

        showSH = EditorGUILayout.Toggle("Show Sh:",showSH);
        showCube = EditorGUILayout.Toggle("Show Cube:",showCube);

        //GUILayout.
       
        if (showSH)
        {
            EditorGUILayout.BeginVertical();
            foreach (var l in com._ShLights)
            {
                EditorGUILayout.Vector4Field("coefs",l);
            }
            EditorGUILayout.EndVertical();
        }

        if (showCube)
        {

            EditorGUILayout.ObjectField("Cube",com.cube,typeof(Cubemap),false);
        }
    }
}