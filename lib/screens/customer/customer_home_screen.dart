import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../auth/welcome_screen.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'meal_details_screen.dart';
import 'search_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState
    extends State<CustomerHomeScreen> {
  final ScrollController _scrollController =
      ScrollController();

  bool _isDeliverySelected = true;
  String? _selectedCuisine;
  

  void _showTemporaryMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: AppSpacing.page,
            right: AppSpacing.page,
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: AppSpacing.large),
              _buildLocation(),
              const SizedBox(height: AppSpacing.extraLarge),
              _buildGreeting(),
              const SizedBox(height: AppSpacing.large),
              _buildOrderTypeSelector(),
              const SizedBox(height: AppSpacing.regular),
             _buildSearchBar(),

const SizedBox(height: AppSpacing.large),

_buildCuisineSection(),

const SizedBox(height: AppSpacing.large),

_buildPromotionBanner(),
              const SizedBox(height: AppSpacing.section),
              _buildLiveMeals(),
              const SizedBox(height: AppSpacing.large),
_buildUpcomingMeals(),
              const SizedBox(height: AppSpacing.section),
_buildCookSpotlight(),
            ],
          ),
        ),
      ),
    ),
  );
}
@override
void dispose() {
  _scrollController.dispose();
  super.dispose();
}
  Widget _buildTopBar() {
  return Padding(
    padding: const EdgeInsets.only(
      top: AppSpacing.small,
    ),
    child: Row(
      children: [
   Text(
  'Home',
  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
),
        const Spacer(),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            _showTemporaryMessage(
              'You have no new notifications.',
            );
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
          ),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: () async {
            final shouldSignOut =
                await showDialog<bool>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text('Sign out'),
                  content: const Text(
                    'Are you sure you want to '
                    'sign out of HomeEats?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          false,
                        );
                      },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      },
                      child: const Text('Sign out'),
                    ),
                  ],
                );
              },
            );

          if (shouldSignOut == true) {
  await FirebaseAuth.instance.signOut();

  if (!mounted) {
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) => const WelcomeScreen(),
    ),
    (route) => false,
  );
}
          },
          icon: const Icon(
            Icons.logout_rounded,
          ),
        ),
      ],
    ),
  );
}
  Widget _buildLocation() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: () {
        _showTemporaryMessage('Location selection will open here.');
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.small,
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivering to',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Birmingham',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
  final hour = DateTime.now().hour;
  final user = FirebaseAuth.instance.currentUser;

  String greeting;

  if (hour < 12) {
    greeting = 'Good morning';
  } else if (hour < 18) {
    greeting = 'Good afternoon';
  } else {
    greeting = 'Good evening';
  }

  final displayName = user?.displayName?.trim() ?? '';

  final greetingText = displayName.isEmpty
      ? '$greeting 👋'
      : '$greeting, $displayName 👋';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        greetingText,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
      ),
      const SizedBox(
        height: AppSpacing.small,
      ),
      const Text(
        'What homemade meal are you craving today?',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
      ),
    ],
  );
}

  Widget _buildOrderTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOrderTypeButton(
              title: 'Delivery',
              icon: Icons.delivery_dining_rounded,
              isSelected: _isDeliverySelected,
              onTap: () {
                setState(() {
                  _isDeliverySelected = true;
                });
              },
            ),
          ),
          Expanded(
            child: _buildOrderTypeButton(
              title: 'Collection',
              icon: Icons.shopping_bag_outlined,
              isSelected: !_isDeliverySelected,
              onTap: () {
                setState(() {
                  _isDeliverySelected = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
Widget _buildSearchBar() {
  return TextField(
    readOnly: true,
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SearchScreen(),
        ),
      );
    },
    decoration: const InputDecoration(
      hintText: 'Search meals, cooks or cuisines',
      prefixIcon: Icon(
        Icons.search_rounded,
      ),
    ),
  );
}



  Widget _buildPromotionBanner() {
    return Container(
      width: double.infinity,
      height: 235,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFC85E32),
            Color(0xFFEDA16C),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -10,
            child: Icon(
              Icons.restaurant_rounded,
              size: 180,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                const Spacer(),
                const Text(
  'Homemade food\nyou can trust.',
  style: TextStyle(
    color: Colors.white,
    fontSize: 25,
    height: 1.08,
    fontWeight: FontWeight.w900,
  ),
),
                const SizedBox(height: AppSpacing.small),
                const Text(
  'Freshly prepared by verified local cooks.',
  style: TextStyle(
    color: Colors.white,
    fontSize: 13,
  ),
),
                const SizedBox(height: AppSpacing.small),
                FilledButton(
                  onPressed: () {
                    _showTemporaryMessage(
                      'Available meals are shown below.',
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Browse Meals'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMeals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       _buildSectionHeading(
  title: 'Available Near You',
  subtitle: _isDeliverySelected
      ? 'Meals available for delivery'
      : 'Meals available for collection',
),
        const SizedBox(height: AppSpacing.regular),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('meals')
              .where('active', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildMessageCard(
                icon: Icons.error_outline_rounded,
                title: 'Meals could not be loaded',
                message: snapshot.error.toString(),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.large),
                  child: CircularProgressIndicator(),
                ),
              );
            }

           final meals = snapshot.data?.docs.where((document) {
  final data = document.data();
  final mealDateValue = data['mealDate'];

if (mealDateValue is! Timestamp) {
  return false;
}

final mealDate = mealDateValue.toDate();

final now = DateTime.now();

final today = DateTime(
  now.year,
  now.month,
  now.day,
);

final normalizedMealDate = DateTime(
  mealDate.year,
  mealDate.month,
  mealDate.day,
);

final isToday = normalizedMealDate == today;

  final remainingValue =
      data['remainingPortions'] ?? data['portions'];

  final remainingPortions = remainingValue is num
      ? remainingValue.toInt()
      : int.tryParse(
            remainingValue?.toString() ?? '',
          ) ??
          0;

 final deliveryAvailable =
    data['deliveryAvailable'] == true;

final collectionAvailable =
    data['collectionAvailable'] == true;

final matchesSelectedOrderType = _isDeliverySelected
    ? deliveryAvailable
    : collectionAvailable;

final mealCuisine =
    data['cuisine']?.toString().trim();

final matchesSelectedCuisine =
    _selectedCuisine == null ||
    mealCuisine == _selectedCuisine;

return isToday &&
    remainingPortions > 0 &&
    matchesSelectedOrderType &&
    matchesSelectedCuisine;
}).toList() ??
    []; 

            meals.sort((first, second) {
              final firstTimestamp =
                  first.data()['createdAt'] as Timestamp?;

              final secondTimestamp =
                  second.data()['createdAt'] as Timestamp?;

              if (firstTimestamp == null &&
                  secondTimestamp == null) {
                return 0;
              }

              if (firstTimestamp == null) {
                return 1;
              }

              if (secondTimestamp == null) {
                return -1;
              }

              return secondTimestamp.compareTo(firstTimestamp);
            });

            if (meals.isEmpty) {
  return _buildMessageCard(
    icon: Icons.restaurant_menu_rounded,
    title: 'No meals available',
    message: _isDeliverySelected
        ? 'There are currently no delivery meals available.'
        : 'There are currently no collection meals available.',
  );
}

            return Column(
              children: [
                for (var index = 0;
                    index < meals.length;
                    index++) ...[
                  _buildMealCard(
                    mealId: meals[index].id,
                    data: meals[index].data()
                  ),
                  if (index < meals.length - 1)
                    const SizedBox(
                      height: AppSpacing.regular,
                    ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMealCard({
  required String mealId,
  required Map<String, dynamic> data,
  bool showMealDate = false,
}) {
  final mealName =
      data['mealName']?.toString() ?? 'Unnamed meal';

  final cookId =
      data['cookId']?.toString() ?? '';

  final cookName =
      data['cookName']?.toString() ?? 'HomeEats Cook';

  final priceValue = data['price'];

  final price = priceValue is num
      ? priceValue.toDouble()
      : double.tryParse(
            priceValue?.toString() ?? '',
          ) ??
          0;

  final portionsValue =
      data['remainingPortions'] ?? data['portions'];

  final portions = portionsValue is num
      ? portionsValue.toInt()
      : int.tryParse(
            portionsValue?.toString() ?? '',
          ) ??
          0;

  final readyTime =
      data['readyTimeLabel']?.toString() ??
          'Time not set';
          final cutOffTime =
    data['cutOffTimeLabel']?.toString() ??
    'Time not set';
    final mealDateValue = data['mealDate'];

String mealDateText = '';

if (mealDateValue is Timestamp) {
  final mealDate = mealDateValue.toDate();

  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  mealDateText =
      '${dayNames[mealDate.weekday - 1]}, '
      '${mealDate.day} ${monthNames[mealDate.month - 1]}';
}
final now = DateTime.now();

final orderOpenValue = data['orderOpenAt'];
final orderCloseValue = data['orderCloseAt'];

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
debugPrint(
  'ORDER DEBUG: ${data['mealName']} | '
  'now=$now | '
  'mealDate=$mealDate | '
  'orderOpenAt=$orderOpenAt | '
  'orderCloseAt=$orderCloseAt | '
  'future=$isFutureMeal | '
  'before=$isBeforeOrdering | '
  'after=$isAfterOrdering | '
  'canOrder=$canOrderNow',
);
  final ingredientsText =
      data['ingredients']?.toString() ?? '';

  final allergensText =
      data['allergens']?.toString() ?? 'None';

  final ingredients = ingredientsText
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  final allergens = allergensText
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  final deliveryAvailable =
      data['deliveryAvailable'] == true;

  final collectionAvailable =
      data['collectionAvailable'] == true;

  final fulfilmentOptions = <String>[];

  if (deliveryAvailable) {
    fulfilmentOptions.add('Delivery');
  }

  if (collectionAvailable) {
    fulfilmentOptions.add('Collection');
  }

  final fulfilmentText =
      fulfilmentOptions.isEmpty
          ? 'Fulfilment not specified'
          : fulfilmentOptions.join(' • ');

final ratingValue = data['averageRating'];

  final rating = ratingValue is num
      ? ratingValue.toDouble()
      : double.tryParse(
            ratingValue?.toString() ?? '',
          ) ??
          0;

  final reviewCountValue = data['reviewCount'];

  final reviewCount = reviewCountValue is num
      ? reviewCountValue.toInt()
      : int.tryParse(
            reviewCountValue?.toString() ?? '',
          ) ??
          0;

  final isVerified =
      data['cookVerified'] == true ||
      data['isCookVerified'] == true;

  const placeholderImage =
      'https://images.unsplash.com/'
      'photo-1547592180-85f173990554'
      '?auto=format&fit=crop&w=1200&q=80';

  final imageUrl =
      data['imageUrl']?.toString().trim();

  final displayedImage =
      imageUrl != null && imageUrl.isNotEmpty
          ? imageUrl
          : placeholderImage;
          debugPrint(
  'MEAL DEBUG: $mealName | $mealId | imageUrl=$imageUrl | displayedImage=$displayedImage',
);

  return Material(
    color: AppColors.surface,
    elevation: 1,
    shadowColor: AppColors.shadow,
    borderRadius: BorderRadius.circular(
      AppRadius.card,
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(
        AppRadius.card,
      ),
      onTap: () async {
  String resolvedCookName = cookName;

  if (cookId.isNotEmpty) {
    final cookDocument =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cookId)
            .get();

    final cookData = cookDocument.data();

    resolvedCookName =
        cookData?['businessName']?.toString() ??
            cookData?['fullName']?.toString() ??
            cookData?['displayName']?.toString() ??
            cookData?['name']?.toString() ??
            cookName;
  }

  if (!mounted) {
  return;
}

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          MealDetailsScreen(
        mealId: mealId,
        cookId: cookId,
        mealName: mealName,
        cookName: resolvedCookName,
        price: '£${price.toStringAsFixed(2)}',
        rating: rating,
        reviewCount: reviewCount,
        portionsLeft: portions,
        deliveryText:
            '$fulfilmentText • Ready $readyTime',
        emoji: '🍽️',
        imageUrl: displayedImage,
        description:
            data['description']?.toString() ??
                'A freshly prepared homemade meal available through HomeEats.',
        ingredients: ingredients.isEmpty
            ? const [
                'See cook for ingredients',
              ]
            : ingredients,
        allergens: allergens.isEmpty
            ? const ['None listed']
            : allergens,
        canOrderNow: canOrderNow,
        readyTime: readyTime,
        cutOffTime: cutOffTime,
      ),
    ),
  );
},
child: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.regular,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                AppRadius.medium,
              ),
              child: Image.network(
                displayedImage,
                width: 104,
                height: 112,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  debugPrint('MEAL IMAGE ERROR: $error');
                  return Container(
                    width: 104,
                    height: 112,
                    color: AppColors.primaryLight,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.primary,
                      size: 42,
                    ),
                  );
                },
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Container(
                    width: 104,
                    height: 112,
                    color: AppColors.primaryLight,
                    alignment: Alignment.center,
                    child:
                        const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  );
                },
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
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          mealName,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                                AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '£${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (showMealDate &&
    mealDateText.isNotEmpty) ...[
  const SizedBox(height: 4),
  Text(
    mealDateText,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  ),
],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Flexible(
  child: FutureBuilder<
      DocumentSnapshot<Map<String, dynamic>>>(
    future: cookId.isEmpty
        ? null
        : FirebaseFirestore.instance
            .collection('users')
            .doc(cookId)
            .get(),
    builder: (context, cookSnapshot) {
      String displayCookName = cookName;

      if (cookSnapshot.hasData) {
        final cookData =
            cookSnapshot.data?.data();

        displayCookName =
            cookData?['businessName']
                    ?.toString() ??
                cookData?['fullName']
                    ?.toString() ??
                cookData?['displayName']
                    ?.toString() ??
                cookData?['name']
                    ?.toString() ??
                cookName;
      }

      return Text(
        displayCookName,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    },
  ),
),
                      if (isVerified) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color:
                              AppColors.secondary,
                        ),
                      ],
                    ],
                  ),
                  if (rating > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: AppColors.rating,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reviewCount > 0
                              ? '${rating.toStringAsFixed(1)} '
                                  '($reviewCount)'
                              : rating.toStringAsFixed(
                                  1,
                                ),
                          style: const TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '$portions portions available',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
  'Ready from $readyTime',
  style: const TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
  ),
),
const SizedBox(height: 5),
Text(
  'Orders close $cutOffTime',
  style: const TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
  ),
),
const SizedBox(height: 5),
Text(
  fulfilmentText,
                    style: const TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text(
                        'View meal details',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Widget _buildUpcomingMeals() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeading(
        title: 'Upcoming Meals',
        subtitle: 'See what local cooks are preparing next',
      ),
      const SizedBox(height: AppSpacing.regular),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('meals')
            .where('active', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildMessageCard(
              icon: Icons.error_outline_rounded,
              title: 'Upcoming meals could not be loaded',
              message: snapshot.error.toString(),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(
                  AppSpacing.large,
                ),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final now = DateTime.now();

          final today = DateTime(
            now.year,
            now.month,
            now.day,
          );

          final endOfWindow = today.add(
            const Duration(days: 7),
          );

          final meals =
              snapshot.data?.docs.where((document) {
                    final data = document.data();

                    final mealDateValue =
                        data['mealDate'];

                    if (mealDateValue is! Timestamp) {
                      return false;
                    }

                    final mealDate =
                        mealDateValue.toDate();

                    final normalizedMealDate =
                        DateTime(
                      mealDate.year,
                      mealDate.month,
                      mealDate.day,
                    );

                    final isFuture =
                        normalizedMealDate
                            .isAfter(today) &&
                        normalizedMealDate
                            .isBefore(endOfWindow);

                    final remainingValue =
                        data['remainingPortions'] ??
                            data['portions'];

                    final remainingPortions =
                        remainingValue is num
                            ? remainingValue.toInt()
                            : int.tryParse(
                                  remainingValue
                                          ?.toString() ??
                                      '',
                                ) ??
                                0;

                    final deliveryAvailable =
                        data['deliveryAvailable'] ==
                            true;

                    final collectionAvailable =
                        data['collectionAvailable'] ==
                            true;

                    final matchesSelectedOrderType =
                        _isDeliverySelected
                            ? deliveryAvailable
                            : collectionAvailable;

                    final mealCuisine =
                        data['cuisine']
                            ?.toString()
                            .trim();

                    final matchesSelectedCuisine =
                        _selectedCuisine == null ||
                            mealCuisine ==
                                _selectedCuisine;

                    return isFuture &&
                        remainingPortions > 0 &&
                        matchesSelectedOrderType &&
                        matchesSelectedCuisine;
                  }).toList() ??
                  [];

          meals.sort((first, second) {
            final firstMealDate =
                first.data()['mealDate']
                    as Timestamp?;

            final secondMealDate =
                second.data()['mealDate']
                    as Timestamp?;

            if (firstMealDate == null &&
                secondMealDate == null) {
              return 0;
            }

            if (firstMealDate == null) {
              return 1;
            }

            if (secondMealDate == null) {
              return -1;
            }

            return firstMealDate.compareTo(
              secondMealDate,
            );
          });

          if (meals.isEmpty) {
            return _buildMessageCard(
              icon: Icons.calendar_month_rounded,
              title: 'No upcoming meals',
              message:
                  'Future meals from local cooks will appear here.',
            );
          }

          return Column(
            children: [
              for (
                var index = 0;
                index < meals.length;
                index++
              ) ...[
                _buildMealCard(
                  mealId: meals[index].id,
                  data: meals[index].data(),
                  showMealDate: true,
                ),
                if (index < meals.length - 1)
                  const SizedBox(
                    height:
                        AppSpacing.regular,
                  ),
              ],
            ],
          );
        },
      ),
    ],
  );
}
  Widget _buildCuisineSection() {
  const cuisines = [
    ('🍽️', 'All'),
    ('🍛', 'Pakistani'),
    ('🍲', 'Indian'),
    ('🌴', 'Caribbean'),
    ('🌍', 'African'),
    ('🍝', 'Italian'),
    ('🥙', 'Middle Eastern'),
    ('🫒', 'Mediterranean'),
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeading(
        title: 'Browse by Cuisine',
        subtitle: 'Discover authentic flavours near you',
      ),
      const SizedBox(height: AppSpacing.medium),
      Wrap(
        spacing: 9,
        runSpacing: 10,
        children: cuisines.map((cuisine) {
          final isSelected =
              cuisine.$2 == 'All'
                  ? _selectedCuisine == null
                  : _selectedCuisine == cuisine.$2;

          return ChoiceChip(
            avatar: Text(cuisine.$1),
            label: Text(cuisine.$2),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (cuisine.$2 == 'All') {
                  _selectedCuisine = null;
                } else {
                  _selectedCuisine = cuisine.$2;
                }
              });
            },
          );
        }).toList(),
      ),
    ],
  );
}
  Widget _buildCookSpotlight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          title: 'Cook Spotlight',
          subtitle: 'Meet trusted local HomeEats cooks',
        ),
        const SizedBox(height: AppSpacing.regular),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.regular),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: AppColors.primaryLight,
                child: Icon(
                  Icons.person_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: AppSpacing.regular),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local HomeEats cooks',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Fresh homemade food prepared near you',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}