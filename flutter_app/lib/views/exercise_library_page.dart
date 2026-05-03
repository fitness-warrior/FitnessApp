import 'package:flutter/material.dart';
import '../data/exercise_db.dart';

class ExerciseLibraryPage extends StatefulWidget {
  const ExerciseLibraryPage({Key? key}) : super(key: key);

  @override
  State<ExerciseLibraryPage> createState() => _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends State<ExerciseLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allExercises = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _selectedArea;

  static const List<String> _areas = [
    'All', 'Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core', 'Cardio',
  ];

  static const Map<String, Color> _areaColors = {
    'Chest':     Color(0xFFEF5350),
    'Back':      Color(0xFFAB47BC),
    'Shoulders': Color(0xFF42A5F5),
    'Arms':      Color(0xFF26C6DA),
    'Legs':      Color(0xFF66BB6A),
    'Core':      Color(0xFFFFA726),
    'Cardio':    Color(0xFFEC407A),
  };

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await ExerciseDb.instance.listExercises();
      if (!mounted) return;
      setState(() {
        _allExercises = exercises;
        _filtered = exercises;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _allExercises.where((ex) {
        final name = (ex['exer_name'] ?? '').toString().toLowerCase();
        final area = (ex['exer_body_area'] ?? '').toString();
        final matchesSearch = query.isEmpty || name.contains(query);
        final matchesArea = _selectedArea == null ||
            _selectedArea == 'All' ||
            area.toLowerCase() == _selectedArea!.toLowerCase();
        return matchesSearch && matchesArea;
      }).toList();
    });
  }

  void _selectArea(String area) {
    setState(() => _selectedArea = area == 'All' ? null : area);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Exercise Library',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Text(
                '${_allExercises.length} exercises loaded',
                style: const TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}
