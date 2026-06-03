import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recipe.dart';
import '../models/theme.dart';
import '../services/app_state.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});
  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _rating = widget.recipe.rating;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isSaved = state.isSaved(widget.recipe.title);
    final r = widget.recipe;

    return Scaffold(
      appBar: AppBar(
        title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: Colors.white),
            onPressed: () => state.toggleSave(r),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => Share.share('${r.title}\n\nIngredients:\n${r.ingredients.join('\n')}\n\nSteps:\n${r.steps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _chip(Icons.access_time, r.time),
            const SizedBox(width: 8),
            _chip(Icons.local_fire_department_outlined, r.difficulty),
            const SizedBox(width: 8),
            _chip(Icons.bar_chart, '${r.match}% match'),
          ]),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () {
                setState(() => _rating = i + 1);
                state.rateRecipe(r.title, i + 1);
              },
              child: Icon(i < _rating ? Icons.star : Icons.star_border, color: kPrimary, size: 26),
            )),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _actionBtn(Icons.favorite_border, isSaved ? 'Saved' : 'Save', isSaved, () => state.toggleSave(r))),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(Icons.shopping_cart_outlined, 'Add to list', false, () {
              state.addShoppingItems(r.shopping);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to shopping list!'), backgroundColor: kPrimary));
            })),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(Icons.calendar_today_outlined, 'Plan meal', false, () => _pickDay(context, state))),
          ]),
          const SizedBox(height: 18),
          _section('Nutrition per serving'),
          GridView.count(
            crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1, crossAxisSpacing: 8, mainAxisSpacing: 8,
            children: [
              _nutriCard('${r.calories}', 'Calories'),
              _nutriCard('${r.protein}g', 'Protein'),
              _nutriCard('${r.carbs}g', 'Carbs'),
              _nutriCard('${r.fat}g', 'Fat'),
            ],
          ),
          const SizedBox(height: 16),
          _section('Ingredients'),
          ...r.ingredients.map((ing) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.fiber_manual_record, size: 8, color: kPrimary),
              const SizedBox(width: 8),
              Expanded(child: Text(ing, style: const TextStyle(fontSize: 14))),
            ]),
          )),
          if (r.shopping.isNotEmpty) ...[
            const SizedBox(height: 14),
            _section('You may need to buy'),
            ...r.shopping.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(item, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ]),
            )),
          ],
          const SizedBox(height: 16),
          _section('Steps'),
          ...r.steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24, height: 24, margin: const EdgeInsets.only(right: 10, top: 1),
                decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600))),
              ),
              Expanded(child: Text(e.value, style: const TextStyle(fontSize: 14, height: 1.5))),
            ]),
          )),
          const SizedBox(height: 16),
          _section('Share this recipe'),
          Row(children: [
            Expanded(child: _actionBtn(Icons.copy, 'Copy', false, () {
              Clipboard.setData(ClipboardData(text: '${r.title}\n\nIngredients:\n${r.ingredients.join('\n')}\n\nSteps:\n${r.steps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe copied!'), backgroundColor: kPrimary));
            })),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(Icons.share, 'Share', false, () => Share.share(r.title))),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: .5)),
  );

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Icon(icon, size: 12, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ]),
  );

  Widget _actionBtn(IconData icon, String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: active ? kPrimary : kPrimaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? kPrimary : const Color(0xFFF0997B)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14, color: active ? Colors.white : kPrimaryDark),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : kPrimaryDark, fontWeight: FontWeight.w500)),
      ]),
    ),
  );

  Widget _nutriCard(String val, String label) => Container(
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  );

  void _pickDay(BuildContext context, AppState state) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    showModalBottomSheet(context: context, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Add to meal plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      ...days.map((d) => ListTile(
        title: Text(d),
        trailing: state.mealPlan.containsKey(d) ? const Icon(Icons.check_circle, color: kPrimary) : null,
        onTap: () {
          state.addToMealPlan(d, widget.recipe.title);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to $d!'), backgroundColor: kPrimary));
        },
      )),
      const SizedBox(height: 16),
    ]));
  }
}
