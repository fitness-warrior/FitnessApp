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
    'Back':      [_BodyPart.lats, _BodyPart.traps, _BodyPart.lowerBack],
    'Shoulders': [_BodyPart.shoulders],
    'Arms':      [_BodyPart.biceps, _BodyPart.triceps, _BodyPart.forearms],
    'Legs':      [_BodyPart.quads, _BodyPart.hamstrings, _BodyPart.calves, _BodyPart.glutes],
    'Core':      [_BodyPart.abs, _BodyPart.obliques],
    'Cardio':    [_BodyPart.chest, _BodyPart.legs],
  };

  @override
  Widget build(BuildContext context) {
    final name = exercise['name']?.toString() ?? exercise['exer_name']?.toString() ?? 'Unknown';
    final areaRaw = exercise['area']?.toString() ?? exercise['exer_body_area']?.toString() ?? '';
    final area = areaRaw.isNotEmpty ? areaRaw[0].toUpperCase() + areaRaw.substring(1).toLowerCase() : '';
    final type = exercise['type']?.toString() ?? exercise['exer_type']?.toString() ?? '';
    final description = exercise['description']?.toString() ?? exercise['exer_descrip']?.toString() ?? 'No description available.';
    final equipmentRaw = exercise['equipment'] ?? exercise['exer_equip'];
    final equipment = equipmentRaw is List ? equipmentRaw.join(', ') : equipmentRaw?.toString() ?? 'None';
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
  head, neck, shoulders, chest, abs, obliques,
  lats, traps, lowerBack, glutes,
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

    final basePaint = Paint()..color = const Color(0xFF2A2A3E)..style = PaintingStyle.fill;
    final highlightPaint = Paint()..color = accentColor..style = PaintingStyle.fill;
    final outlinePaint = Paint()..color = const Color(0xFF3A3A50)..style = PaintingStyle.stroke..strokeWidth = 1.2;

    void drawPoly(List<Offset> pts, bool hl) {
      if (pts.isEmpty) return;
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) path.lineTo(pts[i].dx, pts[i].dy);
      path.close();
      canvas.drawPath(path, hl ? highlightPaint : basePaint);
      canvas.drawPath(path, outlinePaint);
      
      // Mirror to right side
      canvas.save();
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
      canvas.drawPath(path, hl ? highlightPaint : basePaint);
      canvas.drawPath(path, outlinePaint);
      canvas.restore();
    }

    final cx = w / 2;
    // Head & Neck
    drawPoly([Offset(cx, h*0.02), Offset(cx-w*0.15, h*0.02), Offset(cx-w*0.15, h*0.1), Offset(cx-w*0.1, h*0.13), Offset(cx, h*0.13)], false);
    drawPoly([Offset(cx, h*0.13), Offset(cx-w*0.08, h*0.13), Offset(cx-w*0.1, h*0.16), Offset(cx, h*0.16)], false);

    if (isFront) {
      // Shoulders
      drawPoly([Offset(cx-w*0.2, h*0.16), Offset(cx-w*0.4, h*0.18), Offset(cx-w*0.45, h*0.25), Offset(cx-w*0.3, h*0.25)], _h(_BodyPart.shoulders));
      // Chest
      drawPoly([Offset(cx, h*0.16), Offset(cx-w*0.25, h*0.16), Offset(cx-w*0.3, h*0.23), Offset(cx-w*0.02, h*0.25), Offset(cx, h*0.25)], _h(_BodyPart.chest));
      // Abs (6-pack)
      drawPoly([Offset(cx, h*0.26), Offset(cx-w*0.12, h*0.26), Offset(cx-w*0.1, h*0.30), Offset(cx, h*0.30)], _h(_BodyPart.abs));
      drawPoly([Offset(cx, h*0.31), Offset(cx-w*0.1, h*0.31), Offset(cx-w*0.08, h*0.35), Offset(cx, h*0.35)], _h(_BodyPart.abs));
      drawPoly([Offset(cx, h*0.36), Offset(cx-w*0.08, h*0.36), Offset(cx-w*0.05, h*0.41), Offset(cx, h*0.41)], _h(_BodyPart.abs));
      // Obliques
      drawPoly([Offset(cx-w*0.14, h*0.26), Offset(cx-w*0.25, h*0.26), Offset(cx-w*0.22, h*0.39), Offset(cx-w*0.08, h*0.40)], _h(_BodyPart.obliques) || _h(_BodyPart.abs));
      // Biceps
      drawPoly([Offset(cx-w*0.32, h*0.26), Offset(cx-w*0.45, h*0.26), Offset(cx-w*0.42, h*0.35), Offset(cx-w*0.28, h*0.35)], _h(_BodyPart.biceps));
      // Forearms
      drawPoly([Offset(cx-w*0.28, h*0.36), Offset(cx-w*0.42, h*0.36), Offset(cx-w*0.38, h*0.48), Offset(cx-w*0.30, h*0.48)], _h(_BodyPart.forearms));
      // Quads
      drawPoly([Offset(cx-w*0.05, h*0.43), Offset(cx-w*0.25, h*0.43), Offset(cx-w*0.2, h*0.65), Offset(cx-w*0.05, h*0.65)], _h(_BodyPart.quads) || _h(_BodyPart.legs));
      // Calves
      drawPoly([Offset(cx-w*0.05, h*0.68), Offset(cx-w*0.2, h*0.68), Offset(cx-w*0.15, h*0.85), Offset(cx-w*0.05, h*0.85)], _h(_BodyPart.calves) || _h(_BodyPart.legs));
    } else {
      // Shoulders (back)
      drawPoly([Offset(cx-w*0.2, h*0.16), Offset(cx-w*0.4, h*0.18), Offset(cx-w*0.45, h*0.25), Offset(cx-w*0.3, h*0.25)], _h(_BodyPart.shoulders));
      // Traps
      drawPoly([Offset(cx, h*0.16), Offset(cx-w*0.2, h*0.16), Offset(cx-w*0.25, h*0.20), Offset(cx, h*0.24)], _h(_BodyPart.traps));
      // Lats
      drawPoly([Offset(cx, h*0.25), Offset(cx-w*0.25, h*0.21), Offset(cx-w*0.30, h*0.26), Offset(cx-w*0.22, h*0.36), Offset(cx, h*0.36)], _h(_BodyPart.lats));
      // Lower Back
      drawPoly([Offset(cx, h*0.37), Offset(cx-w*0.20, h*0.37), Offset(cx-w*0.22, h*0.45), Offset(cx, h*0.48)], _h(_BodyPart.lowerBack));
      // Glutes
      drawPoly([Offset(cx, h*0.49), Offset(cx-w*0.23, h*0.46), Offset(cx-w*0.28, h*0.55), Offset(cx, h*0.58)], _h(_BodyPart.glutes) || _h(_BodyPart.legs));
      // Triceps
      drawPoly([Offset(cx-w*0.32, h*0.26), Offset(cx-w*0.45, h*0.26), Offset(cx-w*0.42, h*0.35), Offset(cx-w*0.28, h*0.35)], _h(_BodyPart.triceps));
      // Forearms
      drawPoly([Offset(cx-w*0.28, h*0.36), Offset(cx-w*0.42, h*0.36), Offset(cx-w*0.38, h*0.48), Offset(cx-w*0.30, h*0.48)], _h(_BodyPart.forearms));
      // Hamstrings
      drawPoly([Offset(cx-w*0.05, h*0.59), Offset(cx-w*0.27, h*0.56), Offset(cx-w*0.22, h*0.68), Offset(cx-w*0.05, h*0.68)], _h(_BodyPart.hamstrings) || _h(_BodyPart.legs));
      // Calves
      drawPoly([Offset(cx-w*0.05, h*0.70), Offset(cx-w*0.2, h*0.70), Offset(cx-w*0.15, h*0.88), Offset(cx-w*0.05, h*0.88)], _h(_BodyPart.calves) || _h(_BodyPart.legs));
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) => old.isFront != isFront || old.highlights != highlights || old.accentColor != accentColor;
}
