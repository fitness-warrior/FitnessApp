import 'package:flutter/material.dart';
import '../widgets/common/navbar.dart';

class EditAvatarPage extends StatelessWidget {
  const EditAvatarPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Avatar')),
      body: const Center(
        child: Text(
          'Edit Avatar screen',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }
}
