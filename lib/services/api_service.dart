import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class ApiService {
  static const _apiKey = 'AQ.Ab8RN6J2XMNm_-GUVylDa44Mof6UNlbz-H9gumz9gJ2Hw2NW6w';
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
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
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
        throw Exception('Status: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timed out.');
    } catch (e) {
      throw Exception('Could not load recipes: $e');
    }
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
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
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
