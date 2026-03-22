import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({Key? key, required this.currentIndex})
      : super(key: key);

  static const List<_NavItem> _items = [
    _NavItem(
        route: '/my_workout',
        icon: Icons.fitness_center,
        tooltip: 'My Workout'),
    _NavItem(
        route: '/my_meal', icon: Icons.restaurant_menu, tooltip: 'My Meal'),
    _NavItem(route: '/game', icon: Icons.sports_esports, tooltip: 'Game'),
    _NavItem(route: '/edit_avatar', icon: Icons.face, tooltip: 'Wardrobe'),
    _NavItem(
        route: '/dashboard',
        icon: Icons.dashboard_customize,
        tooltip: 'Dashboard'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 92,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 10,
              right: 10,
              bottom: 0,
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildNavIcon(context, _items[0], 0),
                    _buildNavIcon(context, _items[1], 1),
                    const SizedBox(width: 78),
                    _buildNavIcon(context, _items[3], 3),
                    _buildNavIcon(context, _items[4], 4),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -2,
              child: _buildGameButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(BuildContext context, _NavItem item, int index) {
    final selected = currentIndex == index;
    final iconColor = selected ? Colors.blue[700] : Colors.grey[600];

    return Expanded(
      child: IconButton(
        onPressed: () => _onTap(context, item.route),
        tooltip: item.tooltip,
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: selected ? Colors.blue.withValues(alpha: 0.10) : null,
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 23, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildGameButton(BuildContext context) {
    final selected = currentIndex == 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context, _items[2].route),
        borderRadius: BorderRadius.circular(36),
        child: Ink(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: selected
                  ? [const Color(0xFF0D47A1), const Color(0xFF1976D2)]
                  : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child:
              const Icon(Icons.sports_esports, color: Colors.white, size: 34),
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
  final String tooltip;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.tooltip,
  });
}
