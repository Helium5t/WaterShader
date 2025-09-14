using UnityEngine;
using UnityEditor;

[RequireComponent(typeof(MeshRenderer))]
public class Waves : MonoBehaviour
{
    [Header("Cubemap Settings")]
    public int cubemapSize = 512;
    public GameObject sourceCamera;
    public string savePath = "Assets/SkyboxCubemap.cubemap";

    public bool debugMode = false;

    // Called by button in inspector
    public void RenderAndSave()
    {
        MeshRenderer mr = GetComponent<MeshRenderer>();
        Material m = mr.sharedMaterial;
        bool createCamera = sourceCamera == null;
        // Create temporary camera
        if (createCamera)
        {
            sourceCamera = new GameObject("CubemapRenderCam", typeof(Camera));
            sourceCamera.hideFlags = HideFlags.HideAndDontSave;
        }
        Camera renderCam = sourceCamera.GetComponent<Camera>();
        renderCam.enabled = false;

        // Create cubemap
        Cubemap cubemap = new Cubemap(cubemapSize, TextureFormat.RGBA32, false);

        // Render skybox into cubemap
        renderCam.transform.position = Vector3.zero; // Skybox is global, so position doesn’t matter
        renderCam.clearFlags = CameraClearFlags.Skybox;
        renderCam.cullingMask = 0; // don’t render any objects
        renderCam.RenderToCubemap(cubemap);
        m.SetTexture("_CubemapTex", cubemap);
        // Save to project
        AssetDatabase.CreateAsset(cubemap, savePath);
        AssetDatabase.SaveAssets();

        Debug.Log($"Skybox cubemap saved to {savePath}");
        if (createCamera)
        {
            DestroyImmediate(sourceCamera);
        }
    }

    public void CheckDebug()
    {
        MeshRenderer mr = GetComponent<MeshRenderer>();
        Material m = mr.sharedMaterial;
        if (!debugMode)
        {
            m.DisableKeyword("DEBUG_MODE");
            return;
        }
        m.EnableKeyword("DEBUG_MODE");
    }
}