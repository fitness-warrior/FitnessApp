import 'package:flutter/material.dart';

class ExerciseDetailPage extends StatelessWidget {
  final Map<String, dynamic> exercise;

  const ExerciseDetailPage({Key? key, required this.exercise}) : super(key: key);

  static const Map<String, Color> _areaColors = {
    'Chest':     Color(0xFFEF5350),
    'Back':      Color(0xFFAB47BC),
    'Shoulders': Color(0xFF42A5F5),
    'Arms':      Color(0xFF26C6DA),
    'Legs':      Color(0xFF66BB6A),
    'Core':      Color(0xFFFFA726),
    'Cardio':    Color(0xFFEC407A),
  };

  static const Map<String, List<_BodyPart>> _areaHighlights = {
    'Chest':     [_BodyPart.chest],
    'Back':      [_BodyPart.upperBack, _BodyPart.lowerBack],
    'Shoulders': [_BodyPart.shoulders],
    'Arms':      [_BodyPart.biceps, _BodyPart.triceps, _BodyPart.forearms],
    'Legs':      [_BodyPart.quads, _BodyPart.hamstrings, _BodyPart.calves],
    'Core':      [_BodyPart.abs],
    'Cardio':    [_BodyPart.chest, _BodyPart.legs],
  };

  @override
  Widget build(BuildContext context) {
    final name = exercise['exer_name']?.toString() ?? 'Unknown';
    final area = exercise['exer_body_area']?.toString() ?? '';
    final type = exercise['exer_type']?.toString() ?? '';
    final description = exercise['exer_descrip']?.toString() ?? 'No description available.';
    final equipment = exercise['exer_equip']?.toString() ?? 'None';
    final color = _areaColors[area] ?? const Color(0xFF4A9FFF);
    final highlights = _areaHighlights[area] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            backgroundColor: const Color(0xFF0D0D14),
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _badge(area, color),
                      if (type.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _badge(type, Colors.grey[600]!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text('Muscles Targeted', style: TextStyle(color: Colors.grey[400], fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 260,
                          child: _BodyDiagram(highlights: highlights, accentColor: color),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 6),
                            Text(area.isEmpty ? 'Primary muscle' : area, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _infoTile('Equipment', equipment, Icons.fitness_center, const Color(0xFF4A9FFF))),
                      const SizedBox(width: 12),
                      Expanded(child: _infoTile('Type', type.isEmpty ? '—' : type, Icons.category_outlined, const Color(0xFF66BB6A))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: const Color(0xFF1C1C2E), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('About this exercise', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text(description, style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1C1C2E), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _BodyPart {
  head, neck, shoulders, chest, abs, upperBack, lowerBack,
  biceps, triceps, forearms, quads, hamstrings, calves, legs,
}

class _BodyDiagram extends StatelessWidget {
  final List<_BodyPart> highlights;
  final Color accentColor;

  const _BodyDiagram({required this.highlights, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFrontView(),
        _buildBackView(),
      ],
    );
  }

  Widget _buildFrontView() {
    return Column(
      children: [
        Text('Front', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        const SizedBox(height: 6),
        SizedBox(width: 110, height: 230, child: CustomPaint(painter: _BodyPainter(isFront: true, highlights: highlights, accentColor: accentColor))),
      ],
    );
  }

  Widget _buildBackView() {
    return Column(
      children: [
        Text('Back', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        const SizedBox(height: 6),
        SizedBox(width: 110, height: 230, child: CustomPaint(painter: _BodyPainter(isFront: false, highlights: highlights, accentColor: accentColor))),
      ],
    );
  }
}

class _BodyPainter extends CustomPainter {
  final bool isFront;
  final List<_BodyPart> highlights;
  final Color accentColor;

  _BodyPainter({required this.isFront, required this.highlights, required this.accentColor});

  bool _h(_BodyPart part) => highlights.contains(part);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final basePaint = Paint()..color = const Color(0xFF2A2A3E);
    final highlightPaint = Paint()..color = accentColor;
    final outlinePaint = Paint()..color = const Color(0xFF3A3A50)..style = PaintingStyle.stroke..strokeWidth = 1.2;

    void drawPart(Rect rect, {bool isHighlighted = false, double radius = 6}) {
      final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(rRect, isHighlighted ? highlightPaint : basePaint);
      canvas.drawRRect(rRect, outlinePaint);
    }
    void drawOval(Rect rect, {bool isHighlighted = false}) {
      canvas.drawOval(rect, isHighlighted ? highlightPaint : basePaint);
      canvas.drawOval(rect, outlinePaint);
    }

    final cx = w / 2;
    drawOval(Rect.fromCenter(center: Offset(cx, h * 0.06), width: w * 0.32, height: h * 0.10));
    drawPart(Rect.fromLTWH(cx - w * 0.07, h * 0.105, w * 0.14, h * 0.05), radius: 4);

    if (isFront) {
      drawOval(Rect.fromCenter(center: Offset(cx - w * 0.35, h * 0.19), width: w * 0.24, height: h * 0.09), isHighlighted: _h(_BodyPart.shoulders));
      drawOval(Rect.fromCenter(center: Offset(cx + w * 0.35, h * 0.19), width: w * 0.24, height: h * 0.09), isHighlighted: _h(_BodyPart.shoulders));
      drawPart(Rect.fromLTWH(cx - w * 0.30, h * 0.155, w * 0.28, h * 0.13), isHighlighted: _h(_BodyPart.chest), radius: 8);
      drawPart(Rect.fromLTWH(cx + w * 0.02, h * 0.155, w * 0.28, h * 0.13), isHighlighted: _h(_BodyPart.chest), radius: 8);
      drawPart(Rect.fromLTWH(cx - w * 0.47, h * 0.265, w * 0.15, h * 0.14), isHighlighted: _h(_BodyPart.biceps), radius: 8);
      drawPart(Rect.fromLTWH(cx + w * 0.32, h * 0.265, w * 0.15, h * 0.14), isHighlighted: _h(_BodyPart.biceps), radius: 8);
      for (int i = 0; i < 3; i++) {
        drawPart(Rect.fromLTWH(cx - w * 0.27, h * (0.29 + i * 0.075), w * 0.22, h * 0.06), isHighlighted: _h(_BodyPart.abs), radius: 5);
        drawPart(Rect.fromLTWH(cx + w * 0.05, h * (0.29 + i * 0.075), w * 0.22, h * 0.06), isHighlighted: _h(_BodyPart.abs), radius: 5);
      }
      drawPart(Rect.fromLTWH(cx - w * 0.50, h * 0.415, w * 0.14, h * 0.13), isHighlighted: _h(_BodyPart.forearms), radius: 7);
      drawPart(Rect.fromLTWH(cx + w * 0.36, h * 0.415, w * 0.14, h * 0.13), isHighlighted: _h(_BodyPart.forearms), radius: 7);
      drawPart(Rect.fromLTWH(cx - w * 0.30, h * 0.57, w * 0.25, h * 0.20), isHighlighted: _h(_BodyPart.quads) || _h(_BodyPart.legs), radius: 10);
      drawPart(Rect.fromLTWH(cx + w * 0.05, h * 0.57, w * 0.25, h * 0.20), isHighlighted: _h(_BodyPart.quads) || _h(_BodyPart.legs), radius: 10);
      drawPart(Rect.fromLTWH(cx - w * 0.28, h * 0.79, w * 0.22, h * 0.16), isHighlighted: _h(_BodyPart.calves), radius: 8);
      drawPart(Rect.fromLTWH(cx + w * 0.06, h * 0.79, w * 0.22, h * 0.16), isHighlighted: _h(_BodyPart.calves), radius: 8);
    } else {
      drawOval(Rect.fromCenter(center: Offset(cx - w * 0.35, h * 0.19), width: w * 0.24, height: h * 0.09), isHighlighted: _h(_BodyPart.shoulders));
      drawOval(Rect.fromCenter(center: Offset(cx + w * 0.35, h * 0.19), width: w * 0.24, height: h * 0.09), isHighlighted: _h(_BodyPart.shoulders));
      drawPart(Rect.fromLTWH(cx - w * 0.30, h * 0.155, w * 0.60, h * 0.14), isHighlighted: _h(_BodyPart.upperBack), radius: 8);
      drawPart(Rect.fromLTWH(cx - w * 0.22, h * 0.30, w * 0.44, h * 0.12), isHighlighted: _h(_BodyPart.lowerBack), radius: 6);
      drawPart(Rect.fromLTWH(cx - w * 0.47, h * 0.265, w * 0.15, h * 0.14), isHighlighted: _h(_BodyPart.triceps), radius: 8);
      drawPart(Rect.fromLTWH(cx + w * 0.32, h * 0.265, w * 0.15, h * 0.14), isHighlighted: _h(_BodyPart.triceps), radius: 8);
      drawPart(Rect.fromLTWH(cx - w * 0.50, h * 0.415, w * 0.14, h * 0.13), isHighlighted: _h(_BodyPart.forearms), radius: 7);
      drawPart(Rect.fromLTWH(cx + w * 0.36, h * 0.415, w * 0.14, h * 0.13), isHighlighted: _h(_BodyPart.forearms), radius: 7);
      drawPart(Rect.fromLTWH(cx - w * 0.30, h * 0.57, w * 0.25, h * 0.20), isHighlighted: _h(_BodyPart.hamstrings) || _h(_BodyPart.legs), radius: 10);
      drawPart(Rect.fromLTWH(cx + w * 0.05, h * 0.57, w * 0.25, h * 0.20), isHighlighted: _h(_BodyPart.hamstrings) || _h(_BodyPart.legs), radius: 10);
      drawPart(Rect.fromLTWH(cx - w * 0.28, h * 0.79, w * 0.22, h * 0.16), isHighlighted: _h(_BodyPart.calves), radius: 8);
      drawPart(Rect.fromLTWH(cx + w * 0.06, h * 0.79, w * 0.22, h * 0.16), isHighlighted: _h(_BodyPart.calves), radius: 8);
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) => old.isFront != isFront || old.highlights != highlights || old.accentColor != accentColor;
}
