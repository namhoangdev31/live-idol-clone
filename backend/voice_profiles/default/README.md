# Voice Profile: default

This directory should contain a reference audio file (WAV format recommended) for voice cloning.

## Setup

1. Record a 5-10 second audio sample of the target voice saying a few sentences
2. Save as `reference.wav` in this directory
3. The TTS engine will use this to clone the voice

## For PoC/Testing

If no audio file is present, the system will fall back to the default TTS voice without cloning.

## Recommended Recording

- Format: WAV, 16-bit, 22050 Hz or higher
- Duration: 5-10 seconds
- Content: Clear speech, no background noise
- Example text: "Hello, my name is [Name]. I'm excited to demonstrate this voice cloning technology. This is a sample of my voice for the live idol clone project."
