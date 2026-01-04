using UnityEngine;
using VRM;

/// <summary>
/// Energy-based lip sync that animates mouth based on audio volume
/// </summary>
public class LipSync : MonoBehaviour
{
    [Header("Lip Sync Settings")]
    [Range(0f, 5f)]
    [Tooltip("How sensitive the mouth opening is to audio volume")]
    public float sensitivity = 1.5f;
    
    [Range(0f, 1f)]
    [Tooltip("How smoothly the mouth transitions (0 = instant, 1 = very smooth)")]
    public float smoothing = 0.3f;
    
    [Range(0f, 1f)]
    [Tooltip("Minimum mouth opening when speaking")]
    public float minMouthOpen = 0.1f;
    
    private VRMBlendShapeProxy blendShapeProxy;
    private AudioSource audioSource;
    private float currentMouthOpen = 0f;
    private float[] audioSamples = new float[256];
    
    void Start()
    {
        // Get VRM blend shape proxy
        blendShapeProxy = GetComponent<VRMBlendShapeProxy>();
        if (blendShapeProxy == null)
        {
            Debug.LogError("VRMBlendShapeProxy not found! LipSync requires a VRM model.");
            enabled = false;
            return;
        }
        
        // Get audio source
        audioSource = GetComponent<AudioSource>();
        if (audioSource == null)
        {
            Debug.LogError("AudioSource not found! LipSync requires an AudioSource.");
            enabled = false;
            return;
        }
        
        Debug.Log("LipSync initialized");
    }
    
    void Update()
    {
        if (blendShapeProxy == null || audioSource == null)
            return;
        
        // Calculate audio volume (RMS - Root Mean Square)
        float volume = GetAudioRMS();
        
        // Map volume to mouth opening (0-1 range)
        float targetMouth = 0f;
        
        if (volume > 0.001f) // Threshold to avoid noise
        {
            targetMouth = Mathf.Clamp01(volume * sensitivity);
            targetMouth = Mathf.Max(targetMouth, minMouthOpen);
        }
        
        // Smooth transition
        currentMouthOpen = Mathf.Lerp(currentMouthOpen, targetMouth, 1f - smoothing);
        
        // Apply to VRM blend shapes
        // Use 'A' blend shape for mouth opening
        blendShapeProxy.ImmediatelySetValue(BlendShapePreset.A, currentMouthOpen);
    }
    
    /// <summary>
    /// Calculate RMS (Root Mean Square) of current audio output
    /// </summary>
    float GetAudioRMS()
    {
        if (!audioSource.isPlaying)
            return 0f;
        
        // Get audio output data
        audioSource.GetOutputData(audioSamples, 0);
        
        // Calculate RMS
        float sum = 0f;
        for (int i = 0; i < audioSamples.Length; i++)
        {
            sum += audioSamples[i] * audioSamples[i];
        }
        
        float rms = Mathf.Sqrt(sum / audioSamples.Length);
        
        return rms;
    }
    
    /// <summary>
    /// Visualize audio volume in editor
    /// </summary>
    void OnGUI()
    {
        if (!Application.isEditor)
            return;
        
        float volume = GetAudioRMS();
        float barWidth = 200f;
        float barHeight = 20f;
        
        GUI.Box(new Rect(10, 10, barWidth, barHeight), $"Audio: {volume:F3}");
        GUI.Box(new Rect(10, 35, barWidth, barHeight), $"Mouth: {currentMouthOpen:F3}");
        
        // Volume bar
        GUI.color = Color.green;
        GUI.Box(new Rect(10, 60, volume * sensitivity * barWidth, barHeight), "");
        GUI.color = Color.white;
    }
}
