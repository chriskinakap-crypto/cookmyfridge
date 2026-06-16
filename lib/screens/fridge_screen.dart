import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/theme.dart';
import '../services/app_state.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../widgets/recipe_card.dart';
import '../widgets/banner_ad_widget.dart';
import 'recipe_detail_screen.dart';
import 'upgrade_screen.dart';
import 'secondary_screens.dart';

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});
  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  final _controller = TextEditingController();
  final _filters = ['Vegan','Vegetarian','Gluten-free','Halal','Low-carb','Dairy-free'];
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    AdService.loadInterstitial();
    AdService.loadRewardedAd(({required dynamic ad, required dynamic reward}) {});
    _checkPro();
  }

  Future<void> _checkPro() async {
    final data = await AuthService.getUserData();
    if (mounted) setState(() => _isPro = data?['plan'] == 'pro');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('CookMyFridge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: () => _showHistory(context, state)),
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
        ],
      ),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          if (!_isPro) _upgradeBanner(context),
          if (!_isPro) const SizedBox(height: 14),
          const Text('Whats in your fridge?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: .5)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'e.g. eggs, chicken, rice...'), onSubmitted: (_) => _add(state))),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: () => _add(state), style: ElevatedButton.styleFrom(minimumSize: const Size(48,48), padding: EdgeInsets.zero), child: const Icon(Icons.add)),
          ]),
          const SizedBox(height: 10),
          if (state.ingredients.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: state.ingredients.map((ing) => Chip(
            label: Text(ing, style: const TextStyle(fontSize: 12, color: kPrimaryDark)),
            backgroundColor: kPrimaryLight,
            side: const BorderSide(color: Color(0xFFF0997B)),
            deleteIconColor: kPrimaryDark,
            onDeleted: () => state.removeIngredient(ing),
          )).toList()),
          const SizedBox(height: 14),
          const Text('Dietary filters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: .5)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: _filters.map((f) {
            final on = state.activeFilters.contains(f);
            return GestureDetector(
              onTap: () => state.toggleFilter(f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: on ? kPrimaryLight : Colors.white, border: Border.all(color: on ? const Color(0xFFF0997B) : Colors.grey[300]!), borderRadius: BorderRadius.circular(20)),
                child: Text(f, style: TextStyle(fontSize: 12, color: on ? kPrimaryDark : Colors.grey[600])),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: state.ingredients.isNotEmpty && !state.isLoading ? () => _search(state) : null,
            icon: state.isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
            label: Text(state.isLoading ? 'Finding recipes...' : 'Find Recipes', style: const TextStyle(fontSize: 15)),
          )),
          if (state.error != null) ...[const SizedBox(height: 12), Text(state.error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center)],
          const SizedBox(height: 16),
          if (state.currentRecipes.isEmpty && !state.isLoading)
            Center(child: Text('Add ingredients above to discover recipes', style: TextStyle(color: Colors.grey[400], fontSize: 13)))
          else if (state.currentRecipes.isNotEmpty) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recipes for you', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: .5)),
              if (!_isPro) _watchAdButton(),
            ]),
            const SizedBox(height: 8),
            ...(_isPro ? state.currentRecipes : state.currentRecipes.take(2).toList()).asMap().entries.map((e) => RecipeCard(
              recipe: e.value,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: e.value))),
              onSave: () => state.toggleSave(e.value),
              isSaved: state.isSaved(e.value.title),
            )),
            if (!_isPro && state.currentRecipes.length > 2) _lockedTeaser(context, state),
          ],
        ])),
        if (!_isPro) const BannerAdWidget(),
      ]),
    );
  }

  Widget _upgradeBanner(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen())),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimary, Color(0xFFFF9A6C)]), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Upgrade to Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          Text('Unlimited recipes + ad-free for \$2.99/mo', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Text('Upgrade', style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600))),
      ]),
    ),
  );

  Widget _watchAdButton() => GestureDetector(
    onTap: () => AdService.showRewardedAd(onRewarded: ({required dynamic reward}) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unlocked all 3 recipes!'), backgroundColor: kPrimary));
      setState(() => _isPro = true);
    }),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF0997B))),
      child: const Row(children: [Icon(Icons.play_circle_outline, size: 14, color: kPrimary), SizedBox(width: 4), Text('Watch ad for all 3', style: TextStyle(fontSize: 11, color: kPrimaryDark))]),
    ),
  );

  Widget _lockedTeaser(BuildContext context, AppState state) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen())),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[300]!)),
      child: Row(children: [
        const Icon(Icons.lock_outline, color: Colors.grey, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${state.currentRecipes.length - 2} more recipe locked', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
          const Text('Upgrade to Pro or watch an ad to unlock', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ]),
    ),
  );

  Future<void> _search(AppState state) async {
    await state.findRecipes();
    AdService.onRecipeSearch();
  }

  void _add(AppState state) {
    if (_controller.text.trim().isNotEmpty) { state.addIngredient(_controller.text); _controller.clear(); }
  }

  void _showHistory(BuildContext context, AppState state) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => DraggableScrollableSheet(
      expand: false, initialChildSize: .5,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Search history', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(child: state.searchHistory.isEmpty
            ? const Center(child: Text('No searches yet'))
            : ListView.separated(
                controller: ctrl,
                itemCount: state.searchHistory.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final h = state.searchHistory[i];
                  return ListTile(
                    title: Text((h['ingredients'] as List?)?.join(', ') ?? '', style: const TextStyle(fontSize: 13)),
                    subtitle: Text((h['recipeNames'] as List?)?.join(' · ') ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  );
                },
              )),
        ]),
      ),
    ));
  }
}
