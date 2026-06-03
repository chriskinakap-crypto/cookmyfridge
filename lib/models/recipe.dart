class Recipe {
  final String title;
  final String time;
  final String difficulty;
  final int match;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> diet;
  final List<String> ingredients;
  final List<String> steps;
  final List<String> shopping;
  int rating;
  bool isSaved;

  Recipe({
    required this.title,
    required this.time,
    required this.difficulty,
    required this.match,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.diet = const [],
    this.ingredients = const [],
    this.steps = const [],
    this.shopping = const [],
    this.rating = 0,
    this.isSaved = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'] ?? '',
      time: json['time'] ?? '',
      difficulty: json['difficulty'] ?? '',
      match: json['match'] ?? 0,
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
      diet: List<String>.from(json['diet'] ?? []),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      shopping: List<String>.from(json['shopping'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'time': time,
    'difficulty': difficulty,
    'match': match,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'diet': diet,
    'ingredients': ingredients,
    'steps': steps,
    'shopping': shopping,
    'rating': rating,
    'isSaved': isSaved,
  };
}

class ShoppingItem {
  String name;
  bool isDone;
  ShoppingItem({required this.name, this.isDone = false});
}

class SearchHistory {
  final List<String> ingredients;
  final List<String> filters;
  final List<String> recipeNames;
  final DateTime date;

  SearchHistory({
    required this.ingredients,
    required this.filters,
    required this.recipeNames,
    required this.date,
  });
}
