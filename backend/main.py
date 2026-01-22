import os
import shutil
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import uvicorn

app = FastAPI()

# 1. Izin Akses (Biar HP bisa ngobrol sama Laptop)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Folder untuk simpan file sementara
UPLOAD_FOLDER = "uploads"
OUTPUT_FOLDER = "outputs"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

@app.get("/")
def home():
    return {"status": "VoxMod AI Server is Running!"}

@app.post("/convert")
async def convert_voice(
    file: UploadFile = File(...),
    character: str = Form(...)
):
    print(f"📥 Menerima file: {file.filename} | Karakter: {character}")
    
    # 1. Simpan file asli dari Flutter
    file_location = f"{UPLOAD_FOLDER}/{file.filename}"
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    print(f"💾 File tersimpan di: {file_location}")

    # ==========================================
    # DISINI NANTI LOGIC AI AKAN BEKERJA
    # (Sementara kita 'bypass' dulu: Kirim balik file aslinya)
    # ==========================================
    
    # Simulasi proses (misal file output namanya beda)
    output_filename = f"processed_{file.filename}"
    output_location = f"{OUTPUT_FOLDER}/{output_filename}"
    
    # Copy file asli ke folder output (Pura-pura udah diedit AI)
    shutil.copy(file_location, output_location)
    
    print(f"📤 Mengirim balik: {output_location}")
    
    # 2. Return URL/File ke Flutter
    # Kita langsung kirim filenya sebagai response stream
    return FileResponse(output_location, media_type="audio/aac", filename=output_filename)

if __name__ == "__main__":
    # Host 0.0.0.0 biar bisa diakses dari HP/Emulator
    uvicorn.run(app, host="0.0.0.0", port=8000)