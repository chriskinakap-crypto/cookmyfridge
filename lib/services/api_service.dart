import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class ApiService {
  static const _apiKey = 'YOUR_GEMINI_API_KEY';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<List<Recipe>> getRecipes({
    required List<String> ingredients,
    required List<String> filters,
  }) async {
    final dietText = filters.isNotEmpty ? 'Must be ${filters.join(', ')}.' : '';
    final prompt = 'User has: ${ingredients.join(', ')}. $dietText\nSuggest 3 recipes. Reply ONLY with JSON array, no markdown, no explanation:\n[{"title":"","time":"","difficulty":"","match":90,"calories":450,"protein":25,"carbs":40,"fat":15,"diet":["tag"],"ingredients":["item with quantity"],"steps":["detailed step"],"shopping":["missing ingredient"]}]';
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'maxOutputTokens': 2000, 'temperature': 0.7},
        }),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
        final List<dynamic> jsonList = jsonDecode(clean);
        return jsonList.map((j) => Recipe.fromJson(j)).toList();
      } else {
        return _mockRecipes(ingredients);
      }
    } catch (e) {
      return _mockRecipes(ingredients);
    }
  }

  static List<Recipe> _mockRecipes(List<String> ingredients) {
    final ing = ingredients.isNotEmpty ? ingredients.first : 'vegetables';
    return [
      Recipe.fromJson({
        'title': 'Simple $ing Stir Fry',
        'time': '20 mins',
        'difficulty': 'Easy',
        'match': 85,
        'calories': 350,
        'protein': 20,
        'carbs': 30,
        'fat': 10,
        'diet': ['Halal'],
        'ingredients': ingredients.map((i) => '1 cup $i').toList() + ['2 tbsp oil', 'salt', 'pepper'],
        'steps': ['Heat oil in a pan', 'Add ${ingredients.join(', ')}', 'Stir fry for 10 minutes', 'Season and serve hot'],
        'shopping': ['oil', 'salt', 'pepper']
      }),
      Recipe.fromJson({
        'title': '$ing Soup',
        'time': '30 mins',
        'difficulty': 'Easy',
        'match': 75,
        'calories': 250,
        'protein': 15,
        'carbs': 25,
        'fat': 8,
        'diet': ['Vegan'],
        'ingredients': ingredients.map((i) => '200g $i').toList() + ['1L water', 'salt'],
        'steps': ['Boil water', 'Add ${ingredients.join(', ')}', 'Simmer for 20 minutes', 'Season and serve'],
        'shopping': ['vegetable stock', 'salt']
      }),
      Recipe.fromJson({
        'title': 'Baked $ing',
        'time': '40 mins',
        'difficulty': 'Medium',
        'match': 70,
        'calories': 400,
        'protein': 22,
        'carbs': 35,
        'fat': 12,
        'diet': ['Gluten-free'],
        'ingredients': ingredients.map((i) => '300g $i').toList() + ['olive oil', 'garlic', 'herbs'],
        'steps': ['Preheat oven to 180C', 'Prepare ${ingredients.join(', ')}', 'Bake for 30 minutes', 'Serve warm'],
        'shopping': ['olive oil', 'garlic', 'herbs']
      }),
    ];
  }

  static Future<String> chat({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    try {
      final contents = history.map((m) => {
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': m['content']}]
      }).toList();
      contents.add({'role': 'user', 'parts': [{'text': message}]});
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {'maxOutputTokens': 300},
        }),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else {
        return 'Sorry, I could not connect. Try again!';
      }
    } catch (e) {
      return 'Sorry, I could not connect. Try again!';
    }
  }
}
