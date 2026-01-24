import os
import sys
import shutil
import torch
import numpy as np
from scipy.io import wavfile 
from pydub import AudioSegment 

from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import FileResponse
import uvicorn
from rvc_python.infer import RVCInference

# ==========================================
# 🛑 TAHAP 1: KONFIGURASI & CEK FILE (WAJIB DULUAN)
# ==========================================
print("\n" + "="*40)
print("🔍 SYSTEM CHECK: MEMERIKSA FILE AI...")
print("="*40)

BASE_DIR = os.getcwd()
UPLOAD_FOLDER = os.path.join(BASE_DIR, "uploads")
OUTPUT_FOLDER = os.path.join(BASE_DIR, "outputs")
WEIGHTS_DIR   = os.path.join(BASE_DIR, "assets", "weights")

# --- DEFINISI LOKASI FILE SYSTEM ---
HUBERT_FILE = "hubert_base.pt"
RMVPE_FILE  = "rmvpe.pth"

HUBERT_PATH = os.path.join(BASE_DIR, HUBERT_FILE)
RMVPE_PATH  = os.path.join(BASE_DIR, RMVPE_FILE)

# --- DAFTAR MODEL YANG WAJIB ADA ---
# --- DAFTAR MODEL YANG WAJIB ADA ---
REQUIRED_MODELS = [
    "Keqing_e500_s13000.pth",
    "Keqing.index",
    "Klee_280e_6440s.pth",
    "klee.index",
    # --- TAMBAHAN ZETA ---
    "zetaTest.pth",
    "added_IVF462_Flat_nprobe_1_zetaTest_v2.index"
]

# 1. Cek Hubert
if os.path.exists(HUBERT_PATH):
    print(f"✅ [OK] HUBERT ditemukan.")
    os.environ["hubert_path"] = HUBERT_PATH 
else:
    print(f"❌ [GAGAL] File '{HUBERT_FILE}' TIDAK ADA di root folder!")
    sys.exit(1)

# 2. Cek RMVPE
if os.path.exists(RMVPE_PATH):
    print(f"✅ [OK] RMVPE ditemukan.")
    os.environ["rmvpe_path"] = RMVPE_PATH 
else:
    print(f"❌ [GAGAL] File '{RMVPE_FILE}' TIDAK ADA di root folder!")
    sys.exit(1)

# 3. Cek Model Suara
print("-" * 20)
missing_files = []
for filename in REQUIRED_MODELS:
    file_path = os.path.join(WEIGHTS_DIR, filename)
    if os.path.exists(file_path):
        print(f"✅ [OK] Model/Index ditemukan: {filename}")
    else:
        print(f"❌ [MISSING] File hilang: {filename}")
        missing_files.append(filename)

if missing_files:
    print(f"\n⚠️ PERINGATAN: Ada {len(missing_files)} file model yang hilang di folder assets/weights!")
else:
    print("✨ Semua Model (Keqing & Klee) LENGKAP!")

print("="*40)
print("🚀 MEMULAI SERVER...")
print("="*40 + "\n")

# ==========================================
# 🛠️ TAHAP 2: LIBRARY & SECURITY BYPASS
# ==========================================
# Hardcode FFMPEG (Sesuaikan path jika perlu)
AudioSegment.converter = r"C:\ffmpeg\bin\ffmpeg.exe"
AudioSegment.ffmpeg = r"C:\ffmpeg\bin\ffmpeg.exe"
AudioSegment.ffprobe = r"C:\ffmpeg\bin\ffprobe.exe"

# Bypass Security
original_load = torch.load
def bypass_security_load(*args, **kwargs):
    if 'weights_only' not in kwargs:
        kwargs['weights_only'] = False
    return original_load(*args, **kwargs)
torch.load = bypass_security_load

# ==========================================
# 🟢 TAHAP 3: FASTAPI & RVC
# ==========================================
app = FastAPI()

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# Inisialisasi RVC (Engine standby)
print(f"⏳ Menyalakan Mesin AI (CUDA)...")
rvc = RVCInference(device="cuda:0") 

# ==========================================
# 🗣️ ENDPOINT: CONVERT VOICE
# ==========================================
@app.post("/convert")
async def convert_voice(
    file: UploadFile = File(...),
    character: str = Form(...),
    model_name: str = Form(...),
    index_name: str = Form(...),
    pitch: int = Form(...) # <--- TAMBAHAN BARU: Terima Pitch dari Flutter
):
    try:
        # 1. Simpan File Input (Sama seperti sebelumnya)
        file_location = os.path.join(UPLOAD_FOLDER, file.filename)
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        output_filename = f"rvc_{file.filename.split('.')[0]}.wav"
        output_location = os.path.join(OUTPUT_FOLDER, output_filename)

        print(f"\n🔄 REQUEST BARU: {character}")
        print(f"🎵 Pitch Request: {pitch}") # Log Pitch

        # 2. KONSTRUKSI PATH (Sama seperti sebelumnya)
        current_model_path = os.path.join(WEIGHTS_DIR, model_name)
        current_index_path = os.path.join(WEIGHTS_DIR, index_name)

        if not os.path.exists(current_model_path):
            raise FileNotFoundError(f"Model {model_name} tidak ditemukan!")
        
        if not os.path.exists(current_index_path):
            print(f"⚠️ Warning: Index tidak ditemukan, lanjut tanpa index.")
            current_index_path = None

        # 3. LOAD MODEL (Sama seperti sebelumnya)
        print(f"⚙️  Loading Model...")
        rvc.load_model(current_model_path)
        
        # 4. EKSEKUSI DENGAN PITCH DINAMIS
        print(f"mic -> ai (Pitch: {pitch}) -> converting...")
        
        full_result = rvc.vc.vc_single(
            0, 
            file_location, 
            pitch,          # <--- PENTING: Pakai variabel pitch dari parameter
            None, 
            "rmvpe",
            current_index_path, 
            None, 
            0.75, 3, 0, 0.25, 0.33
        )

        # --- LOGIC PENCARIAN OUTPUT ---
        target_sr = None
        audio_data = None

        if isinstance(full_result, (tuple, list)):
            for item in full_result:
                if isinstance(item, int): target_sr = item
                elif isinstance(item, np.ndarray): audio_data = item
                elif isinstance(item, tuple):
                    for subitem in item:
                        if isinstance(subitem, np.ndarray): audio_data = subitem

        if audio_data is None and isinstance(full_result, np.ndarray):
            audio_data = full_result

        if audio_data is None:
            raise ValueError("❌ Gagal: Output AI Kosong!")
        
        if target_sr is None: target_sr = 40000 

        # 5. SAVE FILE
        if len(audio_data.shape) > 1: audio_data = audio_data.flatten()
        if audio_data.dtype != np.int16:
            if np.abs(audio_data).max() <= 1.5: 
                audio_data = (audio_data * 32767).astype(np.int16)
            else: 
                audio_data = audio_data.astype(np.int16)

        wavfile.write(output_location, target_sr, audio_data)
        print(f"✅ BERHASIL! Audio untuk {character} selesai.")
        
        return FileResponse(output_location, media_type="audio/wav", filename=output_filename)
    
    except Exception as e:
        print(f"❌ Error Fatal: {e}")
        import traceback
        traceback.print_exc()
        return {"error": str(e)}

# ==========================================
# 🚀 RUN SERVER
# ==========================================
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
