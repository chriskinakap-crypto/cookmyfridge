import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/theme.dart';
import '../services/app_state.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

// ── Saved Screen ──────────────────────────────────────────────────────────────
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved recipes', style: TextStyle(color: Colors.white))),
      body: state.savedRecipes.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No saved recipes yet', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              const SizedBox(height: 8),
              Text('Tap the heart on any recipe!', style: TextStyle(color: Colors.grey[300], fontSize: 13)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.savedRecipes.length,
              itemBuilder: (_, i) => RecipeCard(
                recipe: state.savedRecipes[i],
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: state.savedRecipes[i]))),
                onSave: () => state.toggleSave(state.savedRecipes[i]),
                isSaved: true,
              ),
            ),
    );
  }
}

// ── Meal Plan Screen ──────────────────────────────────────────────────────────
class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final planned = state.mealPlan.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Meal planner', style: TextStyle(color: Colors.white))),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: kPrimaryLight,
          child: Row(children: [
            _stat('$planned', 'Meals planned'),
            const SizedBox(width: 16),
            _stat('${7 - planned}', 'Days empty'),
          ]),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _days.length,
          itemBuilder: (_, i) {
            final day = _days[i];
            final meal = state.mealPlan[day];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: meal != null ? kPrimary : Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(day.substring(0, 3), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: meal != null ? Colors.white : Colors.grey[500]))),
                ),
                title: Text(meal ?? 'No meal planned', style: TextStyle(fontSize: 14, color: meal != null ? Colors.black87 : Colors.grey[400])),
                trailing: meal != null
                    ? IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.grey), onPressed: () => state.removeMealPlan(day))
                    : const Icon(Icons.add, color: kPrimary),
                onTap: meal == null ? () => _pickMeal(context, state, day) : null,
              ),
            );
          },
        )),
      ]),
    );
  }

  Widget _stat(String val, String label) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kPrimary)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]),
  ));

  void _pickMeal(BuildContext context, AppState state, String day) {
    final pool = [...state.savedRecipes, ...state.currentRecipes.where((r) => !state.savedRecipes.any((s) => s.title == r.title))];
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Find or save recipes first!'), backgroundColor: kPrimary));
      return;
    }
    showModalBottomSheet(context: context, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: const EdgeInsets.all(16), child: Text('Pick meal for $day', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      ...pool.map((r) => ListTile(
        title: Text(r.title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(r.time, style: const TextStyle(fontSize: 12)),
        onTap: () { state.addToMealPlan(day, r.title); Navigator.pop(context); },
      )),
      const SizedBox(height: 16),
    ]));
  }
}

// ── Shopping Screen ───────────────────────────────────────────────────────────
class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ctrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping list', style: TextStyle(color: Colors.white)),
        actions: [
          if (state.shoppingList.isNotEmpty)
            TextButton(
              onPressed: () { for (var i = state.shoppingList.length - 1; i >= 0; i--) { if (state.shoppingList[i].isDone) state.deleteShoppingItem(i); } },
              child: const Text('Clear done', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Add item...'), onSubmitted: (v) { state.addShoppingItem(v); ctrl.clear(); })),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () { state.addShoppingItem(ctrl.text); ctrl.clear(); },
              style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48), padding: EdgeInsets.zero),
              child: const Icon(Icons.add),
            ),
          ]),
        ),
        Expanded(child: state.shoppingList.isEmpty
          ? Center(child: Text('Your list is empty.\nAdd items from any recipe!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])))
          : ListView.separated(
              itemCount: state.shoppingList.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final item = state.shoppingList[i];
                return ListTile(
                  leading: Checkbox(value: item.isDone, onChanged: (_) => state.toggleShoppingItem(i), activeColor: kPrimary),
                  title: Text(item.name, style: TextStyle(decoration: item.isDone ? TextDecoration.lineThrough : null, color: item.isDone ? Colors.grey[400] : null)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => state.deleteShoppingItem(i)),
                );
              },
            )),
      ]),
    );
  }
}

// ── Profile Screen ────────────────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wasteKg = (state.totalIngredientsUsed * 0.12).toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(title: const Text('My profile', style: TextStyle(color: Colors.white))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
            child: const Center(child: Text('JD', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kPrimary))),
          ),
          const SizedBox(height: 10),
          const Text('John Doe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const Text('john@email.com', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF0997B))), child: const Text('Free plan', style: TextStyle(fontSize: 12, color: kPrimaryDark))),
        ])),
        const SizedBox(height: 24),
        _statsGrid(state.totalSearches, state.savedRecipes.length, state.totalIngredientsUsed, wasteKg),
        const SizedBox(height: 20),
        _sectionTitle('Account'),
        _tile('Name', 'John Doe'),
        _tile('Email', 'john@email.com'),
        _tile('Plan', 'Free', color: kPrimary),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () {}, child: const Text('Upgrade to Pro — \$2.99/month')),
      ]),
    );
  }

  Widget _statsGrid(int searches, int saved, int ings, String waste) => GridView.count(
    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 2.4, crossAxisSpacing: 10, mainAxisSpacing: 10,
    children: [
      _statCard('$searches', 'Searches'),
      _statCard('$saved', 'Saved recipes'),
      _statCard('$ings', 'Ingredients used'),
      _statCard('${waste}kg', 'Waste saved'),
    ],
  );

  Widget _statCard(String val, String label) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]),
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: .5)),
  );

  Widget _tile(String label, String val, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    margin: const EdgeInsets.only(bottom: 1),
    decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      Text(val, style: TextStyle(fontSize: 14, color: color ?? Colors.grey)),
    ]),
  );
}
