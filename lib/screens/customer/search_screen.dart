import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'meal_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();

  String selectedCuisine = 'All';
  bool isDeliverySelected = true;

  final List<String> cuisines = const [
    'All',
    'Pakistani',
    'Caribbean',
    'Mediterranean',
    'Indian',
    'Italian',
    'Chinese',
    'African',
    'British',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  int _intValue(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _doubleValue(dynamic value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _priceText(dynamic value) {
    if (value is num) {
      return '£${value.toDouble().toStringAsFixed(2)}';
    }

    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return '£0.00';
    }

    if (text.startsWith('£')) {
      return text;
    }

    final number = double.tryParse(text);

    if (number != null) {
      return '£${number.toStringAsFixed(2)}';
    }

    return text;
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return <String>[];
  }

  Future<void> _openMeal(
  Map<String, dynamic> meal,
  String mealId,
  String cookId,
) async {
    String cookName = _stringValue(
  meal['cookName'] ?? meal['cook'],
  fallback: '',
);

if (cookName.isEmpty && cookId.isNotEmpty) {
  final cookDocument = await FirebaseFirestore.instance
      .collection('users')
      .doc(cookId)
      .get();

  final cookData = cookDocument.data();

  cookName = _stringValue(
  cookData?['businessName'] ??
      cookData?['fullName'] ??
      cookData?['displayName'] ??
      cookData?['name'],
  fallback: 'Home cook',
);
}

if (cookName.isEmpty) {
  cookName = 'Home cook';
  }
    final rating = _doubleValue(meal['rating']);

    final reviewCount = _intValue(
      meal['reviewCount'] ?? meal['reviews'],
    );
    final portionsLeft = _intValue(
  meal['remainingPortions'] ?? meal['portions'],
);

final now = DateTime.now();

final mealDateValue = meal['mealDate'];
final orderOpenValue = meal['orderOpenAt'];
final orderCloseValue = meal['orderCloseAt'];

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
    meal['readyTimeLabel']?.toString() ??
    'Time not set';

final cutOffTime =
    meal['cutOffTimeLabel']?.toString() ??
    'Time not set';
    if (!mounted) {
  return;
}
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailsScreen(
          mealId: mealId,
          cookId: cookId,
          portionsLeft: portionsLeft,
          mealName: _stringValue(
            meal['mealName'] ?? meal['name'],
            fallback: 'Meal',
          ),
          cookName: cookName,
          price: _priceText(meal['price']),
          rating: rating,
          reviewCount: reviewCount,
          deliveryText: isDeliverySelected
              ? 'Available for delivery'
              : 'Available for collection',
          emoji: _stringValue(
            meal['emoji'],
            fallback: '🍽️',
          ),
          imageUrl: meal['imageUrl']?.toString(),
          description: _stringValue(
            meal['description'],
            fallback: 'No description available.',
          ),
          ingredients: _stringList(meal['ingredients']),
          allergens: _stringList(meal['allergens']),
          canOrderNow: canOrderNow,
readyTime: readyTime,
cutOffTime: cutOffTime,
          
        ),
      ),
    );
  }

  bool _matchesFilters(Map<String, dynamic> meal) {
    final query = searchController.text.trim().toLowerCase();

    final name = _stringValue(
  meal['mealName'] ?? meal['name'],
).toLowerCase();

    final cookName = _stringValue(
      meal['cookName'] ?? meal['cook'],
    ).toLowerCase();

    final cuisine = _stringValue(
      meal['cuisine'],
    ).toLowerCase();

    final remainingPortions = _intValue(
      meal['remainingPortions'] ?? meal['portions'],
    );

    final deliveryAvailable =
        meal['deliveryAvailable'] == true;

    final collectionAvailable =
        meal['collectionAvailable'] == true;

    final matchesSearch =
        query.isEmpty ||
        name.contains(query) ||
        cookName.contains(query) ||
        cuisine.contains(query);

    final matchesCuisine =
        selectedCuisine == 'All' ||
        cuisine == selectedCuisine.toLowerCase();

    final matchesOrderType = isDeliverySelected
        ? deliveryAvailable
        : collectionAvailable;

    return remainingPortions > 0 &&
        matchesSearch &&
        matchesCuisine &&
        matchesOrderType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Meals'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.regular,
              AppSpacing.page,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Delivery',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    selected: isDeliverySelected,
                    onSelected: (_) {
                      setState(() {
                        isDeliverySelected = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: ChoiceChip(
                    label: const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Collection',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    selected: !isDeliverySelected,
                    onSelected: (_) {
                      setState(() {
                        isDeliverySelected = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: TextField(
              controller: searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search meals, cooks or cuisines',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.page,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: cuisines.length,
              separatorBuilder: (context, index) {
                return const SizedBox(
                  width: AppSpacing.small,
                );
              },
              itemBuilder: (context, index) {
                final cuisine = cuisines[index];
                final isSelected =
                    selectedCuisine == cuisine;

                return ChoiceChip(
                  label: Text(cuisine),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedCuisine = cuisine;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.regular),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('meals')
                  .where('active', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load meals',
                    message:
                        'Please check your connection and try again.',
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final mealDocuments = snapshot.data?.docs ?? [];

                final filteredMeals = mealDocuments
                    .where((document) {
                      return _matchesFilters(document.data());
                    })
                    .toList();

                if (filteredMeals.isEmpty) {
                  return _buildEmptyResults();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    0,
                    AppSpacing.page,
                    AppSpacing.page,
                  ),
                  itemCount: filteredMeals.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(
                      height: AppSpacing.regular,
                    );
                  },
                  itemBuilder: (context, index) {
 final document = filteredMeals[index];
final meal = document.data();

return _buildMealResult(
  meal,
  document.id,
  meal['cookId']?.toString() ?? '',
);
}
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealResult(
  Map<String, dynamic> meal,
  String mealId,
  String cookId,
) {
   final mealName = _stringValue(
  meal['mealName'] ?? meal['name'],
  fallback: 'Meal',
);
    final cookName = _stringValue(
      meal['cookName'] ?? meal['cook'],
      fallback: 'Home cook',
    );

    final emoji = _stringValue(
      meal['emoji'],
      fallback: '🍽️',
    );

    final imageUrl = _stringValue(meal['imageUrl']);

    final rating = _doubleValue(meal['rating']);

    final reviewCount = _intValue(
      meal['reviewCount'] ?? meal['reviews'],
    );

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
  _openMeal(
  meal,
  mealId,
  cookId,
);
},
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.regular,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppRadius.medium,
                ),
                child: Container(
                  width: 82,
                  height: 82,
                  color: AppColors.primaryLight,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(
                                  fontSize: 42,
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(
                              fontSize: 42,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.regular),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
  future: cookId.isEmpty
      ? null
      : FirebaseFirestore.instance
          .collection('users')
          .doc(cookId)
          .get(),
  builder: (context, cookSnapshot) {
    var displayCookName = cookName;

    if (cookSnapshot.hasData) {
      final cookData = cookSnapshot.data?.data();

      displayCookName = _stringValue(
        cookData?['businessName'] ??
            cookData?['fullName'] ??
            cookData?['displayName'] ??
            cookData?['name'],
        fallback: cookName,
      );
    }

    return Text(
      displayCookName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  },
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
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '($reviewCount)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isDeliverySelected
                          ? 'Available for delivery'
                          : 'Available for collection',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                _priceText(meal['price']),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyResults() {
    final orderType = isDeliverySelected
        ? 'delivery'
        : 'collection';

    return _buildMessage(
      icon: Icons.search_off_rounded,
      title: 'No meals found',
      message:
          'No $orderType meals match your search and cuisine filters.',
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.page,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 70,
              color: AppColors.textSecondary,
            ),
            const SizedBox(
              height: AppSpacing.regular,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: AppSpacing.small,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}