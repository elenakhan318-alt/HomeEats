import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FavouritesData extends ChangeNotifier {
  final List<Map<String, dynamic>> _favouriteMeals = [];
  final List<Map<String, dynamic>> _favouriteCooks = [];

  List<Map<String, dynamic>> get favouriteMeals {
    return List.unmodifiable(_favouriteMeals);
  }

  List<Map<String, dynamic>> get favouriteCooks {
    return List.unmodifiable(_favouriteCooks);
  }

  bool isMealFavourite(String mealId) {
    return _favouriteMeals.any(
      (meal) => meal['mealId']?.toString() == mealId,
    );
  }

  bool isCookFavourite(String cookId) {
    return _favouriteCooks.any(
      (cook) => cook['cookId']?.toString() == cookId,
    );
  }

  Future<void> loadFavourites() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      clearLocalFavourites();
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favourites')
        .get();

    _favouriteMeals.clear();
    _favouriteCooks.clear();

    for (final document in snapshot.docs) {
      final data = <String, dynamic>{
        ...document.data(),
        'documentId': document.id,
      };

      if (data['type'] == 'meal') {
        _favouriteMeals.add(data);
      }

      if (data['type'] == 'cook') {
        _favouriteCooks.add(data);
      }
    }

    notifyListeners();
  }

  Future<void> toggleMealFavourite({
    required String mealId,
    required String cookId,
    required String name,
    required String cook,
    required String price,
    required String emoji,
    required double rating,
    required int reviewCount,
    required String delivery,
    required int portionsLeft,
    required String description,
    required List<String> ingredients,
    required List<String> allergens,
    String? imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in to save favourites.',
      );
    }

    if (mealId.isEmpty) {
      throw Exception(
        'This meal could not be identified.',
      );
    }

    final reference = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favourites')
        .doc('meal_$mealId');

    if (isMealFavourite(mealId)) {
      await reference.delete();

      _favouriteMeals.removeWhere(
        (meal) => meal['mealId']?.toString() == mealId,
      );
    } else {
      final favourite = <String, dynamic>{
        'type': 'meal',
        'mealId': mealId,
        'cookId': cookId,
        'name': name,
        'cook': cook,
        'price': price,
        'emoji': emoji,
        'imageUrl': imageUrl,
        'rating': rating,
        'reviewCount': reviewCount,
        'delivery': delivery,
        'portionsLeft': portionsLeft,
        'description': description,
        'ingredients': ingredients,
        'allergens': allergens,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await reference.set(favourite);

      _favouriteMeals.add(favourite);
    }

    notifyListeners();
  }

  Future<void> toggleCookFavourite({
    required String cookId,
    required String cookName,
    String? profileImageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in to save favourites.',
      );
    }

    if (cookId.isEmpty) {
      throw Exception(
        'This cook could not be identified.',
      );
    }

    final reference = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favourites')
        .doc('cook_$cookId');

    if (isCookFavourite(cookId)) {
      await reference.delete();

      _favouriteCooks.removeWhere(
        (cook) => cook['cookId']?.toString() == cookId,
      );
    } else {
      final favourite = <String, dynamic>{
        'type': 'cook',
        'cookId': cookId,
        'cookName': cookName,
        'profileImageUrl': profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await reference.set(favourite);

      _favouriteCooks.add(favourite);
    }

    notifyListeners();
  }

  Future<void> removeMealFavourite(
    String mealId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || mealId.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favourites')
        .doc('meal_$mealId')
        .delete();

    _favouriteMeals.removeWhere(
      (meal) => meal['mealId']?.toString() == mealId,
    );

    notifyListeners();
  }

  Future<void> removeCookFavourite(
    String cookId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || cookId.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favourites')
        .doc('cook_$cookId')
        .delete();

    _favouriteCooks.removeWhere(
      (cook) => cook['cookId']?.toString() == cookId,
    );

    notifyListeners();
  }

  // Compatibility method used by older screens.
  bool isFavourite(String value) {
    return _favouriteMeals.any(
      (meal) =>
          meal['mealId']?.toString() == value ||
          meal['name']?.toString() == value,
    );
  }

  // Compatibility method used by older meal cards.
  Future<void> toggleFavourite(
    Map<String, dynamic> meal,
  ) async {
    final mealId =
        meal['mealId']?.toString() ??
        meal['name']?.toString() ??
        '';

    final cookId =
        meal['cookId']?.toString() ?? '';

    final name =
        meal['name']?.toString() ?? 'Meal';

    final cook =
        meal['cook']?.toString() ?? 'HomeEats Cook';

    final price =
        meal['price']?.toString() ?? '£0.00';

    final emoji =
        meal['emoji']?.toString() ?? '🍽️';

    final imageUrl =
        meal['imageUrl']?.toString();

    final ratingValue = meal['rating'];

    final rating = ratingValue is num
        ? ratingValue.toDouble()
        : double.tryParse(
              ratingValue?.toString() ?? '',
            ) ??
            0;

    final reviewValue =
        meal['reviewCount'] ?? meal['reviews'];

    final reviewCount = reviewValue is num
        ? reviewValue.toInt()
        : int.tryParse(
              reviewValue?.toString() ?? '',
            ) ??
            0;

    final portionsValue =
        meal['portionsLeft'];

    final portionsLeft = portionsValue is num
        ? portionsValue.toInt()
        : int.tryParse(
              portionsValue?.toString() ?? '',
            ) ??
            0;

    final ingredientsValue =
        meal['ingredients'];

    final ingredients = ingredientsValue is List
        ? ingredientsValue
            .map((item) => item.toString())
            .toList()
        : const <String>[
            'See cook for ingredients',
          ];

    final allergensValue =
        meal['allergens'];

    final allergens = allergensValue is List
        ? allergensValue
            .map((item) => item.toString())
            .toList()
        : const <String>[
            'See cook for allergen information',
          ];

    await toggleMealFavourite(
      mealId: mealId,
      cookId: cookId,
      name: name,
      cook: cook,
      price: price,
      emoji: emoji,
      imageUrl: imageUrl,
      rating: rating,
      reviewCount: reviewCount,
      delivery:
          meal['delivery']?.toString() ??
          'View meal for availability',
      portionsLeft: portionsLeft,
      description:
          meal['description']?.toString() ??
          'A freshly prepared homemade meal available through HomeEats.',
      ingredients: ingredients,
      allergens: allergens,
    );
  }

  // Compatibility method used by older screens.
  Future<void> removeFavourite(
    String value,
  ) async {
    Map<String, dynamic>? matchingMeal;

    for (final meal in _favouriteMeals) {
      final matches =
          meal['mealId']?.toString() == value ||
          meal['name']?.toString() == value;

      if (matches) {
        matchingMeal = meal;
        break;
      }
    }

    if (matchingMeal == null) {
      return;
    }

    final mealId =
        matchingMeal['mealId']?.toString() ?? '';

    if (mealId.isEmpty) {
      return;
    }

    await removeMealFavourite(mealId);
  }

  void clearLocalFavourites() {
    _favouriteMeals.clear();
    _favouriteCooks.clear();
    notifyListeners();
  }
}

final FavouritesData favouritesData =
    FavouritesData();