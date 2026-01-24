import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:share_plus/share_plus.dart'; // Untuk Share
import 'package:permission_handler/permission_handler.dart'; // Untuk Izin Save
import 'package:intl/intl.dart'; // Untuk penamaan file unik

import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final String characterName;
  final String currentAudioPath; // Path Audio AI saat ini
  final String originalAudioPath; // Path Audio Mentah (Source)
  final String modelFilename;
  final String indexFilename;
  final double initialPitch;

  const ResultScreen({
    super.key,
    required this.characterName,
    required this.currentAudioPath,
    required this.originalAudioPath,
    required this.modelFilename,
    required this.indexFilename,
    this.initialPitch = 0,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final ApiService _apiService = ApiService();

  bool isPlaying = false;
  bool isRegenerating = false;
  late String activeAudioPath;
  late double pitchValue;

  @override
  void initState() {
    super.initState();
    activeAudioPath = widget.currentAudioPath;
    pitchValue = widget.initialPitch;
    _player.openPlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (isPlaying) {
      await _player.stopPlayer();
      setState(() => isPlaying = false);
    } else {
      setState(() => isPlaying = true);
      await _player.startPlayer(
          fromURI: activeAudioPath,
          whenFinished: () {
            setState(() => isPlaying = false);
          }
      );
    }
  }

  Future<void> _regenerateAudio() async {
    setState(() {
      isRegenerating = true;
      if (isPlaying) {
        _player.stopPlayer();
        isPlaying = false;
      }
    });

    String? newPath = await _apiService.convertVoice(
      widget.originalAudioPath,
      widget.characterName,
      widget.modelFilename,
      widget.indexFilename,
      pitchValue.toInt(),
    );

    if (mounted) {
      setState(() {
        isRegenerating = false;
        if (newPath != null) {
          activeAudioPath = newPath;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pitch berhasil diupdate!"), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update suara."), backgroundColor: Colors.red));
        }
      });
    }
  }

  // --- 📤 FUNGSI SHARE (WHATSAPP, TIKTOK, DLL) ---
  Future<void> _shareFile() async {
    if (isRegenerating) return; // Cegah share saat loading

    try {
      final file = File(activeAudioPath);
      if (await file.exists()) {
        // Menggunakan library share_plus
        await Share.shareXFiles(
            [XFile(activeAudioPath)],
            text: "Cek suara AI ${widget.characterName} buatanku!"
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File audio tidak ditemukan!")));
      }
    } catch (e) {
      print("Error Share: $e");
    }
  }

  // --- 💾 FUNGSI SIMPAN KE DOWNLOADS ---
  // --- 💾 FUNGSI SIMPAN (FIXED FOR ANDROID 11/12/13+) ---
  Future<void> _saveFile() async {
    if (isRegenerating) return;

    // 1. Cek Permission (Logic Android 11+ vs Lama)
    if (Platform.isAndroid) {
      // Cek Manage External Storage (Android 11+)
      if (await Permission.manageExternalStorage.status.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      // Cek Storage Biasa (Fallback)
      if (await Permission.storage.status.isDenied) {
        await Permission.storage.request();
      }
    }

    try {
      // 2. CEK APAKAH FILE SUMBER ADA? (Ini kunci masalahmu)
      File sourceFile = File(activeAudioPath);
      if (!await sourceFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: File Audio Sumber Hilang/Corrupt!"), backgroundColor: Colors.red)
        );
        return;
      }

      int fileSize = await sourceFile.length();
      if (fileSize < 1000) { // Kalau di bawah 1KB, berarti file rusak/kosong
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: File Audio Kosong (0 detik)."), backgroundColor: Colors.red)
        );
        return;
      }

      // 3. Tentukan Path Download
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = "VoxMod_${widget.characterName}_$timestamp.wav";

      // Hardcode path Download Android (Paling aman)
      Directory downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        downloadDir = Directory('/storage/emulated/0/Downloads'); // Coba pakai 's'
      }

      final String newPath = "${downloadDir.path}/$fileName";

      // 4. Salin File
      await sourceFile.copy(newPath);

      // 5. MEDIA SCANNER (Agar muncul di Gallery/File Manager HP)
      // Kita pakai trik sederhana: Kirim broadcast agar HP scan file baru
      try {
        if (Platform.isAndroid) {
          // Jika mau lebih canggih bisa pakai package 'media_scanner',
          // tapi biasanya copy ke Download folder sudah cukup terbaca.
        }
      } catch (_) {}

      print("File tersimpan di: $newPath"); // Cek di Terminal

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tersimpan di Download:\n$fileName"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

    } catch (e) {
      print("SAVE ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal Simpan: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Helper untuk membuka Settings jika izin ditolak permanen
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Izin Ditolak"),
        content: const Text("Aplikasi ini membutuhkan izin 'Kelola Semua File' (All Files Access) untuk menyimpan hasil ke folder Download. Silakan aktifkan di Pengaturan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings(); // Membuka pengaturan HP
            },
            child: const Text("Buka Pengaturan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Studio Hasil", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- VISUALIZER ---
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: isRegenerating
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : const Center(child: Icon(Icons.graphic_eq, size: 80, color: Colors.blueAccent)),
            ),

            const SizedBox(height: 30),

            // --- PLAYER CONTROLS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.replay_10, color: Colors.white54, size: 30), onPressed: () {}),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: isRegenerating ? null : _togglePlay,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                        boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 20)]
                    ),
                    child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 35),
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(icon: const Icon(Icons.forward_10, color: Colors.white54, size: 30), onPressed: () {}),
              ],
            ),

            const SizedBox(height: 10),
            Text(isRegenerating ? "Sedang memproses ulang..." : "Pitch Aktif: ${pitchValue.toInt()}",
                style: const TextStyle(color: Colors.white54, fontSize: 12)),

            const SizedBox(height: 40),

            // --- EDITOR SECTION ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Ubah Pitch (Nada)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: isRegenerating ? null : _regenerateAudio,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("Terapkan", style: TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blueAccent,
                      inactiveTrackColor: Colors.black26,
                      thumbColor: Colors.white,
                      overlayColor: Colors.blueAccent.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: pitchValue,
                      min: -12,
                      max: 24,
                      divisions: 24,
                      label: pitchValue.toInt().toString(),
                      onChanged: (val) {
                        setState(() => pitchValue = val);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("-12 (Berat)", style: TextStyle(color: Colors.white24, fontSize: 10)),
                        Text("0 (Normal)", style: TextStyle(color: Colors.white24, fontSize: 10)),
                        Text("+24 (Imut)", style: TextStyle(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const Spacer(),

            // --- SHARE & SAVE BUTTONS (SUDAH AKTIF) ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareFile, // <--- Panggil Fungsi Share
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text("Share"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveFile, // <--- Panggil Fungsi Save
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: const Text("Simpan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
