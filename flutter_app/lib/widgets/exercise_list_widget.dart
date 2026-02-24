import 'package:flutter/material.dart';
import 'package:fitness_app_flutter/services/exercise_service.dart';

/// Widget for browsing exercises
class ExerciseListWidget extends StatefulWidget {
  const ExerciseListWidget({Key? key}) : super(key: key);

  @override
  State<ExerciseListWidget> createState() => _ExerciseListWidgetState();
}

class _ExerciseListWidgetState extends State<ExerciseListWidget> {
  List<Map<String, dynamic>> _exercises = [];
  bool _loading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedArea;
  String? _selectedType;
  List<String> _selectedEquipment = [];

  final List<String> _bodyAreas = [
    'chest',
    'back',
    'legs',
    'arms',
    'shoulders',
    'core',
    'full body',
  ];

  final List<String> _types = ['strength', 'cardio'];

  final List<String> _equipment = [
    'Bodyweight Only',
    'Dumbbells',
    'Barbells',
    'Resistance Bands',
    'Gym Machines',
    'Cardio Machines',
  ];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final exercises = await ExerciseService.listExercises(
        name: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        area: _selectedArea,
        type: _selectedType,
        equipment: _selectedEquipment.isEmpty ? null : _selectedEquipment,
      );
      setState(() {
        _exercises = exercises;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedArea = null;
      _selectedType = null;
      _selectedEquipment.clear();
      _searchController.clear();
    });
    _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilters(),
        Expanded(child: _buildExerciseList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search exercises',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadExercises();
                  },
                )
              : null,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _loadExercises(),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildAreaFilter(),
            const SizedBox(height: 8),
            _buildTypeFilter(),
            const SizedBox(height: 8),
            Text(
              'Equipment',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            _buildEquipmentFilter(),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedArea,
      decoration: const InputDecoration(
        labelText: 'Body Area',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All Areas'),
        ),
        ..._bodyAreas.map((area) => DropdownMenuItem(
              value: area,
              child: Text(area),
            )),
      ],
      onChanged: (value) {
        setState(() => _selectedArea = value);
        _loadExercises();
      },
    );
  }

  Widget _buildTypeFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: const InputDecoration(
        labelText: 'Type',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All Types'),
        ),
        ..._types.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )),
      ],
      onChanged: (value) {
        setState(() => _selectedType = value);
        _loadExercises();
      },
    );
  }

  Widget _buildEquipmentFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: _equipment.map((equip) {
        final isSelected = _selectedEquipment.contains(equip);
        return FilterChip(
          label: Text(equip, style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedEquipment.add(equip);
              } else {
                _selectedEquipment.remove(equip);
              }
            });
            _loadExercises();
          },
        );
      }).toList(),
    );
  }

  Widget _buildExerciseList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

  Widget _buildExerciseList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExercises,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_exercises.isEmpty) {
      return const Center(child: Text('No exercises found'));
    }

    return ListView.builder(
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return ListTile(
          title: Text(exercise['exer_name'] ?? 'Unknown'),
          subtitle: Text(exercise['exer_body_area'] ?? 'N/A'),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }
}
