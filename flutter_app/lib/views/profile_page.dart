import 'package:flutter/material.dart';
import '../widgets/common/header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: HeaderWithDropdown(
          title: 'Profile',
          onMenuSelected: (value) {
            Navigator.of(context).pushReplacementNamed(
                '/${value.toLowerCase().replaceAll(' ', '_')}');
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person, size: 40, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account details will appear here.',
                style: TextStyle(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
