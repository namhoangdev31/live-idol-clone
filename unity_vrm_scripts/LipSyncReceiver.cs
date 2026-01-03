using UnityEngine;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Collections.Concurrent;

namespace LiveIdol
{
    /// <summary>
    /// Simple TCP Receiver for LipSync data.
    /// Listens on a port for JSON viseme data from the backend.
    /// </summary>
    public class LipSyncReceiver : MonoBehaviour
    {
        [SerializeField] private int port = 5000;
        [SerializeField] private LipSync lipSyncController;

        private TcpListener listener;
        private Thread listenerThread;
        private ConcurrentQueue<string> messageQueue = new ConcurrentQueue<string>();
        private bool isRunning = false;

        void Start()
        {
            if (lipSyncController == null)
            {
                lipSyncController = GetComponent<LipSync>();
            }

            StartServer();
        }

        void OnDestroy()
        {
            StopServer();
        }

        void Update()
        {
            // Process queue on main thread
            while (messageQueue.TryDequeue(out string message))
            {
                ProcessMessage(message);
            }
        }

        private void StartServer()
        {
            try
            {
                listener = new TcpListener(IPAddress.Parse("127.0.0.1"), port);
                listener.Start();
                isRunning = true;
                listenerThread = new Thread(ListenForClients);
                listenerThread.IsBackground = true;
                listenerThread.Start();
                Debug.Log($"LipSync Receiver listening on port {port}");
            }
            catch (System.Exception e)
            {
                Debug.LogError($"Failed to start LipSync Receiver: {e.Message}");
            }
        }

        private void StopServer()
        {
            isRunning = false;
            listener?.Stop();
            listenerThread?.Abort();
        }

        private void ListenForClients()
        {
            try
            {
                while (isRunning)
                {
                    TcpClient client = listener.AcceptTcpClient();
                    Thread clientThread = new Thread(HandleClient);
                    clientThread.IsBackground = true;
                    clientThread.Start(client);
                }
            }
            catch (System.Exception)
            {
                // Expected when stopping
            }
        }

        private void HandleClient(object obj)
        {
            TcpClient client = (TcpClient)obj;
            NetworkStream stream = client.GetStream();
            byte[] buffer = new byte[1024];
            int bytesRead;

            try
            {
                while ((bytesRead = stream.Read(buffer, 0, buffer.Length)) != 0)
                {
                    string data = Encoding.UTF8.GetString(buffer, 0, bytesRead);
                    messageQueue.Enqueue(data);
                }
            }
            catch
            {
                // Disconnected
            }
            finally
            {
                client.Close();
            }
        }

        [System.Serializable]
        private class VisemeMessage
        {
            public string @event;
            public int duration_ms;
        }

        private void ProcessMessage(string json)
        {
            Debug.Log($"Received LipSync Data: {json}");
            try
            {
                var msg = JsonUtility.FromJson<VisemeMessage>(json);
                if (msg != null && msg.@event == "speech_start" && lipSyncController != null)
                {
                   // Trigger simple open mouth for duration
                   // Since LipSyncController might be complex, we can try to call a method like 'OpenMouth(duration)'
                   // Or for this PoC, just log it clearly or start a coroutine if MonoBehaviour
                   StartCoroutine(SimpleMouthRoutine(msg.duration_ms / 1000f));
                }
            }
            catch (System.Exception e)
            {
                Debug.LogError($"Error parsing LipSync JSON: {e.Message}");
            }
        }

        private System.Collections.IEnumerator SimpleMouthRoutine(float duration)
        {
            Debug.Log($"[LipSync] Opening mouth for {duration} seconds");
            // Placeholder: If LipSync controller has blendshapes, set 'A' to 1.0
            // if (lipSyncController != null) lipSyncController.SetMouthOpen(1.0f);
            
            yield return new WaitForSeconds(duration);
            
            Debug.Log($"[LipSync] Closing mouth");
            // if (lipSyncController != null) lipSyncController.SetMouthOpen(0.0f);
        }
    }
}
