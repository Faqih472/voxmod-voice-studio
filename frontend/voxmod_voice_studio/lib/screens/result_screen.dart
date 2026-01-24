import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../services/api_service.dart'; // Import API Service

//update pitch

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
  bool isRegenerating = false; // Loading saat ubah pitch
  late String activeAudioPath; // Audio yang sedang aktif diputar
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
          fromURI: activeAudioPath, // Putar file yang aktif
          whenFinished: () {
            setState(() => isPlaying = false);
          }
      );
    }
  }

  // 🔥 FITUR UTAMA: REQUEST ULANG KE PYTHON
  Future<void> _regenerateAudio() async {
    setState(() {
      isRegenerating = true;
      if (isPlaying) {
        _player.stopPlayer();
        isPlaying = false;
      }
    });

    // Panggil API lagi dengan Pitch Baru + File Original (Bukan file AI)
    String? newPath = await _apiService.convertVoice(
      widget.originalAudioPath, // Pakai source asli
      widget.characterName,
      widget.modelFilename,
      widget.indexFilename,
      pitchValue.toInt(), // Kirim nilai slider baru
    );

    if (mounted) {
      setState(() {
        isRegenerating = false;
        if (newPath != null) {
          activeAudioPath = newPath; // Update file yang akan diputar
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pitch berhasil diupdate!"), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update suara."), backgroundColor: Colors.red));
        }
      });
    }
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
                      // Tombol Terapkan (Hanya aktif jika tidak loading)
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

                  // Slider Pitch
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
                        Text("+12 (Imut)", style: TextStyle(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const Spacer(),

            // --- SHARE BUTTONS ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
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
                    onPressed: () {},
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
