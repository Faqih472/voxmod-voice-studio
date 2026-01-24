# 🎙️ VoxMod: AI Voice Studio

> **Transform your voice into anyone.** VoxMod is a next-generation AI Voice Changer application powered by **RVC (Retrieval-based Voice Conversion)**. It seamlessly integrates a Flutter-based mobile studio with a high-performance Python FastAPI backend to deliver realistic, customizable voice transformations.

![Status](https://img.shields.io/badge/Status-Active_Development-green)
![Tech](https://img.shields.io/badge/Tech-Flutter_%7C_Python_%7C_RVC-blue)
![License](https://img.shields.io/badge/License-AGPL_3.0-red)

---

## ✨ Features

### 📱 Frontend (Flutter)
- **Studio Mode**: Professional recording interface with real-time audio visualizer.
- **Dynamic Pitch Control**: Adjust voice pitch seamlessly (-12 to +12 semitones).
- **Regenerate Logic**: Record once, edit pitch indefinitely without re-recording.
- **Smart Result Player**: Playback original vs. converted audio with speed control.
- **Interactive UI**: Modern dark-themed UI with animated waves and intuitive sliders.

### ⚙️ Backend (Python AI)
- **RVC Engine**: Powered by `rvc-python` with `rmvpe` (Harvest) extraction for high fidelity.
- **FastAPI Server**: Lightweight, asynchronous REST API handling voice conversion requests.
- **Auto-Flattening**: Automatically fixes audio format issues (channels/sample rate) before processing.
- **Dynamic Model Loading**: Supports hot-swapping between multiple voice models (e.g., Keqing, Klee).
- **GPU Acceleration**: Optimized for NVIDIA CUDA execution (supports CPU fallback).

---

## 📸 Workflow Preview

1. **Select Character**: Choose from available presets (Anime, Cyborg, etc.).
2. **Studio Record**: Record your voice. The app sends raw audio with default pitch (+12 for anime).
3. **Result & Edit**: Listen to the result.
    - *Too deep?* Slide pitch up.
    - *Too squeaky?* Slide pitch down.
    - Click **"Apply"** to regenerate audio on the server instantly.

---

## 🎭 Voice Presets (Models)

VoxMod is designed to work with standard `.pth` (RVC Model) and `.index` (Feature Retrieval) files.

| Preset Name     | Icon | Pitch Strategy | Description |
|-----------------|------|----------------|-------------|
| **Anime Girl**  | 👧   | +12 Semitones  | High-pitch, cute tone (Target: Keqing/Genshin). |
| **Loli / Kid**  | 🎒   | +12 to +16     | Child-like, energetic voice (Target: Klee). |
| **News Anchor** | 🎙️   | 0 (Normal)     | Deep, formal, and authoritative. |
| **Deep / Villain** | 🔉 | -12 Semitones | Heavy bass, dark, mysterious tone. |
| **Chipmunk**    | 🐿️   | +20 Semitones  | Extreme high-pitch, fast and playful. |

---

## 📂 Project Structure

The project follows a Monorepo structure separating the Mobile App and the AI Server.

voxmod-voice-studio  
├── backend/                  # Python API Server  
│   ├── assets/               
│   │   └── weights/          # PLACE YOUR .PTH & .INDEX FILES HERE  
│   ├── uploads/              # Auto-generated temp input audio  
│   ├── outputs/              # Auto-generated temp result audio  
│   ├── hubert_base.pt        # Required Hubert Model  
│   ├── rmvpe.pth             # Required Pitch Extraction Model  
│   ├── main.py               # Main FastAPI Server Entrypoint  
│   └── requirements.txt      # Python Dependencies  
└── frontend/                 # Flutter Mobile App  
    └── voxmod_voice_studio/  
        ├── lib/  
        │   ├── screens/      # StudioScreen, ResultScreen, HomeScreen  
        │   ├── services/     # ApiService (Multipart Requests)  
        │   └── main.dart     # App Entrypoint  
        └── pubspec.yaml      # Flutter Dependencies  

---

## 🛠️ Installation & Setup

### Backend Setup
Prerequisites: Python 3.10+, FFmpeg installed and added to PATH, NVIDIA GPU with CUDA recommended.  
Install Python dependencies: torch, torchvision, torchaudio, fastapi, uvicorn, python-multipart, rvc-python.  
Place `hubert_base.pt` and `rmvpe.pth` in the backend root.  
Place voice models (e.g., Keqing.pth, Keqing.index) in `backend/assets/weights/`.  
Run the server. It will start at `http://0.0.0.0:8000`.

### Frontend Setup
Prerequisites: Flutter SDK, Android Emulator or Physical Device.  
Get dependencies. Configure `lib/services/api_service.dart` with your PC’s local IP (`baseUrl`).  
Run the Flutter app.

---

## 📡 API Reference

**POST /convert**  

Parameters:  
- `file`: File, raw audio recording (.aac, .wav)  
- `character`: String, character name for logging  
- `model_name`: String, model filename (e.g., Keqing.pth)  
- `index_name`: String, index filename (e.g., Keqing.index)  
- `pitch`: Int, pitch shift value (e.g., 12, 0, -12)  

Response: Returns processed `.wav` audio file.

---

## 🐛 Troubleshooting

- FFmpeg not found → ensure installed and in PATH.  
- Connection refused → make sure phone and PC are on same Wi-Fi and API URL uses PC IP, not localhost.  
- Audio robotic/glitchy → adjust pitch (-12 to +12), ensure clear recording without background noise.

---

## 🔒 License

AGPL-3.0:  
✅ Personal use, educational use, modification  
❌ Commercial use or SaaS hosting without open-sourcing  

**Disclaimer:** For creative and educational purposes only. Do not use for deepfakes or malicious impersonation.

<p align="center">Built with 💙 by <b>VoxMod Team</b></p>
