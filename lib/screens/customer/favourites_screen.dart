import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'cook_profile_screen.dart';
import 'favourites_data.dart';
import 'meal_details_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() =>
      _FavouritesScreenState();
}

class _FavouritesScreenState
    extends State<FavouritesScreen> {
  Future<void> _removeMealFavourite(
    Map<String, dynamic> meal,
  ) async {
    final mealId = meal['mealId']?.toString() ?? '';
    final mealName =
        meal['name']?.toString() ?? 'Meal';

    if (mealId.isEmpty) {
      return;
    }

    try {
      await favouritesData.removeMealFavourite(mealId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$mealName removed from favourites',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Favourite could not be removed: $error',
            ),
          ),
        );
    }
  }

  Future<void> _removeCookFavourite(
    Map<String, dynamic> cook,
  ) async {
    final cookId =
        cook['cookId']?.toString() ?? '';

    final cookName =
        cook['cookName']?.toString() ??
            'HomeEats Cook';

    if (cookId.isEmpty) {
      return;
    }

    try {
      await favouritesData.removeCookFavourite(cookId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$cookName removed from favourites',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Favourite could not be removed: $error',
            ),
          ),
        );
    }
  }

  Future<void> _openMeal(Map<String, dynamic> meal) async {
    final mealId =
        meal['mealId']?.toString() ?? '';
        Map<String, dynamic> liveMeal = meal;

if (mealId.isNotEmpty) {
  final mealDocument = await FirebaseFirestore.instance
      .collection('meals')
      .doc(mealId)
      .get();

  final currentMealData = mealDocument.data();

  if (currentMealData != null) {
    liveMeal = {
      ...meal,
      ...currentMealData,
    };
  }
}

    final cookId =
         liveMeal['cookId']?.toString() ?? '';

    final mealName =
         liveMeal['name']?.toString() ?? 'Meal';

    final cookName =
         liveMeal['cook']?.toString() ??
            'HomeEats Cook';

    final price =
        liveMeal['price']?.toString() ?? '£0.00';

    final emoji =
        liveMeal['emoji']?.toString() ?? '🍽️';

    final imageUrl =
        liveMeal['imageUrl']?.toString();

    final ratingValue = liveMeal['rating'];

final rating = ratingValue is num
    ? ratingValue.toDouble()
    : double.tryParse(
          ratingValue?.toString() ?? '',
        ) ??
        0;

final reviewValue =
    liveMeal['reviewCount'] ?? liveMeal['reviews'];

final reviewCount = reviewValue is num
    ? reviewValue.toInt()
    : int.tryParse(
          reviewValue?.toString() ?? '',
        ) ??
        0;

final portionsValue =
    liveMeal['remainingPortions'] ??
    liveMeal['portionsLeft'] ??
    liveMeal['portions'];

final portionsLeft = portionsValue is num
    ? portionsValue.toInt()
    : int.tryParse(
          portionsValue?.toString() ?? '',
        ) ??
        0;

final deliveryText =
    liveMeal['delivery']?.toString() ??
        'See meal for availability';

final description =
    liveMeal['description']?.toString() ??
        'A freshly prepared homemade meal available through HomeEats.';

final ingredientsValue = liveMeal['ingredients'];

final ingredients = ingredientsValue is List
    ? ingredientsValue
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList()
    : ingredientsValue is String &&
            ingredientsValue.trim().isNotEmpty
        ? ingredientsValue
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList()
        : const <String>[
            'See cook for ingredients',
          ];
final allergensValue = liveMeal['allergens'];

final allergens = allergensValue is List
    ? allergensValue
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList()
    : allergensValue is String &&
            allergensValue.trim().isNotEmpty
        ? allergensValue
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList()
        : const <String>[
            'See cook for allergen information',
          ];
                final now = DateTime.now();

final mealDateValue = liveMeal['mealDate'];
final orderOpenValue = liveMeal['orderOpenAt'];
final orderCloseValue = liveMeal['orderCloseAt'];

final mealDate = mealDateValue is Timestamp
    ? mealDateValue.toDate()
    : null;

final orderOpenAt = orderOpenValue is Timestamp
    ? orderOpenValue.toDate()
    : null;

final orderCloseAt = orderCloseValue is Timestamp
    ? orderCloseValue.toDate()
    : null;

final today = DateTime(
  now.year,
  now.month,
  now.day,
);

final normalizedMealDate = mealDate == null
    ? null
    : DateTime(
        mealDate.year,
        mealDate.month,
        mealDate.day,
      );

final isFutureMeal =
    normalizedMealDate != null &&
    normalizedMealDate.isAfter(today);

final isBeforeOrdering =
    orderOpenAt != null &&
    now.isBefore(orderOpenAt);

final isAfterOrdering =
    orderCloseAt != null &&
    !now.isBefore(orderCloseAt);

final canOrderNow =
    !isFutureMeal &&
    !isBeforeOrdering &&
    !isAfterOrdering;

final readyTime =
    liveMeal['readyTimeLabel']?.toString() ??
        'Time not set';

final cutOffTime =
    liveMeal['cutOffTimeLabel']?.toString() ??
        'Time not set';
      if (!mounted) {
  return;
}
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealDetailsScreen(
          mealId: mealId,
          cookId: cookId,
          portionsLeft: portionsLeft,
          mealName: mealName,
          cookName: cookName,
          price: price,
          rating: rating,
          reviewCount: reviewCount,
          deliveryText: deliveryText,
          emoji: emoji,
          imageUrl: imageUrl,
          description: description,
          ingredients: ingredients,
          allergens: allergens,
          canOrderNow: canOrderNow,
readyTime: readyTime,
cutOffTime: cutOffTime,
        ),
      ),
    );
  }

  void _openCook(Map<String, dynamic> cook) {
    final cookId =
        cook['cookId']?.toString() ?? '';

    if (cookId.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookProfileScreen(
          cookId: cookId,
        ),
      ),
    );
  }

  void _addToBasket(String mealName) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$mealName added to basket',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: favouritesData,
      builder: (context, child) {
        final favouriteMeals =
            favouritesData.favouriteMeals;

        final favouriteCooks =
            favouritesData.favouriteCooks;

        final hasFavourites =
            favouriteMeals.isNotEmpty ||
                favouriteCooks.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My Favourites'),
            centerTitle: true,
          ),
          body: hasFavourites
              ? ListView(
                  padding: const EdgeInsets.all(
                    AppSpacing.page,
                  ),
                  children: [
                    if (favouriteMeals.isNotEmpty) ...[
                      const Text(
                        'Favourite Meals',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      for (var index = 0;
                          index <
                              favouriteMeals.length;
                          index++) ...[
                        _buildFavouriteMealCard(
                          favouriteMeals[index],
                        ),
                        if (index <
                            favouriteMeals.length - 1)
                          const SizedBox(
                            height:
                                AppSpacing.regular,
                          ),
                      ],
                    ],
                    if (favouriteMeals.isNotEmpty &&
                        favouriteCooks.isNotEmpty)
                      const SizedBox(
                        height: AppSpacing.section,
                      ),
                    if (favouriteCooks.isNotEmpty) ...[
                      const Text(
                        'Favourite Cooks',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      for (var index = 0;
                          index <
                              favouriteCooks.length;
                          index++) ...[
                        _buildFavouriteCookCard(
                          favouriteCooks[index],
                        ),
                        if (index <
                            favouriteCooks.length - 1)
                          const SizedBox(
                            height:
                                AppSpacing.regular,
                          ),
                      ],
                    ],
                  ],
                )
              : _buildEmptyFavourites(),
        );
      },
    );
  }

  Widget _buildFavouriteMealCard(
    Map<String, dynamic> meal,
  ) {
    final mealName =
        meal['name']?.toString() ?? 'Meal';

    final cookName =
        meal['cook']?.toString() ??
            'HomeEats Cook';

    final price =
        meal['price']?.toString() ?? '£0.00';

    final emoji =
        meal['emoji']?.toString() ?? '🍽️';

    final delivery =
        meal['delivery']?.toString() ??
            'View meal for availability';

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

    return Container(
      padding: const EdgeInsets.all(
        AppSpacing.regular,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(
              AppRadius.medium,
            ),
            onTap: () {
              _openMeal(meal);
            },
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(
                      AppRadius.medium,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 42,
                    ),
                  ),
                ),
                const SizedBox(
                  width: AppSpacing.regular,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealName,
                        style: const TextStyle(
                          color:
                              AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cookName,
                        style: const TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.rating,
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reviewCount == 0
                                ? 'No reviews yet'
                                : '${rating.toStringAsFixed(1)} '
                                    '($reviewCount)',
                            style: const TextStyle(
                              color: AppColors
                                  .textPrimary,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        delivery,
                        style: const TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip:
                          'Remove favourite meal',
                      onPressed: () {
                        _removeMealFavourite(meal);
                      },
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: AppSpacing.regular,
          ),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () {
                _addToBasket(mealName);
              },
              icon: const Icon(
                Icons.add_shopping_cart_rounded,
                size: 18,
              ),
              label: const Text('Add to Basket'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavouriteCookCard(
    Map<String, dynamic> cook,
  ) {
    final cookName =
        cook['cookName']?.toString() ??
            'HomeEats Cook';

    final profileImageUrl =
        cook['profileImageUrl']?.toString() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        AppRadius.card,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        onTap: () {
          _openCook(cook);
        },
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.regular,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor:
                    AppColors.primaryLight,
                backgroundImage:
                    profileImageUrl.isEmpty
                        ? null
                        : NetworkImage(
                            profileImageUrl,
                          ),
                child: profileImageUrl.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 34,
                      )
                    : null,
              ),
              const SizedBox(
                width: AppSpacing.regular,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      cookName,
                      style: const TextStyle(
                        color:
                            AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.green,
                          size: 17,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Verified local cook',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove favourite cook',
                onPressed: () {
                  _removeCookFavourite(cook);
                },
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.red,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFavourites() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.page,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 55,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(
              height: AppSpacing.large,
            ),
            const Text(
              'No favourites yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: AppSpacing.small,
            ),
            const Text(
              'Tap the heart icon on a meal or cook profile to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}