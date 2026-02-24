import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/exercise_service.dart';

class ExerciseDetailWidget extends StatefulWidget {
  final int exerId;
  const ExerciseDetailWidget({Key? key, required this.exerId}) : super(key: key);

  @override
  _ExerciseDetailWidgetState createState() => _ExerciseDetailWidgetState();
}

class _ExerciseDetailWidgetState extends State<ExerciseDetailWidget> {
  Map<String, dynamic>? _exercise;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ExerciseService.getExercise(widget.exerId);
      setState(() {
        _exercise = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open video URL')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_exercise == null) return Center(child: Text('No data'));

    final title = _exercise!['exer_name'] ?? 'Exercise';
    final area = _exercise!['exer_body_area'] ?? '';
    final type = _exercise!['exer_type'] ?? '';
    final desc = _exercise!['exer_descrip'] ?? 'No description available.';
    final vid = _exercise!['exer_vid'] as String?;
    final equip = _exercise!['exer_equip'] ?? '';
    final plan = _exercise!['plan'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headline6),
          SizedBox(height: 8),
          Row(children: [
            if (area.isNotEmpty)
              Chip(label: Text(area)),
            SizedBox(width: 8),
            if (type.isNotEmpty)
              Chip(label: Text(type)),
            SizedBox(width: 8),
            if (equip.isNotEmpty)
              Chip(label: Text(equip)),
          ]),

          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(desc),
            ),
          ),

          SizedBox(height: 12),
          if (plan != null) ...[
            Text('Plan', style: Theme.of(context).textTheme.subtitle1),
            SizedBox(height: 6),
            Row(children: [
              Text('Sets: ${plan['sets'] ?? '-'}'),
              SizedBox(width: 16),
              Text('Reps: ${plan['reps'] ?? '-'}'),
            ]),
            SizedBox(height: 12),
          ],

          Text('Video', style: Theme.of(context).textTheme.subtitle1),
          SizedBox(height: 8),
          if (vid != null && vid.isNotEmpty)
            ElevatedButton.icon(
              icon: Icon(Icons.play_arrow),
              label: Text('Open video'),
              onPressed: () => _openVideo(vid),
            )
          else
            Text('No video available', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
