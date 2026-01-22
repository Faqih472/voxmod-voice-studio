import 'package:flutter/material.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String characterName;
  final String audioPath; // TAMBAHAN: Menerima path audio

  const ProcessingScreen({
    super.key,
    required this.characterName,
    required this.audioPath,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String loadingText = "Mengunggah Audio...";

  @override
  void initState() {
    super.initState();
    _startFakeProcess();
  }

  void _startFakeProcess() async {
    // Simulasi Processing AI (Nanti di sini kita panggil Server Python)
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => loadingText = "Memproses Suara ${widget.characterName}...");

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => loadingText = "Finalizing...");

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      // Oper file path ke layar hasil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            characterName: widget.characterName,
            audioPath: widget.audioPath, // Teruskan file aslinya
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150, height: 150,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    backgroundColor: Colors.white10,
                  ),
                ),
                const Icon(Icons.psychology, size: 60, color: Colors.white24),
              ],
            ),
            const SizedBox(height: 40),
            Text(loadingText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("File: ${widget.audioPath.split('/').last}", style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}