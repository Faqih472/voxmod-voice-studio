import 'package:flutter/material.dart';
import 'result_screen.dart'; // Import halaman result

class ProcessingScreen extends StatefulWidget {
  final String characterName;
  const ProcessingScreen({super.key, required this.characterName});

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
    // Simulasi Step AI
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => loadingText = "Memisahkan Vokal...");

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => loadingText = "Menerapkan Suara ${widget.characterName}...");

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => loadingText = "Finalizing...");

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResultScreen(characterName: widget.characterName)),
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
            // Custom Loader
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
            const Text("AI sedang bekerja, mohon tunggu...", style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}