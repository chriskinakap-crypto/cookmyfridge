import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class ApiService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';

  // IMPORTANT: Replace with your actual Anthropic API key
  // In production, store this securely using Flutter Secure Storage
  static const _apiKey = 'YOUR_ANTHROPIC_API_KEY';

  static Future<List<Recipe>> getRecipes({
    required List<String> ingredients,
    required List<String> filters,
  }) async {
    final dietText = filters.isNotEmpty ? 'Must be ${filters.join(', ')}.' : '';
    final prompt = '''User has: ${ingredients.join(', ')}. $dietText
Suggest 3 recipes. Reply ONLY with JSON array, no markdown, no explanation:
[{"title":"","time":"","difficulty":"","match":90,"calories":450,"protein":25,"carbs":40,"fat":15,"diet":["tag"],"ingredients":["item with quantity"],"steps":["detailed step"],"shopping":["missing ingredient"]}]
match=0-100 percent ingredient fit. diet from [Vegan,Vegetarian,Gluten-free,Halal,Low-carb,Dairy-free]. Give detailed realistic steps.''';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1500,
        'messages': [{'role': 'user', 'content': prompt}],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = (data['content'] as List)
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String)
          .join('');
      final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
      final List<dynamic> jsonList = jsonDecode(clean);
      return jsonList.map((j) => Recipe.fromJson(j)).toList();
    } else {
      throw Exception('Failed to get recipes: ${response.statusCode}');
    }
  }

  static Future<String> chat({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final messages = [
      ...history,
      {'role': 'user', 'content': message},
    ];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 300,
        'system': 'You are a friendly expert AI chef inside CookMyFridge app. Give short, practical cooking advice under 80 words.',
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['content'] as List)
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String)
          .join('');
    } else {
      throw Exception('Chat failed: ${response.statusCode}');
    }
  }
}
