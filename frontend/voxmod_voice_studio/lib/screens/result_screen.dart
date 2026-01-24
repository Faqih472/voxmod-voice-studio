
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'; // Library Audio

class ResultScreen extends StatefulWidget {
  final String characterName;
  final String audioPath; // Menerima path audio

  const ResultScreen({
    super.key,
    required this.characterName,
    required this.audioPath,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer(); // Player Audio
  bool isPlaying = false;
  double pitchValue = 0.0;
  double mixValue = 100.0;

  @override
  void initState() {
    super.initState();
    _player.openPlayer(); // Buka sesi player
  }

  @override
  void dispose() {
    _player.closePlayer(); // Tutup sesi saat keluar
    super.dispose();
  }

  // LOGIC PLAY / STOP
  Future<void> _togglePlay() async {
    if (isPlaying) {
      await _player.stopPlayer();
      setState(() => isPlaying = false);
    } else {
      setState(() => isPlaying = true);

      // Hitung speed berdasarkan slider
      double speed = 1.0 + (pitchValue / 20);
      if (speed < 0.5) speed = 0.5;

      await _player.startPlayer(
          fromURI: widget.audioPath,
          whenFinished: () {
            setState(() => isPlaying = false);
          }
      );
      // Set speed segera setelah start
      await _player.setSpeed(speed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: const Text("Hasil Konversi", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () {}, child: const Text("Save", style: TextStyle(color: Color(0xFF00FFC2), fontWeight: FontWeight.bold)))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: Icon(Icons.graphic_eq, size: 80, color: Colors.white12)),
            ),

            const SizedBox(height: 30),

            // Player Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.skip_previous, size: 30), onPressed: () {}),
                const SizedBox(width: 20),

                // TOMBOL PLAY REAL
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                          )
                        ]
                    ),
                    child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 30),
                  ),
                ),

                const SizedBox(width: 20),
                IconButton(icon: const Icon(Icons.skip_next, size: 30), onPressed: () {}),
              ],
            ),

            const SizedBox(height: 20),
            Text("Memutar File: ...${widget.audioPath.substring(widget.audioPath.length - 15)}",
                style: const TextStyle(color: Colors.white24, fontSize: 12)),

            const SizedBox(height: 40),

            _buildSlider("Pitch Tuning", pitchValue, -12, 12, (val) {
              setState(() => pitchValue = val);
              // LOGIC UBAH PITCH (SPEED):
              // Nilai 0 = 1.0 (Normal)
              // Nilai 12 = ~1.5 (Cepat/Chipmunk)
              // Nilai -12 = ~0.5 (Lambat/Berat)
              double speed = 1.0 + (val / 20);
              if (speed < 0.5) speed = 0.5; // Batas minimum

              if (isPlaying) {
                _player.setSpeed(speed); // Ubah speed saat play
              }
            }),
            _buildSlider("AI Strength (Mix)", mixValue, 0, 100, (val) => setState(() => mixValue = val)),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text("WhatsApp"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                    icon: const Icon(Icons.music_note),
                    label: const Text("TikTok"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
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

  Widget _buildSlider(String label, double val, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(val.toStringAsFixed(1), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: val,
          min: min,
          max: max,
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Colors.white10,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
