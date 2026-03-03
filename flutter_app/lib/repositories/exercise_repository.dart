import 'package:collection/collection.dart';
import '../data/exercise_db.dart';
import '../services/exercise_service.dart';

/// ExerciseRepository: unified access to exercise data.

class ExerciseRepository {
  
  static Future<List<Map<String, dynamic>>> listExercises({
    String? name,
    String? area,
    String? type,
    List<String>? equipment,
    List<String>? recommendationTags,
    List<int>? ids,
    bool forceRefresh = false,
  }) async {
    // If ids provided, return local items by id
    if (ids != null && ids.isNotEmpty) {
      final results = <Map<String, dynamic>>[];
      for (final id in ids) {
        final r = await ExerciseDb.instance.getExercise(id);
        if (r != null) results.add(_normalizeDbRow(r));
      }
      return results;
    }

    final localRows = await ExerciseDb.instance.listExercises(
      name: name,
      area: area,
      type: type,
      equipment: equipment,
    );

    var normalized = localRows.map(_normalizeDbRow).toList();

    // If recommendation tags provided, compute a recommendationScore and sort
    if (recommendationTags != null && recommendationTags.isNotEmpty) {
      final tagSet = recommendationTags.map((t) => t.toLowerCase()).toSet();
      for (final item in normalized) {
        final itemTags = <String>{};
        // collect tags from normalized fields
        if (item['type'] != null) itemTags.add(item['type'].toString().toLowerCase());
        if (item['area'] != null) itemTags.add(item['area'].toString().toLowerCase());
        if (item['equipment'] != null) {
          final eq = (item['equipment'] as List).map((e) => e.toString().toLowerCase());
          itemTags.addAll(eq);
        }
        // name-based tag
        if (item['name'] != null) itemTags.addAll(item['name'].toString().toLowerCase().split(' '));

        // compute simple score: number of matching tags
        final matches = tagSet.intersection(itemTags).length;
        item['meta'] ??= {};
        item['meta']['recommendationScore'] = matches.toDouble();
      }
      // sort descending by score
      normalized.sort((a, b) {
        final sa = (a['meta']?['recommendationScore'] ?? 0) as double;
        final sb = (b['meta']?['recommendationScore'] ?? 0) as double;
        return sb.compareTo(sa);
      });
    }

    // If no local results and forceRefresh -> fetch remote and upsert locally
    if ((normalized.isEmpty && !forceRefresh) || forceRefresh) {
      try {
        final remote = await ExerciseService.listExercises(
          name: name,
          area: area,
          type: type,
          equipment: equipment,
        );
        if (remote.isNotEmpty) {
          // Attempt to normalize remote rows; assume they already match normalized shape
          final remoteNorm = remote.map((r) => _normalizeRemoteRow(r)).toList();
          // Prefer remote results if forceRefresh
          if (forceRefresh || normalized.isEmpty) normalized = remoteNorm;
        }
      } catch (_) {
        // swallow remote errors here; UI should handle showing retry if needed
      }
    }

    return normalized;
  }

  static Future<Map<String, dynamic>?> getExerciseById(int id) async {
    final local = await ExerciseDb.instance.getExercise(id);
    if (local != null) return _normalizeDbRow(local);
    try {
      final remote = await ExerciseService.getExercise(id);
      return _normalizeRemoteRow(remote);
    } catch (_) {
      return null;
    }
  }

  // Transform DB row shape into normalized shape
  static Map<String, dynamic> _normalizeDbRow(Map<String, dynamic> r) {
    final equipRaw = r['exer_equip'] as String?;
    final equipment = equipRaw == null || equipRaw.isEmpty
        ? <String>[]
        : equipRaw.split(',').map((s) => s.trim()).whereNotNull().toList();

    return {
      'id': r['exer_id'],
      'name': r['exer_name'],
      'type': r['exer_type'],
      'area': r['exer_body_area'],
      'description': r['exer_descrip'],
      'video': r['exer_vid'],
      'equipment': equipment,
      'difficulty': r['difficulty'] ?? '',
      'tags': <String>[],
      'meta': {'source': 'local'},
    };
  }

  // Normalize remote row; assume keys may already be normalized but guard
  static Map<String, dynamic> _normalizeRemoteRow(Map<String, dynamic> r) {
    final equipment = <String>[];
    if (r['equipment'] is String) {
      equipment.addAll((r['equipment'] as String).split(',').map((s) => s.trim()));
    } else if (r['equipment'] is List) {
      equipment.addAll((r['equipment'] as List).map((e) => e.toString()));
    }

    return {
      'id': r['id'] ?? r['exer_id'] ?? r['exerId'],
      'name': r['name'] ?? r['exer_name'] ?? r['exerName'],
      'type': r['type'] ?? r['exer_type'],
      'area': r['area'] ?? r['exer_body_area'],
      'description': r['description'] ?? r['exer_descrip'],
      'video': r['video'] ?? r['exer_vid'],
      'equipment': equipment,
      'difficulty': r['difficulty'] ?? '',
      'tags': (r['tags'] is List) ? (r['tags'] as List).map((e) => e.toString()).toList() : <String>[],
      'meta': {'source': 'remote'},
    };
  }
}
