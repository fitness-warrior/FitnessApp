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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500]),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1C1C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Area filter chips
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _areas.length,
              itemBuilder: (context, i) {
                final area = _areas[i];
                final isSelected = area == 'All'
                    ? _selectedArea == null
                    : _selectedArea == area;
                final color = _areaColors[area] ?? const Color(0xFF4A9FFF);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _selectArea(area),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color : const Color(0xFF1C1C2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : const Color(0xFF2A2A3E),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        area,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Text(
                      '${_filtered.length} exercises found',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
