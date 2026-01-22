import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  final String characterName;
  const ResultScreen({super.key, required this.characterName});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool isPlaying = false;
  double pitchValue = 0.0;
  double mixValue = 100.0;

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
            // Waveform Result (Static Image Placeholder)
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
                GestureDetector(
                  onTap: () {
                    setState(() => isPlaying = !isPlaying);
                  },
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

            const SizedBox(height: 40),

            // Sliders (Fine Tuning)
            _buildSlider("Pitch Tuning", pitchValue, -12, 12, (val) => setState(() => pitchValue = val)),
            const SizedBox(height: 20),
            _buildSlider("AI Strength (Mix)", mixValue, 0, 100, (val) => setState(() => mixValue = val)),

            const Spacer(),

            // Share Buttons
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
                    icon: const Icon(Icons.music_note), // Icon TikTok anggap saja
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