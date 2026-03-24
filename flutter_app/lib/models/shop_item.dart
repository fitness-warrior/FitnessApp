import 'package:flutter/material.dart';

class ShopItem {
  final String id; // e.g. "dmg_up", "time_up", "auto_click"
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });
}