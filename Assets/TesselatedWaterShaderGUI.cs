
using UnityEditor;
using UnityEngine;

public class TessellatedWaterShaderGUI : WaterShaderGUI
{

    enum TessellationMode
    {
        Fixed,
        EdgeBased,
        DistanceBased,
        HeightFunctionBased,
    }

    TessellationMode tessMode;

    string[] edgeBasedParameters = {
        "_TargetEdgeLen",
    };

    string[] distanceBasedParameters = {
        "_MinDistTessellation",
        "_MaxDistTessellation",
    };

    string[] fixedParameters = {
        "_Subdivs",
    };
    string[] heightFunctionBasedParameters = {
        "_Subdivs",
        "_PhongTesselationFactor",
        "_MinDistTessellation",
        "_MaxDistTessellation",
        "_MinEdgeTesselation",
        "_MaxEdgeTesselation"
    };

    string[] tessModeKeywords =
    {
        "EDGE_BASED_TESSELLATION",
        "DISTANCE_BASED_TESSELLATION",
        "HEIGHT_FUNCTION_BASED_TESSELATION",
    };

    public override void OnGUI(
           MaterialEditor editor, MaterialProperty[] properties
       )
    {
        this.target = editor.target as Material;
        this.editor = editor;
        this.properties = properties;
        if (tessMode == TessellationMode.Fixed)
        {
            CheckTessellationMode();
        }
        tessMode = (TessellationMode)EditorGUILayout.EnumPopup(MakeLabel("Tessellation Mode"), tessMode);
        DisableAllTessellationKeywords();
        if (tessMode == TessellationMode.EdgeBased)
        {
            target.EnableKeyword("EDGE_BASED_TESSELLATION");
            ShowDefaultUI(edgeBasedParameters);
        }
        else if (tessMode == TessellationMode.DistanceBased)
        {
            target.EnableKeyword("DISTANCE_BASED_TESSELLATION");
            ShowDefaultUI(distanceBasedParameters);
        }
        else if (tessMode == TessellationMode.HeightFunctionBased)
        {
            target.EnableKeyword("HEIGHT_FUNCTION_BASED_TESSELATION");
            ShowDefaultUI(heightFunctionBasedParameters);
        }
        else
        {
            ShowDefaultUI(fixedParameters);
        }
        DoMain();
        ValidateValues();

    }

    void ValidateValues()
    {
        float minDist = target.GetFloat("_MinDistTessellation");
        target.SetFloat("_MinDistTessellation", Mathf.Clamp(minDist, 0f, target.GetFloat("_MaxDistTessellation")));

        float minEdge = target.GetFloat("_MinEdgeTesselation");
        target.SetFloat("_MinEdgeTesselation", Mathf.Clamp(minEdge, 0f, target.GetFloat("_MaxEdgeTesselation")));
        float subdivs = target.GetFloat("_Subdivs");
        target.SetFloat("_Subdivs", Mathf.Max(subdivs, 0.01f));
    }

    void DisableAllTessellationKeywords()
    {
        foreach (var s in tessModeKeywords)
        {
            target.DisableKeyword(s);
        }
        
    }

    void CheckTessellationMode()
    {
        for (int i = 0; i < tessModeKeywords.Length; i++)
        {
            if (target.IsKeywordEnabled(tessModeKeywords[i]))
            {
                tessMode = (TessellationMode)i+1;
                return;
            }
            tessMode = TessellationMode.Fixed;
        }
    }
}