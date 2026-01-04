using UnityEngine;
using System.IO;
using System.Collections;
using System;

/// <summary>
/// Watches for new audio files from backend and plays them
/// </summary>
public class AudioReceiver : MonoBehaviour
{
    [Header("Audio Receiver Settings")]
    [Tooltip("Directory to watch for new audio files")]
    public string watchDirectory = @"C:\Program Files\LiveIdolClone\backend\output";
    
    [Tooltip("Check for new files every X seconds")]
    public float checkInterval = 0.5f;
    
    private AudioSource audioSource;
    private string lastProcessedFile = null;
    private float nextCheckTime = 0f;
    
    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        
        if (audioSource == null)
        {
            Debug.LogError("AudioSource not found!");
            enabled = false;
            return;
        }
        
        // Try to find the correct directory
        if (!Directory.Exists(watchDirectory))
        {
            // Try alternative paths
            string[] alternativePaths = new string[]
            {
                Path.Combine(Application.dataPath, "..", "backend", "output"),
                Path.Combine(Application.dataPath, "..", "..", "backend", "output"),
                Path.Combine(Application.dataPath, "..", "..", "..", "..", "backend", "output"),
                @"C:\LiveIdolClone\backend\output",
            };
            
            bool found = false;
            foreach (string alt in alternativePaths)
            {
                if (Directory.Exists(alt))
                {
                    watchDirectory = alt;
                    found = true;
                    Debug.Log($"Using watch directory: {watchDirectory}");
                    break;
                }
            }
            
            if (!found)
            {
                Debug.LogWarning($"Watch directory not found: {watchDirectory}");
                Debug.LogWarning("Audio playback may not work. Please set the correct path in Inspector.");
            }
        }
        else
        {
            Debug.Log($"Watching directory: {watchDirectory}");
        }
    }
    
    void Update()
    {
        if (Time.time < nextCheckTime)
            return;
        
        nextCheckTime = Time.time + checkInterval;
        
        // Check for new audio files
        CheckForNewAudio();
    }
    
    void CheckForNewAudio()
    {
        if (!Directory.Exists(watchDirectory))
            return;
        
        try
        {
            // Get all WAV files
            string[] audioFiles = Directory.GetFiles(watchDirectory, "*.wav");
            
            if (audioFiles.Length == 0)
                return;
            
            // Sort by creation time (newest first)
            System.Array.Sort(audioFiles, (a, b) => 
                File.GetCreationTime(b).CompareTo(File.GetCreationTime(a))
            );
            
            string latestFile = audioFiles[0];
            
            // Check if this is a new file we haven't played yet
            if (latestFile != lastProcessedFile && !audioSource.isPlaying)
            {
                // Make sure file is fully written (wait a bit)
                FileInfo fileInfo = new FileInfo(latestFile);
                TimeSpan age = DateTime.Now - fileInfo.LastWriteTime;
                
                if (age.TotalSeconds > 0.5) // File is at least 0.5 seconds old
                {
                    Debug.Log($"New audio file detected: {Path.GetFileName(latestFile)}");
                    lastProcessedFile = latestFile;
                    StartCoroutine(LoadAndPlayAudio(latestFile));
                }
            }
        }
        catch (System.Exception e)
        {
            Debug.LogWarning($"Error checking for audio files: {e.Message}");
        }
    }
    
    IEnumerator LoadAndPlayAudio(string filePath)
    {
        // Load audio file
        string url = "file:///" + filePath.Replace("\\", "/");
        
        using (WWW www = new WWW(url))
        {
            yield return www;
            
            if (!string.IsNullOrEmpty(www.error))
            {
                Debug.LogError($"Failed to load audio: {www.error}");
                yield break;
            }
            
            AudioClip clip = www.GetAudioClip(false, false, AudioType.WAV);
            
            if (clip != null)
            {
                audioSource.clip = clip;
                audioSource.Play();
                
                Debug.Log($"Playing: {Path.GetFileName(filePath)} ({clip.length:F2}s)");
            }
            else
            {
                Debug.LogError("Failed to create AudioClip from file");
            }
        }
    }
    
    /// <summary>
    /// Display current status in editor
    /// </summary>
    void OnGUI()
    {
        if (!Application.isEditor)
            return;
        
        float y = 100f;
        float width = 300f;
        float height = 20f;
        
        GUI.Box(new Rect(10, y, width, height), $"Watch Dir: {Path.GetFileName(watchDirectory)}");
        GUI.Box(new Rect(10, y + 25, width, height), 
            $"Status: {(audioSource.isPlaying ? "Playing" : "Idle")}");
        
        if (lastProcessedFile != null)
        {
            GUI.Box(new Rect(10, y + 50, width, height), 
                $"Last: {Path.GetFileName(lastProcessedFile)}");
        }
    }
}
