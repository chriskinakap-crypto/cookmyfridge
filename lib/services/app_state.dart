import 'dart:async';
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'firebase_service.dart';

class AppState extends ChangeNotifier {
  List<String> ingredients = [];
  List<String> activeFilters = [];
  List<Recipe> currentRecipes = [];
  bool isLoading = false;
  String? error;

  List<Recipe> savedRecipes = [];
  StreamSubscription? _savedSub;

  Map<String, String> mealPlan = {};
  StreamSubscription? _mealSub;

  List<Map<String, dynamic>> shoppingItems = [];
  List<Map<String, dynamic>> get shoppingList => shoppingItems;

  void unsaveRecipe(dynamic recipe) {
    savedRecipes.removeWhere((r) => r.title == recipe.title);
    notifyListeners();
  }



  StreamSubscription? _shopSub;

  List<Map<String, dynamic>> searchHistory = [];
  StreamSubscription? _histSub;

  List<Map<String, String>> chatHistory = [];

  int totalSearches = 0;
  int totalIngredientsUsed = 0;

  AppState() {
    AuthService.authStateChanges.listen((user) {
      if (user != null) _startStreams();
      else _stopStreams();
    });
  }

  void _startStreams() {
    _savedSub = DatabaseService.savedRecipesStream().listen((recipes) {
      savedRecipes = recipes; notifyListeners();
    });
    _mealSub = DatabaseService.mealPlanStream().listen((plan) {
      mealPlan = plan; notifyListeners();
    });
    _shopSub = DatabaseService.shoppingListStream().listen((snap) {
      shoppingItems = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      notifyListeners();
    });
    _histSub = DatabaseService.historyStream().listen((hist) {
      searchHistory = hist; notifyListeners();
    });
  }

  void _stopStreams() {
    _savedSub?.cancel(); _mealSub?.cancel(); _shopSub?.cancel(); _histSub?.cancel();
    savedRecipes = []; mealPlan = {}; shoppingItems = []; searchHistory = [];
    notifyListeners();
  }

  @override
  void dispose() { _stopStreams(); super.dispose(); }

  void addIngredient(String value) {
    final items = value.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty);
    for (final item in items) { if (!ingredients.contains(item)) ingredients.add(item); }
    notifyListeners();
  }

  void removeIngredient(String ing) { ingredients.remove(ing); notifyListeners(); }

  void toggleFilter(String filter) {
    activeFilters.contains(filter) ? activeFilters.remove(filter) : activeFilters.add(filter);
    notifyListeners();
  }

  Future<void> findRecipes() async {
    if (ingredients.isEmpty) return;
    isLoading = true; error = null; notifyListeners();
    try {
      currentRecipes = await ApiService.getRecipes(ingredients: ingredients, filters: activeFilters);
      totalSearches++; totalIngredientsUsed += ingredients.length;
      if (AuthService.isLoggedIn) {
        await DatabaseService.addSearchHistory(ingredients: List.from(ingredients), filters: List.from(activeFilters), recipeNames: currentRecipes.map((r) => r.title).toList());
        await DatabaseService.incrementSearchCount();
      }
      await FirebaseService.logRecipeSearch(ingredients);
    } catch (e) {
      error = 'Could not load recipes. Check your connection and try again.';
    }
    isLoading = false; notifyListeners();
  }

  Future<void> toggleSave(Recipe recipe) async {
    final alreadySaved = isSaved(recipe.title);
    if (alreadySaved) {
      if (AuthService.isLoggedIn) await DatabaseService.unsaveRecipe(recipe.title);
      else savedRecipes.removeWhere((r) => r.title == recipe.title);
    } else {
      if (AuthService.isLoggedIn) await DatabaseService.saveRecipe(recipe);
      else savedRecipes.add(recipe);
      await FirebaseService.logRecipeSaved(recipe.title);
    }
    notifyListeners();
  }

  bool isSaved(String title) => savedRecipes.any((r) => r.title == title);

  Future<void> rateRecipe(String title, int rating) async {
    for (final r in [...currentRecipes, ...savedRecipes]) { if (r.title == title) r.rating = rating; }
    if (AuthService.isLoggedIn) await DatabaseService.updateRecipeRating(title, rating);
    notifyListeners();
  }

  Future<void> addToMealPlan(String day, String recipeTitle) async {
    mealPlan[day] = recipeTitle;
    if (AuthService.isLoggedIn) await DatabaseService.saveMealPlan(mealPlan);
    notifyListeners();
  }

  Future<void> removeMealPlan(String day) async {
    mealPlan.remove(day);
    if (AuthService.isLoggedIn) await DatabaseService.saveMealPlan(mealPlan);
    notifyListeners();
  }

  Future<void> addShoppingItems(List<String> items) async {
    if (AuthService.isLoggedIn) await DatabaseService.addShoppingItems(items);
    else { for (final item in items) shoppingItems.add({'id': DateTime.now().toString(), 'name': item, 'isDone': false}); notifyListeners(); }
  }

  Future<void> addShoppingItem(String name) async {
    if (name.trim().isEmpty) return;
    if (AuthService.isLoggedIn) await DatabaseService.addShoppingItem(name.trim());
    else { shoppingItems.add({'id': DateTime.now().toString(), 'name': name.trim(), 'isDone': false}); notifyListeners(); }
  }

  Future<void> toggleShoppingItem(int idx) async {
    final item = shoppingItems[idx]; final newVal = !(item['isDone'] as bool);
    if (AuthService.isLoggedIn) await DatabaseService.toggleShoppingItem(item['id'], newVal);
    else { shoppingItems[idx]['isDone'] = newVal; notifyListeners(); }
  }

  Future<void> deleteShoppingItem(int idx) async {
    if (AuthService.isLoggedIn) await DatabaseService.deleteShoppingItem(shoppingItems[idx]['id']);
    else { shoppingItems.removeAt(idx); notifyListeners(); }
  }

  Future<String> sendChat(String message) async {
    chatHistory.add({'role': 'user', 'content': message}); notifyListeners();
    try {
      final reply = await ApiService.chat(message: message, history: chatHistory.sublist(0, chatHistory.length - 1));
      chatHistory.add({'role': 'assistant', 'content': reply}); notifyListeners();
      return reply;
    } catch (e) { chatHistory.removeLast(); notifyListeners(); return 'Sorry, I could not connect. Try again!'; }
  }
}




