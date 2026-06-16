import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'recipe_detail_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Recipes')),
      body: state.savedRecipes.isEmpty
          ? const Center(child: Text('No saved recipes yet.'))
          : ListView.builder(
              itemCount: state.savedRecipes.length,
              itemBuilder: (context, i) {
                final recipe = state.savedRecipes[i];
                return ListTile(
                  title: Text(recipe.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => state.unsaveRecipe(recipe),
                  ),
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe))),
                );
              },
            ),
    );
  }
}
