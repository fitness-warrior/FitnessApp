import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({Key? key, required this.currentIndex})
      : super(key: key);

  static const List<_NavItem> _items = [
    _NavItem(
      route: '/my_workout',
      icon: Icons.fitness_center,
      label: 'Workout',
      activeColor: Color(0xFF4A9FFF),
    ),
    _NavItem(
      route: '/dashboard',
      icon: Icons.home_rounded,
      label: 'Home',
      activeColor: Color(0xFF4A9FFF),
    ),
    _NavItem(
      route: '/my_meal',
      icon: Icons.apple,
      label: 'Nutrition',
      activeColor: Color(0xFFEF5350),
    ),
    _NavItem(
      route: '/profile',
      icon: Icons.person_rounded,
      label: 'Profile',
      activeColor: Color(0xFFAB47BC),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: _items.asMap().entries.map((entry) {
            return _buildNavItem(context, entry.value, entry.key);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem item, int index) {
    final selected = currentIndex == index;
    final color = selected ? item.activeColor : const Color(0xFF6B6B80);

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, item.route),
        splashColor: item.activeColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected
                    ? item.activeColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 24, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.of(context).pushReplacementNamed(route);
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;
  final Color activeColor;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}
