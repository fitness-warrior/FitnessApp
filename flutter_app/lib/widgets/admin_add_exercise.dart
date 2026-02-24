import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAddExercise extends StatefulWidget {
  const AdminAddExercise({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AdminAddExerciseState createState() => _AdminAddExerciseState();
}

class _AdminAddExerciseState extends State<AdminAddExercise> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _areaCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _vidCtl = TextEditingController();

  String _type = 'strength';
  String _equip = 'Bodyweight Only';
  bool _saving = false;
  String? _result;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _result = null;
    });

    final payload = {
      'exer_name': _nameCtl.text.trim(),
      'exer_body_area': _areaCtl.text.trim(),
      'exer_type': _type,
      'exer_descrip': _descCtl.text.trim(),
      'exer_vid': _vidCtl.text.trim(),
      'exer_equip': _equip,
    };

    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2:5001/api/exercises'),
        headers: {
          'Content-Type': 'application/json',
          'X-Admin': 'true',
        },
        body: json.encode(payload),
      );
      if (res.statusCode == 201) {
        final data = json.decode(res.body);
        setState(() {
          _result = 'Created exer_id: ${data['exer_id']}';
        });
        _formKey.currentState!.reset();
      } else {
        setState(() {
          _result = 'Error ${res.statusCode}: ${res.body}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Exception: $e';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Add Exercise')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _areaCtl,
                decoration: const InputDecoration(labelText: 'Body area'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: ['strength', 'cardio']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'strength'),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _equip,
                items: [
                  'Bodyweight Only',
                  'Dumbbells',
                  'Barbells',
                  'Resistance Bands',
                  'Gym Machines',
                  'Cardio Machines'
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _equip = v ?? 'Bodyweight Only'),
                decoration: const InputDecoration(labelText: 'Equipment'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtl,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 6,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vidCtl,
                decoration: const InputDecoration(labelText: 'Video URL (optional)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 12),
                Text(_result!),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
