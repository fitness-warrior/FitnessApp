import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/game_storage.dart';
import '../widgets/common/navbar.dart';

class EditAvatarPage extends StatefulWidget {
  const EditAvatarPage({Key? key}) : super(key: key);

  @override
  State<EditAvatarPage> createState() => _EditAvatarPageState();
}

class _EditAvatarPageState extends State<EditAvatarPage> {
  GameState _state = GameState();

  // A list of all possible costumes in the game
  final List<Map<String, dynamic>> _costumes = [
    {'key': '', 'name': 'Base Uniform', 'icon': Icons.person, 'color': Colors.grey},
    {'key': 'earth', 'name': 'Earth Suit', 'icon': Icons.terrain, 'color': Colors.brown},
    {'key': 'water', 'name': 'Water Suit', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'key': 'fire', 'name': 'Fire Suit', 'icon': Icons.local_fire_department, 'color': Colors.red},
    {'key': 'wind', 'name': 'Wind Suit', 'icon': Icons.air, 'color': Colors.tealAccent},
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final state = await GameStorage.load();
    if (!mounted) return;
    setState(() {
      _state = state;
    });
  }

  void _equip(String key) {
    setState(() {
      // Empty string means default character
      _state.equippedCostume = key.isEmpty ? null : key;
    });
    GameStorage.save(_state);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Costume Equipped!'),
        backgroundColor: Colors.greenAccent,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current equipped key (handle null as empty string to match Base Uniform key)
    final currentEquipped = _state.equippedCostume ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Match the game theme
      appBar: AppBar(
        title: const Text('Wardrobe', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _costumes.length,
        itemBuilder: (context, index) {
          final c = _costumes[index];
          final cKey = c['key'] as String;
          
          // Base uniform is always owned. Others depend on the GameState.
          final isOwned = cKey.isEmpty || _state.ownedCostumes.contains(cKey);
          final isEquipped = currentEquipped == cKey;

          return Card(
            color: isOwned ? Colors.blueGrey[800] : Colors.blueGrey[900]?.withValues(alpha: 0.5),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isEquipped ? const BorderSide(color: Colors.greenAccent, width: 2) : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isOwned ? (c['color'] as Color).withValues(alpha: 0.2) : Colors.black26,
                child: Icon(c['icon'] as IconData, color: isOwned ? (c['color'] as Color) : Colors.white24),
              ),
              title: Text(
                c['name'] as String,
                style: TextStyle(
                  color: isOwned ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                isEquipped ? 'Currently Equipped' : (isOwned ? 'Tap to equip' : 'Defeat boss to unlock'),
                style: TextStyle(color: isEquipped ? Colors.greenAccent : Colors.white54),
              ),
              trailing: isOwned && !isEquipped
                  ? ElevatedButton(
                      onPressed: () => _equip(cKey),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Equip', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  : const SizedBox.shrink(),
              onTap: isOwned && !isEquipped ? () => _equip(cKey) : null,
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3), // Profile/Avatar tab
    );
  }
}
