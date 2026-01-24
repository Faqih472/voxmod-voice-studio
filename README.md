# 🎙️ VoxMod: AI Voice Studio

> **Transform your voice into anyone.**  
> VoxMod is an advanced AI Voice Changer application powered by RVC (Retrieval-based Voice Conversion). It combines a high-performance Python backend with a modern Flutter interface to deliver real-time, high-quality voice transformation.

---

## ✨ Demo Preview

| 📱 Mobile App (Frontend) | ⚙️ AI Core Engine (Backend) |
|-------------------------|-----------------------------|
| *(Replace this with App Demo GIF/Video link)* | *(Replace this with Backend Terminal GIF link)* |
| ![App Demo](https://via.placeholder.com/300x600?text=App+Recording+Demo) | ![Backend Running](https://via.placeholder.com/600x300?text=Server+Processing+Log) |
| Flutter UI: Character Selection & Recording | Server Logs: RVC Processing & Pitch Shifting |

---

## 🎭 Voice Collection (Presets)

VoxMod provides a variety of ready-to-use voice presets, ranging from Anime characters to Sci-Fi effects.

| Preset Name | Icon | Character Description | UI Color |
|------------|------|----------------------|----------|
| **Anime Girl** | 👧 | High-pitch anime-style female voice. Cute and kawaii tone (Keqing RVC model). | Pink |
| **News Anchor** | 🎙️ | Deep, formal, and authoritative broadcast-style voice. | Blue |
| **Deep Voice** | 🔉 | Heavy bass voice effect for a dark, mysterious, or villain-like feel. | Teal |
| **Chipmunk** | 🐿️ | Extreme high-pitch effect. Fast, squeaky, and playful. | Orange |
| **Cyborg** | 🤖 | Futuristic robotic voice. Flat, metallic, and emotionless. | Cyan |
| **Ghost** | 👻 | Horror-style voice with reverb and echo for spooky storytelling. | Purple |

---

## 🚀 Key Features

- **AI-Powered RVC**  
  Uses Retrieval-based Voice Conversion (rmvpe) for natural and realistic voice conversion.

- **Smart Pitch Shifting**  
  Automatic pitch control, including presets such as +12 semitones for male-to-female conversion.

- **Auto-Flatten Engine**  
  Intelligent backend system that automatically fixes broken or invalid audio formats before processing.

- **Cross-Platform Mobile App**  
  Built with Flutter for smooth performance on both Android and iOS.

- **Local Processing & Privacy First**  
  All processing is done locally (localhost). No audio data is sent to the cloud.

---

## 📂 Project Structure (Monorepo)

This repository combines both backend AI logic and frontend mobile application.

voxmod-voice-studio  
├── api-contract  
│   └── OpenAPI specification  
├── backend  
│   ├── assets  
│   │   └── AI models (.pth) and index files (.index)  
│   ├── uploads  
│   │   └── Temporary input audio storage  
│   ├── outputs  
│   │   └── Temporary output audio storage  
│   └── main.py  
│       └── Smart Search logic and RVC inference  
└── frontend  
    └── voxmod_voice_studio  
        ├── lib  
        │   └── UI screens (Home, Studio, Result)  
        └── assets  
            └── Icons and static assets  

---

## 🛠️ Installation & Usage

### Backend (AI Engine)

- Requires Python 3.10 or newer  
- NVIDIA GPU is highly recommended for best performance  
- RVC model files (.pth and .index) must be placed in the backend assets directory  
- Backend server runs locally on port 8000

### Frontend (Mobile App)

- Requires Flutter SDK  
- Supports Android and iOS devices  
- The app connects directly to the local backend server on the same network

---

## 🔒 License & Disclaimer

This project is licensed under **AGPL-3.0** with additional restrictions.

- ❌ Commercial use is **NOT allowed**  
- ❌ Hosting as a public service (SaaS) is **NOT allowed**  
- ✅ Personal and educational use only  

This repository contains inference source code only.  
Voice models used in demos belong to their respective creators.

---

Built with 💙 using **Flutter** & **Python RVC**
