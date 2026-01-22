import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Import Service
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String characterName;
  final String audioPath;

  const ProcessingScreen({
    super.key,
    required this.characterName,
    required this.audioPath,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String loadingText = "Menghubungkan ke Server...";
  final ApiService _apiService = ApiService(); // Panggil Service

  @override
  void initState() {
    super.initState();
    _startRealProcess(); // Ganti jadi Real Process
  }

  void _startRealProcess() async {
    // 1. Update UI
    setState(() => loadingText = "Mengirim Audio ke Server...");

    // 2. Panggil API (Ini proses kirim-terima file)
    String? resultPath = await _apiService.convertVoice(widget.audioPath, widget.characterName);

    if (!mounted) return;

    if (resultPath != null) {
      // 3. JIKA SUKSES
      setState(() => loadingText = "Selesai! Membuka hasil...");
      await Future.delayed(const Duration(milliseconds: 500)); // Delay dikit biar mulus

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            characterName: widget.characterName,
            audioPath: resultPath, // Pakai FILE BARU dari server
          ),
        ),
      );
    } else {
      // 4. JIKA GAGAL
      setState(() => loadingText = "Gagal Terhubung ke Server 😢");

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal koneksi. Pastikan IP benar & Server Python nyala."),
            backgroundColor: Colors.red,
          )
      );

      // Tunggu 2 detik lalu kembali
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... Bagian build UI biarkan sama seperti sebelumnya ...
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(height: 20),
            Text(loadingText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}