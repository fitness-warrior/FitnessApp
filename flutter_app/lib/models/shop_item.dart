import 'package:flutter/material.dart';

class ShopItem {
  final String name;
  final int price;
  final IconData icon;
  final Color color;

  const ShopItem({
    required this.name,
    required this.price,
    required this.icon,
    required this.color,
  });
}