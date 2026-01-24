import 'package:flutter/material.dart';
import 'studio_screen.dart'; // Pastikan StudioScreen sudah di-import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dummy Data Karakter
  final List<Map<String, dynamic>> characters = [
    {'name': 'Anime', 'icon': Icons.face_4, 'color': Colors.pink, 'active': true},
    {'name': 'Vtuber', 'icon': Icons.live_tv, 'color': Colors.indigoAccent, 'active': true}, // ✅ News Anchor diganti Vtuber & Aktif
    {'name': 'Cyborg', 'icon': Icons.android, 'color': Colors.cyan, 'active': false},
    {'name': 'Hantu', 'icon': Icons.mood_bad, 'color': Colors.purple, 'active': false},
    {'name': 'Chipmunk', 'icon': Icons.pest_control_rodent, 'color': Colors.orange, 'active': false},
    {'name': 'Deep Voice', 'icon': Icons.graphic_eq, 'color': Colors.teal, 'active': false},
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
          // Banner Unlock Premium
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

  // --- LOGIC UI CARD ---
  Widget _buildCharacterCard(Map<String, dynamic> char) {
    bool isActive = char['active'];

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${char['name']} belum tersedia (Upcoming Feature)"),
              backgroundColor: Colors.grey[800],
              duration: const Duration(seconds: 1),
            ),
          );
          return;
        }

        // LOGIC NAVIGASI BERDASARKAN KATEGORI
        if (char['name'] == 'Anime') {
          _showAnimeSelectionModal(context);
        } else if (char['name'] == 'Vtuber') {
          _showVtuberSelectionModal(context); // ✅ Buka Modal Vtuber
        }
      },
      child: Opacity(
        opacity: isActive ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isActive ? char['color'].withOpacity(0.5) : Colors.white10,
                width: isActive ? 2 : 1
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: char['color'].withOpacity(0.2),
                  blurRadius: 15,
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
              Text(
                  char['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              const SizedBox(height: 5),
              Text(
                  isActive ? "Available" : "Upcoming",
                  style: TextStyle(
                      color: isActive ? Colors.greenAccent : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================
  // 1. MODAL ANIME (Keqing, Klee)
  // =========================================
  void _showAnimeSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pilih Model Anime", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),

              _buildModelOption(
                  context, "Keqing (Genshin)", Icons.bolt, Colors.purpleAccent,
                      () { Navigator.pop(context); _navigateToStudio("Keqing", "Keqing_e500_s13000.pth", "Keqing.index"); }
              ),
              const SizedBox(height: 10),
              _buildModelOption(
                  context, "Klee (Genshin)", Icons.local_fire_department, Colors.redAccent,
                      () { Navigator.pop(context); _navigateToStudio("Klee", "Klee_280e_6440s.pth", "klee.index"); }
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // =========================================
  // 2. MODAL VTUBER (Zeta)
  // =========================================
  void _showVtuberSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pilih Model Vtuber", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),

              // ✅ ZETA OPTION
              _buildModelOption(
                  context,
                  "Vestia Zeta (Hololive)",
                  Icons.policy, // Icon agen rahasia/kucing
                  Colors.grey,
                      () {
                    Navigator.pop(context);
                    // Masukkan Nama File Persis Sesuai Request
                    _navigateToStudio(
                        "Zeta",
                        "zetaTest.pth",
                        "added_IVF462_Flat_nprobe_1_zetaTest_v2.index"
                    );
                  }
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelOption(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: const Text("High Quality RVC V2", style: TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
    );
  }

  void _navigateToStudio(String name, String modelFile, String indexFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StudioScreen(
            characterName: name,
            modelFilename: modelFile,
            indexFilename: indexFile,
          )
      ),
    );
  }
}
