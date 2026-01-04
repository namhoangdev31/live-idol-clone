using UnityEngine;
using System.Collections;
using VRM;

/// <summary>
/// Adds idle animations like blinking and subtle head movements
/// </summary>
public class IdleAnimation : MonoBehaviour
{
    [Header("Blink Settings")]
    [Tooltip("Average time between blinks in seconds")]
    public float blinkInterval = 3f;
    
    [Tooltip("Random variation in blink timing (±seconds)")]
    public float blinkVariation = 2f;
    
    [Tooltip("Duration of blink animation")]
    public float blinkDuration = 0.15f;
    
    [Header("Head Movement Settings")]
    [Tooltip("Enable subtle head movement")]
    public bool enableHeadMovement = true;
    
    [Tooltip("Maximum head rotation angle")]
    public float headMovementAmount = 5f;
    
    [Tooltip("Speed of head movement")]
    public float headMovementSpeed = 0.5f;
    
    private VRMBlendShapeProxy blendShapeProxy;
    private Transform headBone;
    private float nextBlinkTime;
    private bool isBlinking = false;
    
    // Head movement
    private Vector3 headRotationTarget;
    private Vector3 currentHeadRotation;
    private float nextHeadChangeTime;
    
    void Start()
    {
        blendShapeProxy = GetComponent<VRMBlendShapeProxy>();
        
        if (blendShapeProxy == null)
        {
            Debug.LogWarning("VRMBlendShapeProxy not found. Idle animations disabled.");
            enabled = false;
            return;
        }
        
        // Find head bone
        Animator animator = GetComponent<Animator>();
        if (animator != null)
        {
            headBone = animator.GetBoneTransform(HumanBodyBones.Head);
        }
        
        // Initialize timers
        ScheduleNextBlink();
        ScheduleNextHeadMovement();
        
        Debug.Log("Idle animations initialized");
    }
    
    void Update()
    {
        UpdateBlinking();
        
        if (enableHeadMovement && headBone != null)
        {
            UpdateHeadMovement();
        }
    }
    
    void UpdateBlinking()
    {
        if (isBlinking)
            return;
        
        if (Time.time >= nextBlinkTime)
        {
            StartCoroutine(Blink());
        }
    }
    
    void UpdateHeadMovement()
    {
        // Change head rotation target periodically
        if (Time.time >= nextHeadChangeTime)
        {
            headRotationTarget = new Vector3(
                Random.Range(-headMovementAmount, headMovementAmount),
                Random.Range(-headMovementAmount, headMovementAmount),
                Random.Range(-headMovementAmount * 0.5f, headMovementAmount * 0.5f)
            );
            
            ScheduleNextHeadMovement();
        }
        
        // Smoothly rotate head
        currentHeadRotation = Vector3.Lerp(
            currentHeadRotation,
            headRotationTarget,
            Time.deltaTime * headMovementSpeed
        );
        
        headBone.localRotation = Quaternion.Euler(currentHeadRotation);
    }
    
    void ScheduleNextBlink()
    {
        float variation = Random.Range(-blinkVariation, blinkVariation);
        nextBlinkTime = Time.time + blinkInterval + variation;
    }
    
    void ScheduleNextHeadMovement()
    {
        nextHeadChangeTime = Time.time + Random.Range(2f, 5f);
    }
    
    IEnumerator Blink()
    {
        isBlinking = true;
        
        // Close eyes (fast)
        float elapsed = 0f;
        float halfDuration = blinkDuration * 0.5f;
        
        while (elapsed < halfDuration)
        {
            float t = elapsed / halfDuration;
            blendShapeProxy.ImmediatelySetValue(BlendShapePreset.Blink, t);
            elapsed += Time.deltaTime;
            yield return null;
        }
        
        blendShapeProxy.ImmediatelySetValue(BlendShapePreset.Blink, 1f);
        
        // Open eyes (fast)
        elapsed = 0f;
        while (elapsed < halfDuration)
        {
            float t = elapsed / halfDuration;
            blendShapeProxy.ImmediatelySetValue(BlendShapePreset.Blink, 1f - t);
            elapsed += Time.deltaTime;
            yield return null;
        }
        
        blendShapeProxy.ImmediatelySetValue(BlendShapePreset.Blink, 0f);
        
        isBlinking = false;
        ScheduleNextBlink();
    }
}
