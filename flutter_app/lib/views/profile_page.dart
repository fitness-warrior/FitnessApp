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
      body: const SizedBox.shrink(),
    );
  }
}
