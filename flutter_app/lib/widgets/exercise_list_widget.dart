import 'package:flutter/material.dart';
import 'package:fitness_app_flutter/repositories/exercise_repository.dart';
import 'package:fitness_app_flutter/models/recommendation_profile.dart';

/// Widget for browsing exercises
class ExerciseListWidget extends StatefulWidget {
  /// Optional recommendation tags (from RecommendationService) to surface
  /// a "Recommended for you" section and to score items.
  final List<String>? recommendationTags;

  /// Optional full recommendation profile. When provided and
  /// [recommendationTags] is null, tags are derived from the profile's
  /// goal, experience and equipment fields.
  final RecommendationProfile? recommendationProfile;

  const ExerciseListWidget({
    Key? key,
    this.recommendationTags,
    this.recommendationProfile,
  }) : super(key: key);

  @override
  State<ExerciseListWidget> createState() => _ExerciseListWidgetState();
}

class _ExerciseListWidgetState extends State<ExerciseListWidget> {
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _recommendedExercises = [];
  bool _loading = false;
  bool _loadingRecommendations = false;
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
    _loadRecommendationsIfNeeded();
  }

  /// Resolves the effective recommendation tags — uses [widget.recommendationTags]
  /// if provided, otherwise derives them from [widget.recommendationProfile].
  List<String>? get _effectiveTags {
    if (widget.recommendationTags != null) return widget.recommendationTags;
    final profile = widget.recommendationProfile;
    if (profile == null) return null;
    return [
      profile.goal,
      profile.experience,
      ...profile.equipment,
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final exercises = await ExerciseRepository.listExercises(
        name: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        area: _selectedArea,
        type: _selectedType,
        equipment: _selectedEquipment.isEmpty ? null : _selectedEquipment,
        recommendationTags: _effectiveTags,
        forceRefresh: forceRefresh,
      );
      setState(() {
        _exercises = exercises;
        _loading = false;
      });
    } catch (e) {
      // Try to show cached results if available
      try {
        final cached = await ExerciseRepository.listExercises(
          name: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          area: _selectedArea,
          type: _selectedType,
          equipment: _selectedEquipment.isEmpty ? null : _selectedEquipment,
        );
        if (cached.isNotEmpty) {
          setState(() {
            _exercises = cached;
            _error = 'Showing cached results: ${e.toString()}';
            _loading = false;
          });
          return;
        }
      } catch (_) {}

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadRecommendationsIfNeeded() async {
    if (_effectiveTags == null || _effectiveTags!.isEmpty) return;
    setState(() {
      _loadingRecommendations = true;
    });
    try {
      final recs = await ExerciseRepository.listExercises(
        recommendationTags: _effectiveTags,
        // limit could be added to repo later
      );
      setState(() {
        _recommendedExercises = recs;
        _loadingRecommendations = false;
      });
    } catch (_) {
      setState(() {
        _recommendedExercises = [];
        _loadingRecommendations = false;
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
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        // Invalidate cache for current query and force refresh from server
                        ExerciseRepository.invalidateCache(
                          name: _searchController.text.trim().isEmpty
                              ? null
                              : _searchController.text.trim(),
                          area: _selectedArea,
                          type: _selectedType,
                          equipment: _selectedEquipment.isEmpty
                              ? null
                              : _selectedEquipment,
                          recommendationTags: _effectiveTags,
                        );
                        await _loadExercises(forceRefresh: true);
                        await _loadRecommendationsIfNeeded();
                      },
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ],
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No exercises found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Try adjusting your filters'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadExercises(forceRefresh: true);
        await _loadRecommendationsIfNeeded();
      },
      child: ListView(
        children: [
          if (_error != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.black87))),
                    TextButton(
                        onPressed: () async {
                          setState(() {
                            _error = null;
                            _loading = true;
                          });
                          await _loadExercises();
                          await _loadRecommendationsIfNeeded();
                        },
                        child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          if (_effectiveTags != null && _effectiveTags!.isNotEmpty)
            _buildRecommendedSection(),
          ..._exercises.map((e) => _buildExerciseCard(e)).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    if (_loadingRecommendations) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_recommendedExercises.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text('Recommended for you',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemBuilder: (context, index) {
              final ex = _recommendedExercises[index];
              return _buildRecommendedCard(ex);
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _recommendedExercises.length,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedCard(Map<String, dynamic> exercise) {
    final name = exercise['name'] ?? exercise['exer_name'] ?? 'Unknown';
    final type = (exercise['type'] ?? exercise['exer_type'])?.toString() ?? '';
    final area = exercise['area'] ?? exercise['exer_body_area'] ?? '';
    final equipment = (exercise['equipment'] is List)
        ? (exercise['equipment'] as List).join(', ')
        : (exercise['exer_equip'] ?? '');

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('View $name details')),
        );
      },
      child: SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          type == 'strength' ? Colors.blue : Colors.orange,
                      child: Icon(
                          type == 'strength'
                              ? Icons.fitness_center
                              : Icons.directions_run,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(area,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(equipment, style: const TextStyle(fontSize: 12)),
                const Spacer(),
                Align(
                    alignment: Alignment.bottomRight,
                    child: Text('Recommended',
                        style:
                            TextStyle(color: Colors.green[700], fontSize: 12))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              exercise['exer_type'] == 'strength' ? Colors.blue : Colors.orange,
          child: Icon(
            exercise['exer_type'] == 'strength'
                ? Icons.fitness_center
                : Icons.directions_run,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          exercise['exer_name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.accessibility_new,
                    size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(exercise['exer_body_area'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.build, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(exercise['exer_equip'] ?? 'N/A'),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to exercise detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('View ${exercise['exer_name']} details'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
