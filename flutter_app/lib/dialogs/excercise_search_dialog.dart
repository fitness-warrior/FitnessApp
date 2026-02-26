import 'package:flutter/material.dart';
import '../services/exercise_service.dart';

class ExerciseSearchDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onExerciseSelected;

  const ExerciseSearchDialog({
    Key? key,
    required this.onExerciseSelected,
  }) : super(key: key);

  @override
  State<ExerciseSearchDialog> createState() => _ExerciseSearchDialogState();
}

class _ExerciseSearchDialogState extends State<ExerciseSearchDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search for an exercise'),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter exercise name',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String searchQuery = _searchController.text;
                if (searchQuery.isNotEmpty) {
                  // Perform search logic
                  print('Searching for: $searchQuery');
                  widget.onExerciseSelected({'exer_name': searchQuery});
                  Navigator.pop(context);
                }
              },
              child: Text('Search'),
            ),
          ],
        ),
      ),
    );
  }
}
