import 'package:flutter/material.dart';
import '../data/food_db.dart';
import '../models/meal_item.dart';

/// Dialog that lets the user search & filter the food catalogue and pick an item.
class FoodPickerDialog extends StatefulWidget {
  final void Function(MealItem) onFoodSelected;

  const FoodPickerDialog({Key? key, required this.onFoodSelected})
      : super(key: key);

  @override
  State<FoodPickerDialog> createState() => _FoodPickerDialogState();
}

class _FoodPickerDialogState extends State<FoodPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _collection = 'All';
  double? _maxCalories;
  List<MealItem> _results = [];

  @override
  void initState() {
    super.initState();
    _results = FoodDb.all();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter() {
    setState(() {
      _results = FoodDb.filter(
        collection: _collection,
        query: _searchCtrl.text,
        maxCalories: _maxCalories,
      );
    });
  }

  void _onCollectionChanged(String? value) {
    if (value == null) return;
    setState(() => _collection = value);
    _filter();
  }

  void _onMaxCalChanged(String raw) {
    setState(() => _maxCalories = double.tryParse(raw));
    _filter();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          // ── header ───────────────────────────────────────────────────────
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Add Food',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          // ── filters ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search food…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Collection dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _collection,
                        decoration: const InputDecoration(
                          labelText: 'Collection',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: FoodDb.collections
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: _onCollectionChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Max-cal filter
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Max kcal',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: _onMaxCalChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // result count
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_results.length} result${_results.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── list ─────────────────────────────────────────────────────────
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text('No foods match your filters.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16),
                    itemBuilder: (context, i) {
                      final food = _results[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _typeColor(food.type).withValues(alpha: 0.2),
                          child: Text(
                            food.type.isNotEmpty ? food.type[0] : '?',
                            style: TextStyle(
                                color: _typeColor(food.type),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(food.name),
                        subtitle: Text(food.type),
                        trailing: Text(
                          '${food.calories.toInt()} kcal',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        onTap: () {
                          widget.onFoodSelected(food);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Protein':
        return Colors.red;
      case 'Carb':
        return Colors.amber[700]!;
      case 'Fat':
        return Colors.orange;
      case 'Vegetable':
        return Colors.green;
      case 'Fruit':
        return Colors.pink;
      case 'Dairy':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }
}
