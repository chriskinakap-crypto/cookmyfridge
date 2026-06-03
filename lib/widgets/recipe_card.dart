import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/theme.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final bool isSaved;

  const RecipeCard({super.key, required this.recipe, required this.onTap, required this.onSave, required this.isSaved});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(recipe.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (recipe.diet.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFE1F5EE), borderRadius: BorderRadius.circular(10)),
                    child: Text(recipe.diet.first, style: const TextStyle(fontSize: 10, color: Color(0xFF085041))),
                  ),
                ],
              ])),
              IconButton(
                onPressed: onSave,
                icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? kPrimary : Colors.grey[400]),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _meta(Icons.access_time, recipe.time),
              const SizedBox(width: 14),
              _meta(Icons.local_fire_department_outlined, recipe.difficulty),
              const SizedBox(width: 14),
              _meta(Icons.whatshot_outlined, '${recipe.calories} kcal'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: recipe.match / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(kPrimary),
                  minHeight: 4,
                ),
              )),
              const SizedBox(width: 8),
              Text('${recipe.match}% match', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label) => Row(children: [
    Icon(icon, size: 13, color: Colors.grey[500]),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
  ]);
}
