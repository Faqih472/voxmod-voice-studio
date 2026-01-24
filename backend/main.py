import os
import sys
import shutil
import torch
import numpy as np
from scipy.io import wavfile 
from pydub import AudioSegment 

# ==========================================
# 🛑 TAHAP 1: KONFIGURASI & CEK FILE (WAJIB DULUAN)
# ==========================================
print("\n" + "="*40)
print("🔍 SYSTEM CHECK: MEMERIKSA FILE AI...")
print("="*40)

BASE_DIR = os.getcwd()
UPLOAD_FOLDER = os.path.join(BASE_DIR, "uploads")
OUTPUT_FOLDER = os.path.join(BASE_DIR, "outputs")

# --- DEFINISI LOKASI FILE ---
# Pastikan nama file ini sesuai dengan yang ada di folder backend Anda
HUBERT_FILE = "hubert_base.pt"
RMVPE_FILE  = "rmvpe.pth"
MODEL_FILE  = "Keqing_e500_s13000.pth"
INDEX_FILE  = "Keqing.index"

HUBERT_PATH = os.path.join(BASE_DIR, HUBERT_FILE)
RMVPE_PATH  = os.path.join(BASE_DIR, RMVPE_FILE)
MODEL_PATH  = os.path.join(BASE_DIR, "assets", "weights", MODEL_FILE)
INDEX_PATH  = os.path.join(BASE_DIR, "assets", "weights", INDEX_FILE)

# --- LOGIKA PENGECEKAN VISUAL ---

# 1. Cek Hubert
if os.path.exists(HUBERT_PATH):
    print(f"✅ [OK] HUBERT ditemukan di: {HUBERT_PATH}")
    os.environ["hubert_path"] = HUBERT_PATH # Paksa Environment Variable
else:
    print(f"❌ [GAGAL] File '{HUBERT_FILE}' TIDAK ADA di folder backend!")
    sys.exit(1) # Matikan program jika file ini hilang

# 2. Cek RMVPE
if os.path.exists(RMVPE_PATH):
    print(f"✅ [OK] RMVPE ditemukan di: {RMVPE_PATH}")
    os.environ["rmvpe_path"] = RMVPE_PATH # Paksa Environment Variable
else:
    print(f"❌ [GAGAL] File '{RMVPE_FILE}' TIDAK ADA di folder backend!")
    sys.exit(1)

# 3. Cek Model Suara
if os.path.exists(MODEL_PATH):
    print(f"✅ [OK] MODEL Suara ditemukan: {MODEL_FILE}")
else:
    print(f"❌ [GAGAL] Model '{MODEL_FILE}' tidak ditemukan di assets/weights!")
    sys.exit(1)

# 4. Cek Index
if os.path.exists(INDEX_PATH):
    print(f"✅ [OK] INDEX Suara ditemukan: {INDEX_FILE}")
else:
    print(f"⚠️ [WARNING] File Index tidak ditemukan. Suara mungkin kurang mirip.")

print("="*40)
print("✨ SEMUA FILE LENGKAP! MEMULAI SERVER...")
print("="*40 + "\n")

# ==========================================
# 🛠️ TAHAP 2: LIBRARY & SECURITY BYPASS
# ==========================================
# Hardcode FFMPEG
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

from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import FileResponse
import uvicorn
from rvc_python.infer import RVCInference

app = FastAPI()

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# Inisialisasi RVC (Dilakukan setelah cek file di atas sukses)
print(f"⏳ Sedang memuat Model ke GPU...")
rvc = RVCInference(device="cuda:0") 

@app.post("/convert")
async def convert_voice(
    file: UploadFile = File(...),
    character: str = Form(...)
):
    try:
        # 1. Simpan File Input
        file_location = os.path.join(UPLOAD_FOLDER, file.filename)
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        output_filename = f"rvc_{file.filename.split('.')[0]}.wav"
        output_location = os.path.join(OUTPUT_FOLDER, output_filename)

        print(f"\n🔄 PROSES BARU: Mengubah suara {file.filename}")

        # 2. LOAD MODEL
        # Kita load ulang untuk memastikan path benar
        rvc.load_model(MODEL_PATH)
        
        # --- SETTING PITCH ---
        # 12 = Laki-laki ke Perempuan (Wajib naik oktaf)
        # 0  = Perempuan ke Perempuan
        PITCH = 12 
        
        # 3. EKSEKUSI UTAMA
        print(f"⚙️  Sedang Convert... (Mode: RMVPE, Pitch: {PITCH})")
        
        full_result = rvc.vc.vc_single(
            0, 
            file_location, 
            PITCH, 
            None, 
            "rmvpe",        # Pastikan string ini "rmvpe"
            INDEX_PATH,     # File index dipanggil disini
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

        # VALIDASI
        if audio_data is None:
            raise ValueError("❌ Gagal: Output AI Kosong!")
        
        if target_sr is None: target_sr = 40000 

        # 4. SAVE FILE
        if len(audio_data.shape) > 1: audio_data = audio_data.flatten()
        
        if audio_data.dtype != np.int16:
            if np.abs(audio_data).max() <= 1.5: 
                audio_data = (audio_data * 32767).astype(np.int16)
            else: 
                audio_data = audio_data.astype(np.int16)

        wavfile.write(output_location, target_sr, audio_data)

        print(f"✅ BERHASIL! File disimpan di: {output_filename}")
        
        return FileResponse(output_location, media_type="audio/wav", filename=output_filename)
    
    except Exception as e:
        print(f"❌ Error Fatal: {e}")
        import traceback
        traceback.print_exc()
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
