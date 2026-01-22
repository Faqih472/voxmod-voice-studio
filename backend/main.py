import os
import shutil
import torch

# --- 🛠️ BYPASS SECURITY (JANGAN DIHAPUS) ---
original_load = torch.load
def bypass_security_load(*args, **kwargs):
    if 'weights_only' not in kwargs:
        kwargs['weights_only'] = False
    return original_load(*args, **kwargs)
torch.load = bypass_security_load
# -------------------------------------------

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
INDEX_NAME = "Keqing.index"  # Pastikan file ini ada!

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
        # 1. Simpan File
        file_location = os.path.join(UPLOAD_FOLDER, file.filename)
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        output_filename = f"rvc_{file.filename.split('.')[0]}.wav"
        output_location = os.path.join(OUTPUT_FOLDER, output_filename)

        print(f"🔄 Mengubah suara: {file.filename}")

        # 2. LOAD MODEL
        rvc.load_model(MODEL_PATH)

        # --- 🎛️ TUNING AREA (SETTINGS) 🎛️ ---

        # A. SETTING NADA (PITCH) - PENTING!
        # Kalau suara asli kamu COWOK (Berat) -> Pakai 12 (Naik 1 Oktaf)
        # Kalau suara asli kamu CEWEK/ANAK KECIL -> Pakai 0
        # Kalau suaranya kayak TIKUS -> Kurangi (misal jadi 8 atau 5)
        # Kalau suaranya masih NGE-BASS -> Tambah (misal jadi 14 atau 15)
        rvc.f0_up_key = 18

        # B. METODE (Kualitas)
        rvc.f0_method = "rmvpe" # Terbaik untuk suara anime

        # C. INDEX (Aksen Karakter)
        # Kita paksa inject variabel ini secara manual
        if os.path.exists(INDEX_PATH):
            print("✅ Index file ditemukan, menerapkan aksen Keqing...")
            rvc.index_file = INDEX_PATH
            rvc.index_rate = 0.75       # Kekuatan aksen (0.75 standard)
        else:
            print("⚠️ Index file tidak ditemukan! Suara mungkin kurang mirip.")

        # -------------------------------------

        # 3. EKSEKUSI
        rvc.infer_file(
            input_path=file_location,
            output_path=output_location
        )

        print("✅ Selesai! Mengirim audio...")
        return FileResponse(output_location, media_type="audio/wav", filename=output_filename)

    except Exception as e:
        print(f"❌ Error: {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
