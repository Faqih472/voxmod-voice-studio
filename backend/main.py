import os
import shutil
import torch
import numpy as np
from scipy.io import wavfile 

# --- 🛠️ BYPASS SECURITY (WAJIB ADA) ---
original_load = torch.load
def bypass_security_load(*args, **kwargs):
    if 'weights_only' not in kwargs:
        kwargs['weights_only'] = False
    return original_load(*args, **kwargs)
torch.load = bypass_security_load
# --------------------------------------

from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import FileResponse
import uvicorn
from rvc_python.infer import RVCInference

app = FastAPI()

# --- PATH ---
BASE_DIR = os.getcwd()
UPLOAD_FOLDER = os.path.join(BASE_DIR, "uploads")
OUTPUT_FOLDER = os.path.join(BASE_DIR, "outputs")

MODEL_NAME = "Keqing_e500_s13000.pth"
INDEX_NAME = "Keqing.index"

MODEL_PATH = os.path.join(BASE_DIR, "assets", "weights", MODEL_NAME)
INDEX_PATH = os.path.join(BASE_DIR, "assets", "weights", INDEX_NAME)

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

print(f"⏳ Memuat Model: {MODEL_NAME}...")
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

        print(f"🔄 Mengubah suara: {file.filename}")

        # 2. LOAD MODEL & PARAMETER
        rvc.load_model(MODEL_PATH)
        PITCH = 12 
        
        # 3. EKSEKUSI (Ambil Semua Hasil Mentah)
        print("⚙️ Memproses di Core Engine...")
        
        full_result = rvc.vc.vc_single(
            0, file_location, PITCH, None, "rmvpe", 
            INDEX_PATH, None, 0.75, 3, 0, 0.25, 0.33
        )

        # --- 🕵️ SMART SEARCH LOGIC (CARA BARU) ---
        target_sr = None
        audio_data = None

        # Kita loop hasilnya satu per satu untuk identifikasi
        # full_result biasanya tuple berisi (sr, audio) atau (audio, sr)
        if isinstance(full_result, tuple) or isinstance(full_result, list):
            for item in full_result:
                if isinstance(item, int):
                    # Kalau angka (misal 40000 atau 48000), ini Sample Rate
                    target_sr = item
                    print(f"🔍 Ditemukan Sample Rate: {target_sr}")
                elif isinstance(item, np.ndarray):
                    # Kalau Array Numpy, ini Audionya!
                    audio_data = item
                    print(f"🔍 Ditemukan Audio Data (Shape: {audio_data.shape})")
                elif isinstance(item, tuple):
                    # Kadang audionya ngumpet di dalam tuple lagi
                    for subitem in item:
                        if isinstance(subitem, np.ndarray):
                            audio_data = subitem
                            print(f"🔍 Ditemukan Audio Data (Hidden): {audio_data.shape}")

        # Fallback jika audio_data belum ketemu tapi full_result itu sendiri adalah array
        if audio_data is None and isinstance(full_result, np.ndarray):
             audio_data = full_result

        # VALIDASI TERAKHIR
        if audio_data is None:
            raise ValueError("❌ Gagal menemukan data audio dalam output AI!")
        
        if target_sr is None:
            target_sr = 40000 # Default safe value

        # 4. NORMALISASI & SAVE
        # Pastikan audio data gepeng (1 Dimensi)
        if len(audio_data.shape) > 1:
            audio_data = audio_data.flatten()

        # Konversi Float ke Int16 (Supaya bisa di-play)
        if audio_data.dtype != np.int16:
            # Cek apakah range -1.0 s/d 1.0 (Float)
            if np.abs(audio_data).max() <= 1.5: # Margin dikit
                print("ℹ️ Konversi Float ke Int16...")
                audio_data = (audio_data * 32767).astype(np.int16)
            else:
                # Berarti sudah integer tapi format float, paksa casting
                audio_data = audio_data.astype(np.int16)

        wavfile.write(output_location, target_sr, audio_data)
        # -----------------------------------------

        print(f"✅ SUKSES FINAL! File tersimpan: {output_filename}")
        print(f"📊 Info File: Rate={target_sr}, Size={audio_data.shape}")
        
        return FileResponse(output_location, media_type="audio/wav", filename=output_filename)
    
    except Exception as e:
        print(f"❌ Error Fatal: {e}")
        import traceback
        traceback.print_exc()
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
