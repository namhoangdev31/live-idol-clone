using UnityEngine;
using UniGLTF;
using VRM;
using System.IO;
using System.Threading.Tasks;

/// <summary>
/// Loads and initializes a VRM avatar from file using modern UniVRM API
/// </summary>
public class VRMLoader : MonoBehaviour
{
    [Header("VRM Settings")]
    public string vrmFilePath = "avatar.vrm";
    
    [Header("Camera Settings")]
    public float cameraDistance = 1.5f;
    public Vector3 cameraOffset = new Vector3(0, 1.4f, 0);
    
    // Instance reference
    private GameObject vrmInstance;
    private Camera mainCamera;
    
    // Async void Start is acceptable for top-level Unity entry points
    async void Start()
    {
        SetupCamera();
        await LoadVRM();
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
        mainCamera.backgroundColor = new Color(0.1f, 0.1f, 0.15f);
    }
    
    async Task LoadVRM()
    {
        // Try multiple locations for VRM file
        string[] searchPaths = new string[]
        {
            // 1. StreamingAssets (Best for build)
            Path.Combine(Application.streamingAssetsPath, vrmFilePath),
            // 2. Project root/VRM (Dev)
            Path.Combine(Application.dataPath, "..", "VRM", vrmFilePath),
            // 3. Project root (Dev)
            Path.Combine(Application.dataPath, "..", vrmFilePath),
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
            foreach (string path in searchPaths) Debug.LogError($"  - {path}");
            return;
        }
        
        Debug.Log($"Loading VRM from: {foundPath}");
        
        try
        {
            // --- MODERN UNIVRM LOADING (v0.100+) ---
            // Use VrmUtility.LoadBytesAsync for robust loading
            byte[] vrmBytes = File.ReadAllBytes(foundPath);
            
            // AllowUnsafeDesktopUsage = true allows loading files from disk in builds
            // VrmUtility.LoadBytesAsync returns a RuntimeGltfInstance
            var instance = await VrmUtility.LoadBytesAsync(foundPath, vrmBytes);
            
            // Important: Show meshes (they are hidden by default in some versions)
            instance.ShowMeshes();
            
            // Get the root GameObject
            vrmInstance = instance.Root;
            
            // ---------------------------------------
            
            if (vrmInstance != null)
            {
                vrmInstance.transform.position = Vector3.zero;
                vrmInstance.transform.rotation = Quaternion.identity;
                
                // Add required components
                SetupComponents(vrmInstance);
                
                Debug.Log("VRM loaded successfully!");
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError($"Failed to load VRM: {e.Message}");
            Debug.LogError(e.StackTrace);
        }
    }
    
    void SetupComponents(GameObject target)
    {
        // Add LipSync if missing
        if (!target.GetComponent<LipSync>())
            target.AddComponent<LipSync>();
            
        // Add IdleAnimation if missing
        if (!target.GetComponent<IdleAnimation>())
            target.AddComponent<IdleAnimation>();
            
        // Add AudioReceiver if missing
        if (!target.GetComponent<AudioReceiver>())
            target.AddComponent<AudioReceiver>();
            
        // Add AudioSource for voice
        if (!target.GetComponent<AudioSource>())
        {
            AudioSource audioSource = target.AddComponent<AudioSource>();
            audioSource.playOnAwake = false;
            audioSource.spatialBlend = 0f; // 2D sound for clearer voice
        }
    }
    
    public GameObject GetVRMInstance()
    {
        return vrmInstance;
    }
}
