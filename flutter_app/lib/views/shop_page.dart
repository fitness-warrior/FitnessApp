import 'package:flutter/material.dart';
import '../data/demo_shop_items.dart';
import '../models/game_state.dart';
import '../services/game_storage.dart';
import '../widgets/common/navbar.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  GameState _state = GameState();

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

  void _buyItem(String id, int price) {
    if (_state.coins >= price) {
      setState(() {
        _state.coins -= price;
        _state.upgrades[id] = (_state.upgrades[id] ?? 0) + 1;
      });
      GameStorage.save(_state);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Upgrade Purchased!'),
          backgroundColor: Colors.greenAccent[700],
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins!'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Match game page darkness
      appBar: AppBar(
        title: const Text('Upgrade Shop', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${_state.coins}', style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75, // Make cards a bit taller to fit description/button
        children: demoShopItems.map((item) {
          final currentLevel = _state.upgrades[item.id] ?? 0;
          final canAfford = _state.coins >= item.price;
          
          return Card(
            color: Colors.blueGrey[800],
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 28, color: item.color),
                  ),
                  
                  // Label & Level
                  Column(
                    children: [
                      Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 2),
                      Text('Level $currentLevel', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  
                  // Description
                  Text(item.description, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center, maxLines: 2),
                  
                  // Buy Button
                  ElevatedButton(
                    onPressed: () => _buyItem(item.id, item.price),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? Colors.amber : Colors.grey[700],
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 36),
                      padding: EdgeInsets.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monetization_on, size: 16, color: canAfford ? Colors.black87 : Colors.white54),
                        const SizedBox(width: 4),
                        Text('${item.price}', style: TextStyle(fontWeight: FontWeight.bold, color: canAfford ? Colors.black : Colors.white54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1), // Assuming Shop is index 1
    );
  }
}