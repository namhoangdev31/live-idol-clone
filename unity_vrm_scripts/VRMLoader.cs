using UnityEngine;
using UniGLTF;
using VRM;
using System.IO;

/// <summary>
/// Loads and initializes a VRM avatar from file
/// </summary>
public class VRMLoader : MonoBehaviour
{
    [Header("VRM Settings")]
    public string vrmFilePath = "avatar.vrm";
    
    [Header("Camera Settings")]
    public float cameraDistance = 1.5f;
    public Vector3 cameraOffset = new Vector3(0, 1.4f, 0);
    
    private GameObject vrmInstance;
    private Camera mainCamera;
    
    void Start()
    {
        SetupCamera();
        LoadVRM();
    }
    
    void SetupCamera()
    {
        mainCamera = Camera.main;
        if (mainCamera == null)
        {
            mainCamera = new GameObject("Main Camera").AddComponent<Camera>();
            mainCamera.tag = "MainCamera";
        }
        
        // Position camera to frame avatar
        mainCamera.transform.position = cameraOffset + new Vector3(0, 0, -cameraDistance);
        mainCamera.transform.LookAt(cameraOffset);
        mainCamera.backgroundColor = new Color(0.1f, 0.1f, 0.15f); // Dark background
    }
    
    void LoadVRM()
    {
        // Try multiple locations for VRM file
        string[] searchPaths = new string[]
        {
            Path.Combine(Application.streamingAssetsPath, vrmFilePath),
            Path.Combine(Application.dataPath, "..", "VRM", vrmFilePath),
            Path.Combine(Application.dataPath, "..", "assets", vrmFilePath),
        };
        
        string foundPath = null;
        foreach (string path in searchPaths)
        {
            if (File.Exists(path))
            {
                foundPath = path;
                break;
            }
        }
        
        if (foundPath == null)
        {
            Debug.LogError($"VRM file not found. Searched paths:");
            foreach (string path in searchPaths)
            {
                Debug.LogError($"  - {path}");
            }
            return;
        }
        
        Debug.Log($"Loading VRM from: {foundPath}");
        
        try
        {
            byte[] vrmBytes = File.ReadAllBytes(foundPath);
            var context = new VRMImporterContext();
            context.ParseGlb(vrmBytes);
            context.Load();
            
            vrmInstance = context.Root;
            vrmInstance.transform.position = Vector3.zero;
            vrmInstance.transform.rotation = Quaternion.identity;
            
            // Add components for animation
            if (!vrmInstance.GetComponent<LipSync>())
            {
                vrmInstance.AddComponent<LipSync>();
            }
            
            if (!vrmInstance.GetComponent<IdleAnimation>())
            {
                vrmInstance.AddComponent<IdleAnimation>();
            }
            
            if (!vrmInstance.GetComponent<AudioReceiver>())
            {
                vrmInstance.AddComponent<AudioReceiver>();
            }
            
            // Add audio source if not present
            if (!vrmInstance.GetComponent<AudioSource>())
            {
                AudioSource audioSource = vrmInstance.AddComponent<AudioSource>();
                audioSource.playOnAwake = false;
                audioSource.spatialBlend = 0f; // 2D sound
            }
            
            Debug.Log("VRM loaded successfully!");
        }
        catch (System.Exception e)
        {
            Debug.LogError($"Failed to load VRM: {e.Message}");
            Debug.LogError(e.StackTrace);
        }
    }
    
    public GameObject GetVRMInstance()
    {
        return vrmInstance;
    }
}
