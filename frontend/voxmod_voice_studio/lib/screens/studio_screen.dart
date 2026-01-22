import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'; // Library Audio
import 'package:permission_handler/permission_handler.dart'; // Izin
import 'package:path_provider/path_provider.dart'; // Path Folder
import 'package:logger/logger.dart'; // Debugger
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
  String? _recordedFilePath;
  final Logger _logger = Logger();

  // Logic UI
  bool isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    _initRecorder(); // Inisialisasi Perekam saat buka halaman
  }

  // 1. SETUP RECORDER & MINTA IZIN
  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin mikrofon diperlukan untuk merekam!')),
        );
      }
      return; // Stop jika tidak ada izin
    }

    await _recorder.openRecorder();
    _isRecorderInitialized = true;
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 100)); // Update UI tiap 100ms
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    _recorder.closeRecorder(); // Wajib tutup recorder biar memori gak bocor
    super.dispose();
  }

  // 2. LOGIC MULAI & STOP REKAM
  Future<void> _toggleRecording() async {
    if (!_isRecorderInitialized) return;

    if (_recorder.isStopped) {
      await _startRecording();
    } else {
      await _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      // Cari lokasi folder temporary di HP
      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/voxmod_audio.aac'; // Format AAC lebih ringan

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS, // Codec standar HP
      );

      setState(() {
        isRecording = true;
        _recordDuration = 0;
      });

      // Timer visual
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration++;
        });
      });

      _logger.i("Mulai merekam di: $path");

    } catch (e) {
      _logger.e("Gagal merekam: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _recorder.stopRecorder();

      _timer?.cancel();
      setState(() {
        isRecording = false;
        _recordedFilePath = path;
      });

      _logger.i("Rekaman selesai. File disimpan di: $path");

      // Pindah ke Processing Screen membawa Path File
      if (path != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(
              characterName: widget.characterName,
              audioPath: path, // Kirim path file asli
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e("Gagal stop: $e");
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text(widget.characterName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Visualizer (Masih Fake Animation, tapi logic rekam sudah asli)
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(10, (index) {
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    double height = isRecording
                        ? 20 + Random().nextInt(100).toDouble()
                        : 10;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 10,
                      height: height,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    );
                  },
                );
              }),
            ),
          ),

          Text(
            _formatTime(_recordDuration),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),

          const Text("Tekan untuk merekam, tekan lagi untuk stop", style: TextStyle(color: Colors.white54)),

          // Tombol Rekam
          GestureDetector(
            onTap: _toggleRecording, // Tap sekali untuk start/stop
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isRecording ? 120 : 100,
              width: isRecording ? 120 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.redAccent : const Color(0xFF1E1E2C),
                border: Border.all(
                    color: isRecording ? Colors.red : Theme.of(context).primaryColor,
                    width: 3
                ),
                boxShadow: [
                  BoxShadow(
                    color: isRecording ? Colors.redAccent.withOpacity(0.5) : Theme.of(context).primaryColor.withOpacity(0.3),
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

          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file, color: Colors.white54),
            label: const Text("Upload Audio File", style: TextStyle(color: Colors.white54)),
          )
        ],
      ),
    );
  }
}