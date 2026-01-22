import os
import shutil
import numpy as np
import librosa
import soundfile as sf
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import FileResponse
import uvicorn

app = FastAPI()

# Setup Folder
UPLOAD_FOLDER = "uploads"
OUTPUT_FOLDER = "outputs"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

@app.get("/")
def home():
    return {"status": "VoxMod Audio Engine Ready"}

def process_audio_dsp(input_path, output_path, character_name):
    """
    Fungsi Pengubah Suara Sederhana (DSP)
    Sambil menunggu RVC, kita pakai manipulasi Pitch dulu.
    """
    print(f"🔄 Memproses audio untuk karakter: {character_name}")
    
    # 1. Load Audio
    # sr=None artinya pakai sample rate asli file
    y, sr = librosa.load(input_path, sr=None) 

    # 2. Tentukan Perubahan Nada (n_steps)
    # Positif = Cempreng (Chipmunk/Anime)
    # Negatif = Berat (Monster/Robot)
    steps = 0
    if "keqing" in character_name.lower() or "anime" in character_name.lower():
        steps = 6  # Naik 6 nada (Jadi cewek/kartun)
    elif "hantu" in character_name.lower() or "robot" in character_name.lower():
        steps = -6 # Turun 6 nada (Jadi berat)
    elif "jokowi" in character_name.lower():
        steps = -2 # Agak berat dikit
    
    # 3. Proses Perubahan Pitch
    if steps != 0:
        # Librosa pitch shifting (High Quality)
        y_shifted = librosa.effects.pitch_shift(y, sr=sr, n_steps=steps)
    else:
        y_shifted = y

    # 4. Simpan File Baru
    sf.write(output_path, y_shifted, sr)
    print("✅ Proses selesai!")

@app.post("/convert")
async def convert_voice(
    file: UploadFile = File(...),
    character: str = Form(...)
):
    try:
        # 1. Terima File
        file_location = f"{UPLOAD_FOLDER}/{file.filename}"
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # 2. Siapkan Nama File Output
        # Kita pastikan outputnya juga .wav biar aman
        output_filename = f"processed_{file.filename.split('.')[0]}.wav"
        output_location = f"{OUTPUT_FOLDER}/{output_filename}"

        # 3. JALANKAN PROSES AUDIO
        # Nanti di sini kita ganti dengan fungsi RVC_Inference()
        process_audio_dsp(file_location, output_location, character)

        # 4. Kirim Balik
        return FileResponse(output_location, media_type="audio/wav", filename=output_filename)
    
    except Exception as e:
        print(f"❌ Error: {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    # Host 0.0.0.0 agar bisa diakses HP
    uvicorn.run(app, host="0.0.0.0", port=8000)
