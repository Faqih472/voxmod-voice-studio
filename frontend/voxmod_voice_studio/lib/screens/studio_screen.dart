import 'dart:async';
import 'dart:math';
import 'dart:io'; // Wajib untuk cek File
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

// Pastikan import ini sesuai dengan nama file Anda
import 'processing_screen.dart';

class StudioScreen extends StatefulWidget {
  final String characterName;
  const StudioScreen({super.key, required this.characterName});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> with SingleTickerProviderStateMixin {
  // Logic Audio
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  final Logger _logger = Logger();

  // Logic UI
  bool isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Animasi gelombang suara (Fake Visualizer)
    _waveController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000)
    )..repeat();

    _initRecorder();
  }

  // 1. SETUP RECORDER & MINTA IZIN
  Future<void> _initRecorder() async {
    // Minta izin mikrofon saat layar dibuka
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin mikrofon WAJIB diberikan!')),
        );
      }
      return; // Stop jika tidak diizinkan
    }

    await _recorder.openRecorder();
    _isRecorderInitialized = true;
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  // 2. TOGGLE START/STOP
  Future<void> _toggleRecording() async {
    if (!_isRecorderInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorder belum siap, coba restart aplikasi.')),
      );
      return;
    }

    if (_recorder.isStopped) {
      await _startRecording();
    } else {
      await _stopRecording();
    }
  }

  // 3. MULAI REKAM (VERSI PERBAIKAN: AAC)
  Future<void> _startRecording() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();

      // PERUBAHAN 1: Gunakan ekstensi .aac (Lebih stabil di Android)
      final String path = '${tempDir.path}/voxmod_audio.aac';

      await _recorder.startRecorder(
        toFile: path,

        // PERUBAHAN 2: Gunakan Codec AAC ADTS
        // Codec.pcm16WAV sering menghasilkan file kosong di beberapa HP.
        codec: Codec.aacADTS,

        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      );

      setState(() {
        isRecording = true;
        _recordDuration = 0;
      });

      // Update Timer setiap detik
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration++;
        });
      });

      _logger.i("🎙️ Mulai merekam ke: $path");
    } catch (e) {
      _logger.e("❌ Gagal start recording: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal merekam: $e')),
      );
    }
  }

  // 4. STOP REKAM & VALIDASI FILE
  Future<void> _stopRecording() async {
    try {
      String? path = await _recorder.stopRecorder();

      _timer?.cancel();
      setState(() {
        isRecording = false;
      });

      if (path != null) {
        // --- VALIDASI UKURAN FILE ---
        File recordedFile = File(path);
        int fileSize = await recordedFile.length();

        _logger.i("✅ Rekaman selesai.");
        _logger.i("📂 Lokasi: $path");
        _logger.i("📦 Ukuran: $fileSize bytes");

        if (fileSize < 1000) {
          _logger.w("⚠️ PERINGATAN: File terlalu kecil ($fileSize bytes). Suara mungkin tidak masuk.");
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal merekam suara (File Kosong). Cek Izin Mic!')),
            );
          }
          return;
        }
        // ----------------------------

        // NAVIGASI: Kirim file .aac ini ke layar processing
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProcessingScreen(
                characterName: widget.characterName,
                audioPath: path,
              ),
            ),
          );
        }
      }
    } catch (e) {
      _logger.e("❌ Gagal stop: $e");
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)
        ),
        title: Text(widget.characterName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Visualizer (Animated Bars)
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(10, (index) {
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    // Jika merekam, tinggi batang akan acak (efek suara)
                    double height = isRecording
                        ? 20 + Random().nextInt(100).toDouble()
                        : 10;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 10,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent, // Ganti warna sesuai tema
                        borderRadius: BorderRadius.circular(50),
                      ),
                    );
                  },
                );
              }),
            ),
          ),

          // Timer Text
          Text(
            _formatTime(_recordDuration),
            style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white
            ),
          ),

          const Text(
              "Tekan Mic untuk Merekam",
              style: TextStyle(color: Colors.white54)
          ),

          // Tombol Rekam (Main Button)
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isRecording ? 120 : 100,
              width: isRecording ? 120 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.redAccent : const Color(0xFF1E1E2C),
                border: Border.all(
                    color: isRecording ? Colors.red : Colors.blueAccent,
                    width: 3
                ),
                boxShadow: [
                  BoxShadow(
                    color: isRecording
                        ? Colors.redAccent.withOpacity(0.5)
                        : Colors.blueAccent.withOpacity(0.3),
                    blurRadius: isRecording ? 30 : 15,
                  )
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop : Icons.mic,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
