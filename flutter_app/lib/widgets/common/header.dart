import 'package:flutter/material.dart';

class HeaderWithDropdown extends StatelessWidget {
  final String title;
  final void Function(String)? onMenuSelected;

  const HeaderWithDropdown({
    Key? key,
    required this.title,
    this.onMenuSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) {
            if (onMenuSelected != null) {
              onMenuSelected!(value);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'Dashboard',
              child: ListTile(
                leading: Icon(Icons.dashboard),
                title: Text('Dashboard'),
              ),
            ),
            const PopupMenuItem(
              value: 'My Workout',
              child: ListTile(
                leading: Icon(Icons.fitness_center),
                title: Text('My Workout'),
              ),
            ),
            const PopupMenuItem(
              value: 'My Meal',
              child: ListTile(
                leading: Icon(Icons.restaurant),
                title: Text('My Meal'),
              ),
            ),
            const PopupMenuItem(
              value: 'Game',
              child: ListTile(
                leading: Icon(Icons.videogame_asset),
                title: Text('Game'),
              ),
            ),
            const PopupMenuItem(
              value: 'Game equipment',
              child: ListTile(
                leading: Icon(Icons.sports_esports),
                title: Text('Game equipment'),
              ),
            ),
            const PopupMenuItem(
              value: 'Edit Avater',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Avater'),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
