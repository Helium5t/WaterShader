
using UnityEditor;
using UnityEngine;

public class WaterShaderGUI : ShaderGUI
{
    protected Material target;
    protected MaterialEditor editor;
    protected MaterialProperty[] properties;
    static GUIContent staticLabel = new GUIContent();

    int waveNumber = 1;
    enum WaveGeneration
    {
        Static,
        FractalBrownianMotion
    }

    enum HeightFunction
    {
        ExponentialSine
    }

    enum WaveNumber
    {
        Compile,
        Runtime
    }
    enum SeedMode
    {
        Dynamic,
        Static
    }
    WaveNumber waveNumSelection = WaveNumber.Compile;
    WaveGeneration generationType = WaveGeneration.FractalBrownianMotion;
    HeightFunction heightFunction = HeightFunction.ExponentialSine;
    SeedMode seedMode = SeedMode.Static;

    string[] defaultUIParameters = {
        "_SpecularStrength",
        "_SpecularSharpness",
        "_AmbientColor",
        "_CubemapTex",
        "_FoamBaseColor",
        "_FoamFactorHeight",
        "_FoamSharpnessHeight",
        "_FoamFactorAngle",
        "_FoamSharpnessAngle",
        "_NormalContrast",
        "_FoamSpecularFactor",
        "_BaseAmplitude",
        "_BasePhase",
        "_BaseFrequency",
        "_PhaseRampMultiplier",
        "_AmplitudeRampMultiplier",
        "_FrequencyRampMultiplier",
        "_WaveSize",
        "_DisplacementScale",
        "_MinHeightRemap",
        "_MaxHeightRemap",
    };

    string[] expSineParameters = {
        "_MaxExpMultiplier",
        "_ExpOffset",
    };

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

    protected void DoMain()
    {
        MaterialProperty mainTex = FindProperty("_MainTex");
        MaterialProperty baseColor = FindProperty("_BaseColor");
        editor.TexturePropertySingleLine(MakeLabel("Diffuse Texture"), mainTex, mainTex.textureValue ? null : baseColor);
        if (mainTex.textureValue)
        {
            target.EnableKeyword("DIFFUSE_TEXTURE");
        }
        else
        {
            target.DisableKeyword("DIFFUSE_TEXTURE");
        }
        MaterialProperty specularColor = FindProperty("_SpecularColor");
        editor.ColorProperty(specularColor, "Specular");
        ShowDefaultUI(defaultUIParameters);
        MaterialProperty cubemapTexture = FindProperty("_CubemapTex");
        if (cubemapTexture.textureValue)
        {
            target.EnableKeyword("SPECULAR_CUBEMAP");
        }
        else
        {
            target.DisableKeyword("SPECULAR_CUBEMAP");
        }

        heightFunction = (HeightFunction)EditorGUILayout.EnumPopup(MakeLabel("Height Function"), heightFunction);
        if (heightFunction == HeightFunction.ExponentialSine)
        {
            ShowDefaultUI(expSineParameters);
        }


        generationType = (WaveGeneration)EditorGUILayout.EnumPopup(MakeLabel("Wave Generation Method"), generationType);
        if (generationType == WaveGeneration.FractalBrownianMotion)
        {
            ShowFractalBrownianUI();
        }
        else
        {
            DisableAllFBMKeywords();
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

    void DisableAllFBMKeywords()
    {
        target.DisableKeyword("DYNAMIC_SEED");
        target.DisableKeyword("DYNAMIC_WAVE_NUM");
    }
    void ShowFractalBrownianUI()
    {
        seedMode = (SeedMode)EditorGUILayout.EnumPopup(MakeLabel("Seed Mode"), seedMode);
        if (seedMode == SeedMode.Dynamic)
        {
            target.EnableKeyword("DYNAMIC_SEED");
            MaterialProperty m = FindProperty("_Seed");
            editor.DefaultShaderProperty(m, m.displayName);
        }
        else
        {
            target.DisableKeyword("DYNAMIC_SEED");
        }
        MaterialProperty amplitude = FindProperty("_BaseAmplitude");
        editor.FloatProperty(amplitude, "Starting Amplitude");
        MaterialProperty lacunarity = FindProperty("_BrownianLacunarity");
        EditorGUI.BeginChangeCheck();
        int lacunarityV = EditorGUILayout.IntSlider("Lacunarity", lacunarity.intValue, 1, 12);
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
        float debugTime = EditorGUILayout.Slider("Wave Progression", dt.vectorValue.x, 1f, 1000f);
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

    protected GUIContent MakeLabel(
        MaterialProperty property, string tooltip = null
    )
    {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }
    protected GUIContent MakeLabel(string text, string tooltip = null)
    {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    protected void ShowDefaultUI(string[] ps) {
        foreach (var p in ps)
        {
            MaterialProperty m = FindProperty(p);
            editor.DefaultShaderProperty(m, m.displayName);
        }
    }
}