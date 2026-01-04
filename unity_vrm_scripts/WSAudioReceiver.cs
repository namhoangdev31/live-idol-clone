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
            PlayAudio(data);
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
                    Debug.Log($"WS Message: {msg}");
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
