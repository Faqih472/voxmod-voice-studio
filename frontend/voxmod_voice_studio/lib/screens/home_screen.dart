import 'package:flutter/material.dart';
import 'studio_screen.dart'; // Import halaman Studio untuk navigasi

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dummy Data Karakter
  final List<Map<String, dynamic>> characters = [
    {'name': 'Cyborg', 'icon': Icons.android, 'color': Colors.cyan},
    {'name': 'Hantu', 'icon': Icons.mood_bad, 'color': Colors.purple},
    {'name': 'Chipmunk', 'icon': Icons.pest_control_rodent, 'color': Colors.orange},
    {'name': 'News Anchor', 'icon': Icons.mic_external_on, 'color': Colors.blue},
    {'name': 'Anime Girl', 'icon': Icons.face_4, 'color': Colors.pink},
    {'name': 'Deep Voice', 'icon': Icons.graphic_eq, 'color': Colors.teal},
  ];

  int selectedCategoryIndex = 0;
  final List<String> categories = ["All", "Horror", "Fun", "Professional", "Robot"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("VoxMod Studio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting / Banner
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00FFC2), Color(0xFF008F7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Unlock Premium", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("Dapatkan akses ke 50+ Suara Selebriti!", style: TextStyle(color: Colors.black87, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.diamond, color: Colors.black, size: 30),
                ],
              ),
            ),
          ),

          // Categories Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(categories[index]),
                    selected: selectedCategoryIndex == index,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedCategoryIndex = index;
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selectedCategoryIndex == index ? Theme.of(context).primaryColor : Colors.white60,
                    ),
                    backgroundColor: const Color(0xFF1E1E2C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Grid Karakter
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: characters.length,
              itemBuilder: (context, index) {
                return _buildCharacterCard(characters[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(Map<String, dynamic> char) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke Studio Screen membawa data karakter
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudioScreen(characterName: char['name'])),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: char['color'].withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(char['icon'], size: 40, color: char['color']),
            ),
            const SizedBox(height: 15),
            Text(char['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            const Text("AI Model V2", style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}