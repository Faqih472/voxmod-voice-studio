import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

// Import Service & Halaman Hasil
import '../services/api_service.dart';
import 'result_screen.dart';

class StudioScreen extends StatefulWidget {
  final String characterName;
  final String modelFilename;
  final String indexFilename;

  const StudioScreen({
    super.key,
    required this.characterName,
    required this.modelFilename,
    required this.indexFilename,
  });

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> with SingleTickerProviderStateMixin {
  // Logic Audio
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  final Logger _logger = Logger();

  // Logic API
  final ApiService _apiService = ApiService();

  // Logic UI
  bool isRecording = false;
  bool isProcessing = false;
  String processingText = "";

  Timer? _timer;
  int _recordDuration = 0;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000)
    )..repeat();

    _initRecorder();
  }

  Future<void> _initRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin mikrofon WAJIB diberikan!')),
        );
      }
      return;
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

  // --- LOGIC RECORDING ---

  Future<void> _toggleRecording() async {
    if (isProcessing) return;

    if (!_isRecorderInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recorder belum siap.')));
      return;
    }

    if (_recorder.isStopped) {
      await _startRecording();
    } else {
      await _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/voxmod_audio.aac';

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      );

      setState(() {
        isRecording = true;
        _recordDuration = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordDuration++);
      });

    } catch (e) {
      _logger.e("❌ Gagal start: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _recorder.stopRecorder();
      _timer?.cancel();
      setState(() => isRecording = false);

      if (path != null) {
        File recordedFile = File(path);
        int fileSize = await recordedFile.length();

        if (fileSize < 1000) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suara kosong/terlalu pendek.')));
          return;
        }

        // Langsung proses setelah stop
        _processAudio(path);
      }
    } catch (e) {
      _logger.e("❌ Gagal stop: $e");
    }
  }

  // --- LOGIC API / PROCESSING ---

  Future<void> _processAudio(String rawAudioPath) async {
    setState(() {
      isProcessing = true;
      processingText = "Mengirim ke AI...";
    });

    // 1. Tentukan Default Pitch awal
    // Kita set 12 (untuk Cowok -> Anime Girl) sebagai default convert pertama.
    // Nanti user bisa ubah di ResultScreen.
    int initialPitch = 12;

    // 2. Panggil API
    String? resultPath = await _apiService.convertVoice(
      rawAudioPath,
      widget.characterName,
      widget.modelFilename,
      widget.indexFilename,
      initialPitch,
    );

    if (!mounted) return;

    if (resultPath != null) {
      setState(() => processingText = "Berhasil! Membuka...");
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Navigasi ke Result Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            characterName: widget.characterName,
            currentAudioPath: resultPath,    // File Hasil AI
            originalAudioPath: rawAudioPath, // [PENTING] File Mentah untuk diedit ulang
            modelFilename: widget.modelFilename,
            indexFilename: widget.indexFilename,
            initialPitch: initialPitch.toDouble(),
          ),
        ),
      );
    } else {
      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal koneksi ke Server Python."),
          backgroundColor: Colors.red,
        ),
      );
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
            onPressed: () => !isProcessing ? Navigator.pop(context) : null
        ),
        title: Text(widget.characterName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Stack(
        children: [
          // 1. LAYER UTAMA (Recording UI Clean)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // --- VISUALIZER ---
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(10, (index) {
                    return AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        double height = isRecording
                            ? 20 + Random().nextInt(80).toDouble()
                            : 10;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 10,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),

              // --- TIMER & TOMBOL ---
              Column(
                children: [
                  Text(
                    _formatTime(_recordDuration),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                      isRecording ? "Sedang Merekam..." : "Tekan Mic untuk Merekam",
                      style: const TextStyle(color: Colors.white54)
                  ),
                  const SizedBox(height: 40),

                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: isRecording ? 120 : 100,
                      width: isRecording ? 120 : 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRecording ? Colors.redAccent : const Color(0xFF1E1E2C),
                        border: Border.all(color: isRecording ? Colors.red : Colors.blueAccent, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: isRecording ? Colors.redAccent.withOpacity(0.5) : Colors.blueAccent.withOpacity(0.3),
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
            ],
          ),

          // 2. LAYER OVERLAY (Muncul saat Processing)
          if (isProcessing)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blueAccent),
                  const SizedBox(height: 20),
                  Text(
                      processingText,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
