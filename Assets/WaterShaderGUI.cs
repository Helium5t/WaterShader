
using UnityEditor;
using UnityEngine;

public class WaterShaderGUI : ShaderGUI
{
    Material target;
    MaterialEditor editor;
    MaterialProperty[] properties;
    static GUIContent staticLabel = new GUIContent();

    int waveNumber = 1;
    enum WaveGeneration
    {
        Static,
        FractalBrownianMotion
    }

    enum WaveNumber
    {
        Compile,
        Runtime
    }
    WaveNumber waveNumSelection = WaveNumber.Compile;
    WaveGeneration generationType = WaveGeneration.FractalBrownianMotion;

    static bool debugMode = false;
    public override void OnGUI(
        MaterialEditor editor, MaterialProperty[] properties
    )
    {
        this.target = editor.target as Material;
        this.editor = editor;
        this.properties = properties;
        DoMain();
    }

    void DoMain()
    {
        MaterialProperty mainTex = FindProperty("_MainTex");
        MaterialProperty baseColor = FindProperty("_BaseColor");
        editor.TexturePropertySingleLine(MakeLabel(mainTex, "Diffuse Texture (RGB)"), mainTex, baseColor);
        MaterialProperty specularColor = FindProperty("_SpecularColor");
        editor.ColorProperty(specularColor, "Specular");
        MaterialProperty ambientCubemap = FindProperty("_CubemapTex");
        editor.TextureProperty(ambientCubemap, "Ambient Cubemap");
        MaterialProperty specularSharpness = FindProperty("_SpecularSharpness");
        editor.FloatProperty(specularSharpness, "Reflection Sharpness");
        MaterialProperty normalAtt = FindProperty("_NormalContrast");
        editor.FloatProperty(normalAtt, "Normal Contrast");
        MaterialProperty waveSize = FindProperty("_WaveSize");
        editor.FloatProperty(waveSize, "Wave Size");
        MaterialProperty displacement = FindProperty("_DisplacementScale");
        editor.FloatProperty(displacement, "Displacement Scale");
        generationType = (WaveGeneration)EditorGUILayout.EnumPopup(MakeLabel("Wave Generation Method"), generationType);
        if (generationType == WaveGeneration.FractalBrownianMotion)
        {
            ShowFractalBrownianUI();
        }
        debugMode = EditorGUILayout.Toggle("Debug", debugMode);
        if (debugMode)
        {
            target.EnableKeyword("DEBUG_MODE");
            ShowDebugUI();
        }
        else
        {
            target.DisableKeyword("DEBUG_MODE");
        }
        

    }

    void ShowFractalBrownianUI()
    {
        MaterialProperty amplitude = FindProperty("_StartingAmplitude");
        editor.FloatProperty(amplitude, "Starting Amplitude");
        MaterialProperty lacunarity = FindProperty("_BrownianLacunarity");
        EditorGUI.BeginChangeCheck();
        int lacunarityV =EditorGUILayout.IntSlider("Lacunarity", lacunarity.intValue, 1, 12);
        if (EditorGUI.EndChangeCheck())
        {
            lacunarity.intValue = lacunarityV;
        }
        float h = editor.GetPropertyHeight(lacunarity);

        waveNumSelection = (WaveNumber)EditorGUILayout.EnumPopup(MakeLabel("Wave Number"), waveNumSelection);
        
        if (waveNumSelection == WaveNumber.Runtime)
        {
            target.EnableKeyword("DYNAMIC_WAVE_NUM");
            MaterialProperty wn = FindProperty("_WaveNumber");
            EditorGUI.BeginChangeCheck();
            int intV = EditorGUILayout.IntSlider("Wave Number", wn.intValue, 1, 64);
            if (EditorGUI.EndChangeCheck())
            {
                wn.intValue = intV;
            }
        }
        else
        {
            target.DisableKeyword("DYNAMIC_WAVE_NUM");
        }
    }

    void ShowDebugUI()
    {
        MaterialProperty dt = FindProperty("_DebugTime");
        EditorGUI.BeginChangeCheck();
        float debugTime = EditorGUILayout.Slider("Wave Progression",dt.vectorValue.x,1f,1000f);
        if (EditorGUI.EndChangeCheck())
        {
            dt.floatValue = debugTime;
            dt.vectorValue = new Vector2(debugTime, debugTime);
        }
    }


    MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, properties);
    }

    GUIContent MakeLabel (
		MaterialProperty property, string tooltip = null
	) {
		staticLabel.text = property.displayName;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}
    GUIContent MakeLabel (string text, string tooltip = null) {
		staticLabel.text = text;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}
}