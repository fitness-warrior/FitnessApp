import 'package:flutter/material.dart';
import '../models/shop_item.dart';

// --- Step 13.1: Actual Gameplay Upgrades ---
final demoShopItems = [
  const ShopItem(
    id: 'dmg_up',
    name: 'Tap Damage Up',
    description: '+5 Damage per Tap',
    price: 100,
    icon: Icons.sports_martial_arts,
    color: Colors.red,
  ),
  const ShopItem(
    id: 'time_up',
    name: 'Extra Time',
    description: '+10 Seconds to Clock',
    price: 150,
    icon: Icons.timer,
    color: Colors.blue,
  ),
  const ShopItem(
    id: 'auto_click',
    name: 'Auto Clicker',
    description: 'Deals 5 damage every second',
    price: 300,
    icon: Icons.touch_app,
    color: Colors.green,
  ),
];