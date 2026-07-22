import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'meal_details_screen.dart';
import 'search_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  bool _isDeliverySelected = true;

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
          child: SingleChildScrollView(
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
                _buildPromotionBanner(),
                const SizedBox(height: AppSpacing.section),
                _buildLiveMeals(),
                const SizedBox(height: AppSpacing.section),
                _buildCuisineSection(),
                const SizedBox(height: AppSpacing.section),
                _buildCookSpotlight(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.small),
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
            onPressed: () {
              _showTemporaryMessage('You have no new notifications.');
            },
            icon: const Icon(Icons.notifications_none_rounded),
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

    String greeting;

    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 18) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.small),
        const Text(
          'What are you craving today?',
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
        prefixIcon: Icon(Icons.search_rounded),
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
                  'Authentic Home\nCooked Meals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                const Text(
                  'Freshly prepared by trusted local cooks.',
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
          subtitle: 'All meals currently available',
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

                  final remainingValue =
                      data['remainingPortions'] ?? data['portions'];

                  final remainingPortions = remainingValue is num
                      ? remainingValue.toInt()
                      : int.tryParse(
                            remainingValue?.toString() ?? '',
                          ) ??
                          0;

                  return remainingPortions > 0;
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
                message:
                    'There are currently no meals with portions remaining.',
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
}) {
  final mealName =
      data['mealName']?.toString() ?? 'Unnamed meal';

  final cookId =
      data['cookId']?.toString() ?? '';

  final priceValue = data['price'];

    final price = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(priceValue?.toString() ?? '') ?? 0;

    final portionsValue =
        data['remainingPortions'] ?? data['portions'];

    final portions = portionsValue is num
        ? portionsValue.toInt()
        : int.tryParse(portionsValue?.toString() ?? '') ?? 0;

    final readyTime =
        data['readyTimeLabel']?.toString() ?? 'Time not set';

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

    final fulfilmentText = fulfilmentOptions.isEmpty
        ? 'Fulfilment not specified'
        : fulfilmentOptions.join(' • ');

    const placeholderImage =
        'https://images.unsplash.com/photo-1547592180-85f173990554'
        '?auto=format&fit=crop&w=1200&q=80';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MealDetailsScreen(
                cookId: cookId,
                mealName: mealName,
                cookName: 'HomeEats Cook',
                price: '£${price.toStringAsFixed(2)}',
                rating: 5.0,
                reviewCount: 0,
                deliveryText:
                    '$fulfilmentText • Ready $readyTime',
                emoji: '🍽️',
                imageUrl: placeholderImage,
                description:
                    'A freshly prepared homemade meal available through HomeEats.',
                ingredients: ingredients.isEmpty
                    ? const ['See cook for ingredients']
                    : ingredients,
                allergens: allergens.isEmpty
                    ? const ['None listed']
                    : allergens,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.regular),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(
                    AppRadius.medium,
                  ),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),
              ),
              const SizedBox(width: AppSpacing.regular),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            mealName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '£${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$portions portions available',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                      fulfilmentText,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'View meal details',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
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

  Widget _buildCuisineSection() {
    const cuisines = [
      ('🍛', 'Pakistani'),
      ('🍲', 'Indian'),
      ('🌴', 'Caribbean'),
      ('🍗', 'Soul Food'),
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
            return ActionChip(
              avatar: Text(cuisine.$1),
              label: Text(cuisine.$2),
              onPressed: () {
                _showTemporaryMessage(
                  '${cuisine.$2} filtering is coming next.',
                );
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