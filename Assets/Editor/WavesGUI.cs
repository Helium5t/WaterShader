using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(Waves))]
public class WavesGUI : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        Waves script = (Waves)target;
        script.CheckDebug();
        if (GUILayout.Button("Render and Save Cubemap"))
        {
            script.RenderAndSave();
        }
    }
}
