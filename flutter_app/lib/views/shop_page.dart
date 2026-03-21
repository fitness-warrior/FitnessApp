import 'package:flutter/material.dart';
import '../data/demo_shop_items.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: demoShopItems.map((item) {
          return Card(
            child: Center(
              child: Text(item.name),
            ),
          );
        }).toList(),
      ),
    );
  }
}