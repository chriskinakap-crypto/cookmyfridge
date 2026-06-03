import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import 'auth_service.dart';

class DatabaseService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid => AuthService.userId;

  // Shortcuts to user subcollections
  static CollectionReference get _savedRef =>
      _db.collection('users').doc(_uid).collection('saved_recipes');
  static CollectionReference get _historyRef =>
      _db.collection('users').doc(_uid).collection('search_history');
  static CollectionReference get _shoppingRef =>
      _db.collection('users').doc(_uid).collection('shopping_list');
  static DocumentReference get _mealPlanRef =>
      _db.collection('users').doc(_uid).collection('data').doc('meal_plan');

  // ── Saved Recipes ─────────────────────────────────────────────────────────
  static Future<void> saveRecipe(Recipe recipe) async {
    await _savedRef.doc(_docId(recipe.title)).set({
      ...recipe.toJson(),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> unsaveRecipe(String title) async {
    await _savedRef.doc(_docId(title)).delete();
  }

  static Stream<List<Recipe>> savedRecipesStream() {
    return _savedRef
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Recipe.fromJson(d.data() as Map<String, dynamic>)).toList());
  }

  static Future<void> updateRecipeRating(String title, int rating) async {
    await _savedRef.doc(_docId(title)).update({'rating': rating});
  }

  // ── Search History ────────────────────────────────────────────────────────
  static Future<void> addSearchHistory({
    required List<String> ingredients,
    required List<String> filters,
    required List<String> recipeNames,
  }) async {
    await _historyRef.add({
      'ingredients': ingredients,
      'filters': filters,
      'recipeNames': recipeNames,
      'searchedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> historyStream() {
    return _historyRef
        .orderBy('searchedAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data() as Map<String, dynamic>).toList());
  }

  // ── Shopping List ─────────────────────────────────────────────────────────
  static Future<void> addShoppingItem(String name) async {
    await _shoppingRef.add({
      'name': name,
      'isDone': false,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addShoppingItems(List<String> items) async {
    final batch = _db.batch();
    for (final item in items) {
      final doc = _shoppingRef.doc();
      batch.set(doc, {
        'name': item,
        'isDone': false,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static Future<void> toggleShoppingItem(String docId, bool isDone) async {
    await _shoppingRef.doc(docId).update({'isDone': isDone});
  }

  static Future<void> deleteShoppingItem(String docId) async {
    await _shoppingRef.doc(docId).delete();
  }

  static Future<void> clearDoneItems() async {
    final snap = await _shoppingRef.where('isDone', isEqualTo: true).get();
    final batch = _db.batch();
    for (final doc in snap.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  static Stream<QuerySnapshot> shoppingListStream() {
    return _shoppingRef.orderBy('addedAt').snapshots();
  }

  // ── Meal Plan ─────────────────────────────────────────────────────────────
  static Future<void> saveMealPlan(Map<String, String> plan) async {
    await _mealPlanRef.set({'plan': plan, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static Stream<Map<String, String>> mealPlanStream() {
    return _mealPlanRef.snapshots().map((snap) {
      if (!snap.exists) return {};
      final data = snap.data() as Map<String, dynamic>?;
      final plan = data?['plan'] as Map<String, dynamic>? ?? {};
      return plan.map((k, v) => MapEntry(k, v.toString()));
    });
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  static Future<void> incrementSearchCount() async {
    await _db.collection('users').doc(_uid).update({
      'totalSearches': FieldValue.increment(1),
    });
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    final snap = await _db.collection('users').doc(_uid).get();
    return snap.data() ?? {};
  }

  // ── Community Recipes (shared public recipes) ────────────────────────────
  static Stream<List<Recipe>> communityRecipesStream({String? filter}) {
    Query query = _db.collection('community_recipes')
        .orderBy('saves', descending: true)
        .limit(20);
    if (filter != null) query = query.where('diet', arrayContains: filter);
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => Recipe.fromJson(d.data() as Map<String, dynamic>)).toList());
  }

  static Future<void> shareRecipeToCommunity(Recipe recipe) async {
    final existing = await _db.collection('community_recipes')
        .where('title', isEqualTo: recipe.title)
        .get();
    if (existing.docs.isEmpty) {
      await _db.collection('community_recipes').add({
        ...recipe.toJson(),
        'sharedBy': AuthService.currentUser?.displayName ?? 'Anonymous',
        'sharedAt': FieldValue.serverTimestamp(),
        'saves': 0,
      });
    }
  }

  static String _docId(String title) =>
      title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
}
