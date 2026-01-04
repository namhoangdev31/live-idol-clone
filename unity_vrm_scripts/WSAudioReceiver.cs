using System;
using System.Collections;
using System.Collections.Concurrent;
using System.IO;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

/// <summary>
/// Connects to Python Backend WebSocket (Link: ws://localhost:8001)
/// Receives Audio Data (WAV bytes) and plays it via AudioSource.
/// </summary>
public class WSAudioReceiver : MonoBehaviour
{
    [Header("Connection Settings")]
    public string serverUrl = "ws://localhost:8001";
    public bool autoConnect = true;

    [Header("Audio Settings")]
    public AudioSource audioSource;
    // Buffer for main thread processing
    private ConcurrentQueue<byte[]> audioQueue = new ConcurrentQueue<byte[]>();

    private ClientWebSocket ws;
    private CancellationTokenSource cts;
    
    private void Start()
    {
        if (audioSource == null) audioSource = GetComponent<AudioSource>();
        if (autoConnect) Connect();
    }

    private void OnDestroy()
    {
        Disconnect();
    }

    private void Update()
    {
        // Process received audio data on the Main Thread
        while (audioQueue.TryDequeue(out byte[] data))
        {
            // Check if it's a special config message (hacky but effective)
            if (data.Length > 7 && Encoding.UTF8.GetString(data, 0, 7) == "CONFIG:")
            {
                string json = Encoding.UTF8.GetString(data, 7, data.Length - 7);
                ApplyConfig(json);
            }
            else
            {
                PlayAudio(data);
            }
        }
    }
    
    private void ApplyConfig(string json)
    {
        // Re-parse or just extract values again? 
        // We already did parsing logic in background thread but we couldn't call component.
        // Let's do parsing here properly safely.
        
        bool enabled = json.Contains("\"enabled\": true");
        float sensitivity = 10.0f;
        
        // Simple regex-like parsing
        int sensIndex = json.IndexOf("\"sensitivity\":");
        if (sensIndex != -1)
        {
            int endIndex = json.IndexOf("}", sensIndex);
            if (endIndex == -1) endIndex = json.IndexOf(",", sensIndex);
            if (endIndex != -1)
            {
                string sensStr = json.Substring(sensIndex + 14, endIndex - (sensIndex + 14)).Trim();
                float.TryParse(sensStr, out sensitivity);
            }
        }
        
        var processor = GetComponent<LipSyncProcessor>();
        if (processor != null)
        {
            processor.UpdateSettings(enabled, sensitivity);
        }
    }

    public async void Connect()
    {
        if (ws != null && ws.State == WebSocketState.Open) return;

        cts = new CancellationTokenSource();
        ws = new ClientWebSocket();

        try
        {
            Debug.Log($"Connecting to WS: {serverUrl}");
            await ws.ConnectAsync(new Uri(serverUrl), cts.Token);
            Debug.Log("Connected to WebSocket Server!");
            
            // Start listening loop
            _ = ReceiveLoop();
        }
        catch (Exception e)
        {
            Debug.LogError($"WS Connection Error: {e.Message}");
            // Retry after delay?
            Invoke(nameof(Connect), 5f);
        }
    }

    public void Disconnect()
    {
        cts?.Cancel();
        ws?.Dispose();
        ws = null;
    }

    private async Task ReceiveLoop()
    {
        var buffer = new byte[1024 * 500]; // 500KB buffer
        
        try
        {
            while (ws.State == WebSocketState.Open && !cts.IsCancellationRequested)
            {
                var result = await ws.ReceiveAsync(new ArraySegment<byte>(buffer), cts.Token);
                
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    await ws.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None);
                    break;
                }
                else if (result.MessageType == WebSocketMessageType.Binary)
                {
                    // Copy received data to a new array
                    // result.Count contains the number of bytes received
                    byte[] receivedBytes = new byte[result.Count];
                    Array.Copy(buffer, receivedBytes, result.Count);
                    
                    // Enqueue for Main Thread
                    audioQueue.Enqueue(receivedBytes);
                }
                else if (result.MessageType == WebSocketMessageType.Text)
                {
                    string msg = Encoding.UTF8.GetString(buffer, 0, result.Count);
                    // Debug.Log($"WS Message: {msg}");
                    
                    try
                    {
                        // Parse JSON manually or use JsonUtility
                        if (msg.Contains("\"type\": \"lipsync_config\""))
                        {
                            // Simple parsing to avoid extra dependencies if possible, 
                            // or use JsonUtility wrapper struct.
                            // Let's use string manipulation for simplicity/robustness without defining structs everywhere
                            // format: {"type": "lipsync_config", "enabled": true, "sensitivity": 20.0}
                            
                            bool enabled = msg.Contains("\"enabled\": true");
                            
                            // Parse sensitivity
                            float sensitivity = 10.0f;
                            int sensIndex = msg.IndexOf("\"sensitivity\":");
                            if (sensIndex != -1)
                            {
                                int endIndex = msg.IndexOf("}", sensIndex);
                                if (endIndex == -1) endIndex = msg.IndexOf(",", sensIndex);
                                if (endIndex != -1)
                                {
                                    string sensStr = msg.Substring(sensIndex + 14, endIndex - (sensIndex + 14)).Trim();
                                    float.TryParse(sensStr, out sensitivity);
                                }
                            }
                            
                            // Apply to LipSyncProcessor
                            var processor = GetComponent<LipSyncProcessor>();
                            if (processor != null)
                            {
                                // Must run on main thread? Unity API usage inside UpdateSettings (Debug.Log) is fine?
                                // Actually UpdateSettings sets simple variables, but Debug.Log is Unity API.
                                // Best to queue it.
                                audioQueue.Enqueue(Encoding.UTF8.GetBytes("CONFIG:" + msg)); 
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Debug.LogError($"Error parsing config: {ex.Message}");
                    }
                }
            }
        }
        catch (Exception e)
        {
            if (!cts.IsCancellationRequested)
                Debug.LogError($"WS Receive Error: {e.Message}");
        }
    }

    private void PlayAudio(byte[] wavData)
    {
        // Simply writing to a file and loading with WWW is easiest for WAV parsing in Unity
        // without external libraries like NAudio.
        // For lower latency, parsing WAV header manually to get float[] is better.
        
        StartCoroutine(LoadAudioFromData(wavData));
    }

    // Creating a temp file is a quick hack to let Unity's built-in WAV loader handle the parsing
    // This adds some latency (disk I/O). 
    // OPTIMIZATION: Parse WAV header in memory.
    private IEnumerator LoadAudioFromData(byte[] data)
    {
        string tempPath = Path.Combine(Application.temporaryCachePath, "temp_stream.wav");
        File.WriteAllBytes(tempPath, data);

        string url = "file://" + tempPath;
        using (WWW www = new WWW(url))
        {
            yield return www;
            if (string.IsNullOrEmpty(www.error))
            {
                AudioClip clip = www.GetAudioClip(false, false, AudioType.WAV);
                if (clip != null)
                {
                    audioSource.clip = clip;
                    audioSource.Play();
                    Debug.Log($"Playing Audio: {clip.length:F2}s");
                }
            }
            else
            {
                Debug.LogError($"Audio Load Error: {www.error}");
            }
        }
    }
}
