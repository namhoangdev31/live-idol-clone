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

        private void ProcessMessage(string json)
        {
            // Parse JSON and trigger LipSync
            // Example: {"viseme": "aa", "duration": 0.2}
            // For now, just logging
            Debug.Log($"Received LipSync Data: {json}");
            
            // TODO: Map to lipSyncController.PlayViseme(...)
        }
    }
}
