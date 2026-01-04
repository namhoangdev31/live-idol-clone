using UnityEngine;
using VRM;

/// <summary>
/// LipSync Processor: Analyzes Audio Spectrum (FFT) and drives VRM BlendShapes (A, I, U, E, O)
/// </summary>
[RequireComponent(typeof(AudioSource))]
public class LipSyncProcessor : MonoBehaviour
{
    [Header("Setup")]
    public VRMBlendShapeProxy blendShapeProxy;
    public AudioSource audioSource;
    
    [Header("Settings")]
    public bool isEnabled = true;
    [Range(1f, 100f)] public float sensitivity = 10.0f;
    [Range(0f, 1f)] public float smoothTime = 0.1f;
    public float threshold = 0.01f;

    // FFT Data
    private float[] spectrumData = new float[512];
    
    // Current BlendShape Weights
    private float targetA, targetI, targetU, targetE, targetO;
    private float currentA, currentI, currentU, currentE, currentO;
    
    // Velocity references for SmoothDamp
    private float velA, velI, velU, velE, velO;

    public void UpdateSettings(bool enabled, float newSensitivity)
    {
        isEnabled = enabled;
        sensitivity = newSensitivity;
        Debug.Log($"[LipSync] Settings Updated: Enabled={isEnabled}, Sensitivity={sensitivity}");
    }

    void Start()
    {
        if (audioSource == null) audioSource = GetComponent<AudioSource>();
        if (blendShapeProxy == null) blendShapeProxy = GetComponent<VRMBlendShapeProxy>();

        if (blendShapeProxy == null)
        {
            Debug.LogError("[LipSync] VRMBlendShapeProxy not found! Please assign it in Inspector.");
            enabled = false;
        }
    }

    void Update()
    {
        if (audioSource == null || blendShapeProxy == null) return;
        
        if (!isEnabled)
        {
            // Reset if disabled
            blendShapeProxy.ImmediatelySetValue(BlendShapePreset.A, 0);
            blendShapeProxy.ImmediatelySetValue(BlendShapePreset.I, 0);
            blendShapeProxy.ImmediatelySetValue(BlendShapePreset.U, 0);
            blendShapeProxy.ImmediatelySetValue(BlendShapePreset.E, 0);
            blendShapeProxy.ImmediatelySetValue(BlendShapePreset.O, 0);
            return;
        }

        // 1. Get Spectrum Data (FFT)
        // Check if playing to avoid noise
        if (audioSource.isPlaying)
        {
            audioSource.GetSpectrumData(spectrumData, 0, FFTWindow.BlackmanHarris);
        }
        else
        {
            // Reset if silent
            for(int i=0; i<spectrumData.Length; i++) spectrumData[i] = 0;
        }

        // 2. Analyze Frequencies (Mapping Logic)
        // These ranges are approximate for human speech vowels
        // Low: U, O | Mid: A, E | High: I
        
        float bandLow = Average(0, 5);      // ~ 0-400Hz
        float bandMidLow = Average(5, 15);  // ~ 400-1200Hz
        float bandMid = Average(15, 30);    // ~ 1200-2500Hz
        float bandHigh = Average(30, 100);  // ~ 2500Hz+

        // Simple Mapping Strategy (Heuristic)
        // A: High energy in Mid-Low (Core speech)
        targetA = (bandMidLow * 2.0f + bandMid * 1.0f) * sensitivity;
        
        // I: High frequencies (Teeth)
        targetI = bandHigh * sensitivity * 1.5f;

        // U: Very low frequencies (Round lips)
        targetU = bandLow * sensitivity * 1.2f;

        // E: Mid frequencies
        targetE = bandMid * sensitivity;

        // O: Mix of Low and Mid-Low
        targetO = (bandLow + bandMidLow) * 0.5f * sensitivity;
        
        // Normalize & Threshold
        ProcessValue(ref targetA);
        ProcessValue(ref targetI);
        ProcessValue(ref targetU);
        ProcessValue(ref targetE);
        ProcessValue(ref targetO);

        // 3. Smooth Values
        currentA = Mathf.SmoothDamp(currentA, targetA, ref velA, smoothTime);
        currentI = Mathf.SmoothDamp(currentI, targetI, ref velI, smoothTime);
        currentU = Mathf.SmoothDamp(currentU, targetU, ref velU, smoothTime);
        currentE = Mathf.SmoothDamp(currentE, targetE, ref velE, smoothTime);
        currentO = Mathf.SmoothDamp(currentO, targetO, ref velO, smoothTime);

        // 4. Apply to VRM
        blendShapeProxy.ImmediatelySetValue(BlendShapePreset.A, currentA);
        blendShapeProxy.ImmediatelySetValue(BlendShapePreset.I, currentI);
        blendShapeProxy.ImmediatelySetValue(BlendShapePreset.U, currentU);
        blendShapeProxy.ImmediatelySetValue(BlendShapePreset.E, currentE);
        blendShapeProxy.ImmediatelySetValue(BlendShapePreset.O, currentO);
    }

    float Average(int start, int end)
    {
        if (start >= spectrumData.Length) return 0;
        if (end > spectrumData.Length) end = spectrumData.Length;
        
        float sum = 0;
        for (int i = start; i < end; i++)
        {
            sum += spectrumData[i];
        }
        return sum / (end - start);
    }

    void ProcessValue(ref float val)
    {
        // Apply threshold
        if (val < threshold) val = 0;
        // Search & Clamp
        val = Mathf.Clamp01(val);
    }
}
