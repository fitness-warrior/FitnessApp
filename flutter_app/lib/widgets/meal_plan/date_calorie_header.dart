import 'package:flutter/material.dart';

class DateAndCalorieHeader extends StatelessWidget {
  final String label;
  final double totalCalories;
  final double proteinCalories;
  final double carbCalories;
  final double fatCalories;
  final VoidCallback? onPreviousDay;
  final VoidCallback? onNextDay;

  const DateAndCalorieHeader({
    Key? key,
    required this.label,
    required this.totalCalories,
    required this.proteinCalories,
    required this.carbCalories,
    required this.fatCalories,
    this.onPreviousDay,
    this.onNextDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const dailyGoal = 2000.0;
    const exercise = 0.0;
    final remaining = (dailyGoal - totalCalories + exercise).toInt();
    final progress = (totalCalories / dailyGoal).clamp(0.0, 1.0);
    final over = remaining < 0;
    final macroTotal = proteinCalories + carbCalories + fatCalories;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: onPreviousDay,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: onNextDay,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Calories Remaining',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              remaining.abs().toString(),
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: over ? Colors.red : Colors.blue[700],
                height: 1,
              ),
            ),
            Text(
              over ? 'Over your goal' : 'Under your goal',
              style: TextStyle(
                fontSize: 12,
                color: over ? Colors.red[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricBox(
                    label: 'Goal',
                    value: dailyGoal.toInt().toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricBox(
                    label: 'Food',
                    value: totalCalories.toInt().toString(),
                    isEmphasis: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricBox(
                    label: 'Exercise',
                    value: exercise.toInt().toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Daily Progress',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  '${totalCalories.toInt()} / ${dailyGoal.toInt()} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 11,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  over ? Colors.red : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Macros',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: macroTotal <= 0
                    ? Container(color: Colors.grey[200])
                    : Row(
                        children: [
                          if (proteinCalories > 0)
                            Expanded(
                              flex: proteinCalories.round(),
                              child: Container(color: Colors.red),
                            ),
                          if (carbCalories > 0)
                            Expanded(
                              flex: carbCalories.round(),
                              child: Container(color: Colors.amber),
                            ),
                          if (fatCalories > 0)
                            Expanded(
                              flex: fatCalories.round(),
                              child: Container(color: Colors.orange),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _MacroLegendItem(
                  label: 'Protein',
                  value: proteinCalories.toInt(),
                  color: Colors.red,
                ),
                _MacroLegendItem(
                  label: 'Carbs',
                  value: carbCalories.toInt(),
                  color: Colors.amber,
                ),
                _MacroLegendItem(
                  label: 'Fats',
                  value: fatCalories.toInt(),
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroLegendItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MacroLegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $value kcal',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasis;

  const _MetricBox({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isEmphasis ? Colors.blue[700] : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}