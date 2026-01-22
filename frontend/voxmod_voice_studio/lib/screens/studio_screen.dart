import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'processing_screen.dart'; // Import halaman processing

class StudioScreen extends StatefulWidget {
  final String characterName;
  const StudioScreen({super.key, required this.characterName});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> with SingleTickerProviderStateMixin {
  bool isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;

  // Dummy waveform animation controller
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      isRecording = !isRecording;
    });

    if (isRecording) {
      // Mulai Timer
      _recordDuration = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration++;
        });
      });
    } else {
      // Stop Timer & Pindah ke Processing
      _timer?.cancel();
      // Simulasi delay sedikit sebelum pindah
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProcessingScreen(characterName: widget.characterName)),
        );
      });
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
          // Visualizer Area
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(10, (index) {
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    // Fake waveform logic logic
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

          // Timer
          Text(
            _formatTime(_recordDuration),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),

          const Text("Tekan untuk merekam, lepas untuk selesai", style: TextStyle(color: Colors.white54)),

          // Tombol Rekam Besar
          GestureDetector(
            onLongPressStart: (_) => _toggleRecording(),
            onLongPressEnd: (_) => _toggleRecording(),
            onTap: () {
              // Fallback kalau user cuma tap sekali (toggle mode)
              _toggleRecording();
            },
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
                    spreadRadius: isRecording ? 10 : 1,
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

          // Tombol Upload File
          TextButton.icon(
            onPressed: () {
              // Logic Upload File
            },
            icon: const Icon(Icons.upload_file, color: Colors.white54),
            label: const Text("Upload Audio File", style: TextStyle(color: Colors.white54)),
          )
        ],
      ),
    );
  }
}