import 'package:flutter/material.dart';
import '../repositories/exercise_repository.dart';
import '../services/exercise_service.dart';
import '../models/recommendation_profile.dart';
import '../services/recommendation_service.dart';
import '../services/recommendation_storage.dart';

class ExerciseSearchDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onExerciseSelected;
  final List<String>? initialTags;

  const ExerciseSearchDialog({
    Key? key,
    required this.onExerciseSelected,
    this.initialTags,
  }) : super(key: key);

  @override
  State<ExerciseSearchDialog> createState() => _ExerciseSearchDialogState();
}

class _ExerciseSearchDialogState extends State<ExerciseSearchDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recommended = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedArea;
  String? _selectedType;

  static const _bodyAreas = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Full Body',
    'Core',
    'Cardio',
  ];
  static const _types = [
    'Strength',
    'Bodyweight',
    'Isolation',
    'Cardio',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final RecommendationProfile? profile =
          await RecommendationStorage.loadProfile().timeout(
            const Duration(seconds: 5),
          );
      if (profile == null) return;
      final rec = await RecommendationService.getRecommendations(profile).timeout(
            const Duration(seconds: 5),
          );
      final tags =
          (rec['tags'] as List<dynamic>?)?.cast<String>() ?? <String>[];
      if (tags.isEmpty) return;
      final recResults = await ExerciseRepository.listExercises(
              recommendationTags: tags)
          .timeout(
            const Duration(seconds: 10),
          );
      if (mounted) {
        setState(() {
          _recommended = recResults;
        });
      }
    } catch (_) {
      // ignore errors; recommendations are optional
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty &&
        _selectedArea == null &&
        _selectedType == null) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use ExerciseService directly for fast name/area/type searches in the dialog
      final results = await ExerciseService.listExercises(
        name: query.trim().isEmpty ? null : query.trim(),
        area: _selectedArea?.toLowerCase(),
        type: _selectedType?.toLowerCase(),
      ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Search timed out - please try again');
            },
          );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _selectExercise(Map<String, dynamic> exercise) {
    widget.onExerciseSelected(exercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D0D14),
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C2E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search Exercises',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Exercise name',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4A9FFF)),
                  filled: true,
                  fillColor: const Color(0xFF1C1C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4A9FFF), width: 1.5),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                  if (value.length > 2) {
                    _performSearch(value);
                  }
                },
              ),
            ),

            // Filter dropdowns — Body Area & Type
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: const Color(0xFF1C1C2E),
                      ),
                      child: DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF1C1C2E),
                        initialValue: _selectedArea,
                        isDense: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Body Area',
                          labelStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: const Color(0xFF1C1C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ..._bodyAreas.map(
                              (a) => DropdownMenuItem(value: a, child: Text(a))),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedArea = value);
                          _performSearch(_searchController.text);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: const Color(0xFF1C1C2E),
                      ),
                      child: DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF1C1C2E),
                        initialValue: _selectedType,
                        isDense: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Type',
                          labelStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: const Color(0xFF1C1C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ..._types.map(
                              (t) => DropdownMenuItem(value: t, child: Text(t))),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedType = value);
                          _performSearch(_searchController.text);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text('Error: $_error', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
    }

    // If user hasn't typed a query and we have recommendations, show them first
    if (_searchController.text.isEmpty && _recommended.isNotEmpty) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Recommended for you',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _recommended.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final exercise = _recommended[idx];
                final name =
                    exercise['name'] ?? exercise['exer_name'] ?? 'Unknown';
                final area =
                    exercise['area'] ?? exercise['exer_body_area'] ?? 'N/A';
                final type = exercise['type'] ?? exercise['exer_type'] ?? 'N/A';
                return GestureDetector(
                  onTap: () => _selectExercise(exercise),
                  child: SizedBox(
                    width: 220,
                    child: Card(
                      color: const Color(0xFF1C1C2E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(area,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Text(type, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const Spacer(),
                            const Align(
                                alignment: Alignment.bottomRight,
                                child: Text('Add',
                                    style: TextStyle(
                                        color: Color(0xFF4A9FFF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12))),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // ignore: deprecated_member_use
          Divider(color: Colors.white.withValues(alpha: 0.05)),
        ],
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Colors.grey.shade700,
              ),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isEmpty
                    ? 'Start typing to search'
                    : 'No exercises found',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final exercise = _searchResults[index];
        final name = exercise['exer_name'] ?? 'Unknown';
        final area = exercise['exer_body_area'] ?? 'N/A';
        final type = exercise['exer_type'] ?? 'N/A';
        final description = exercise['exer_descrip'] ?? 'No description';
        final equipment = exercise['exer_equip'] ?? '';

        return Card(
          color: const Color(0xFF1C1C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            onTap: () => _selectExercise(exercise),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    _searchChip(area, const Color(0xFF4A9FFF)),
                    const SizedBox(width: 6),
                    _searchChip(type, const Color(0xFF66BB6A)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
                if (equipment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Equipment: $equipment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF4A9FFF)),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _searchChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
