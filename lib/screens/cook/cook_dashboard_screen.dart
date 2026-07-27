import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'add_today_meal_screen.dart';
import 'cook_orders_screen.dart';
import 'cook_reviews_screen.dart';

class CookDashboardScreen extends StatelessWidget {
  const CookDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cook Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTodayMealScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Today’s Meal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.regular,
            AppSpacing.page,
            110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning, Fozia',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage today’s meals, portions and orders.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              _buildAvailabilityCard(),
              const SizedBox(height: AppSpacing.large),
              _buildRatingCard(context),
              const SizedBox(height: AppSpacing.large),
              _buildSummaryCards(),
              const SizedBox(height: AppSpacing.large),
              _buildSectionTitle('Today’s Meals'),
              const SizedBox(height: AppSpacing.regular),
              _buildMealsSection(user),
              const SizedBox(height: AppSpacing.large),
              _buildSectionTitle('Incoming Orders'),
              const SizedBox(height: AppSpacing.regular),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CookOrdersScreen(),
                    ),
                  );
                },
                child: _buildOrderCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealsSection(User? user) {
    if (user == null) {
      return _buildMessageCard(
        icon: Icons.lock_outline_rounded,
        title: 'You are not signed in',
        message: 'Sign in again to view your published meals.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('meals')
          .where('cookId', isEqualTo: user.uid)
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

        final meals = snapshot.data?.docs ?? [];

        meals.sort((first, second) {
          final firstCreatedAt =
              first.data()['createdAt'] as Timestamp?;
          final secondCreatedAt =
              second.data()['createdAt'] as Timestamp?;

          if (firstCreatedAt == null && secondCreatedAt == null) {
            return 0;
          }

          if (firstCreatedAt == null) {
            return 1;
          }

          if (secondCreatedAt == null) {
            return -1;
          }

          return secondCreatedAt.compareTo(firstCreatedAt);
        });

        if (meals.isEmpty) {
          return _buildMessageCard(
            icon: Icons.restaurant_menu_rounded,
            title: 'No meals published yet',
            message: 'Tap Add Today’s Meal to publish your first meal.',
          );
        }

        return Column(
          children: [
            for (var index = 0; index < meals.length; index++) ...[
              _buildMealCard(
                mealId: meals[index].id,
                data: meals[index].data(),
              ),
              if (index < meals.length - 1)
                const SizedBox(height: AppSpacing.regular),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.regular),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today’s availability',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Open and accepting orders',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Switch(
            value: true,
            onChanged: null,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ratings')
          .where('cookId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMessageCard(
            icon: Icons.error_outline_rounded,
            title: 'Ratings could not be loaded',
            message: snapshot.error.toString(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final ratings = snapshot.data?.docs ?? [];

        double average = 0;

        if (ratings.isNotEmpty) {
          for (final document in ratings) {
            final value = document.data()['rating'];

            if (value is num) {
              average += value.toDouble();
            }
          }

          average /= ratings.length;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CookReviewsScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 42,
                  ),
                  const SizedBox(width: AppSpacing.regular),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ratings.isEmpty
                              ? 'No ratings yet'
                              : average.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ratings.length} review${ratings.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.receipt_long_rounded,
            title: 'Orders',
            value: '0',
          ),
        ),
        const SizedBox(width: AppSpacing.regular),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.payments_outlined,
            title: 'Earnings',
            value: '£0.00',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 30,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildMealCard({
    required String mealId,
    required Map<String, dynamic> data,
  }) {
    final mealName = data['mealName']?.toString() ?? 'Unnamed meal';

    final priceValue = data['price'];
    final price = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(priceValue?.toString() ?? '') ?? 0;

    final remainingValue =
        data['remainingPortions'] ?? data['portions'];

    final remainingPortions = remainingValue is num
        ? remainingValue.toInt()
        : int.tryParse(remainingValue?.toString() ?? '') ?? 0;

    final readyTime =
        data['readyTimeLabel']?.toString() ?? 'Time not set';

    final deliveryAvailable =
        data['deliveryAvailable'] == true;

    final collectionAvailable =
        data['collectionAvailable'] == true;

    final active = data['active'] != false;

    final fulfilmentOptions = <String>[];

    if (deliveryAvailable) {
      fulfilmentOptions.add('Delivery');
    }

    if (collectionAvailable) {
      fulfilmentOptions.add('Collection');
    }

    final fulfilmentText = fulfilmentOptions.isEmpty
        ? 'No fulfilment option'
        : fulfilmentOptions.join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.regular),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 82,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(width: AppSpacing.regular),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        mealName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
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
                const SizedBox(height: 5),
                Text(
                  '$remainingPortions portions left',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready from $readyTime',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fulfilmentText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    active ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: active ? Colors.green : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildOrderCard() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('cookIds', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.regular),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.regular),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Text('Unable to load orders.'),
          );
        }

        final orders = snapshot.data?.docs ?? [];

        orders.sort((first, second) {
          final firstTime =
              first.data()['createdAt'] as Timestamp?;
          final secondTime =
              second.data()['createdAt'] as Timestamp?;

          if (firstTime == null && secondTime == null) {
            return 0;
          }

          if (firstTime == null) {
            return 1;
          }

          if (secondTime == null) {
            return -1;
          }

          return secondTime.compareTo(firstTime);
        });

        final activeOrders = orders.where((document) {
          final status =
              document.data()['status']?.toString().toLowerCase() ?? '';

          return status == 'pending' ||
              status == 'accepted' ||
              status == 'preparing' ||
              status == 'ready';
        }).toList();

        if (activeOrders.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.regular),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.regular),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No incoming orders yet',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'New customer orders will appear here.',
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
          );
        }

        return Column(
          children: activeOrders.map((document) {
            final order = document.data();

            final customerName =
                order['customerName']?.toString() ?? 'Customer';

            final status =
                order['status']?.toString() ?? 'Pending';

            final total =
                (order['total'] as num?)?.toDouble() ?? 0;

            final items = order['items'] as List? ?? [];

            final mealText = items
                .map((item) {
                  if (item is! Map) {
                    return '';
                  }

                  final quantity = item['quantity'] ?? 1;
                  final name = item['name'] ?? 'Item';

                  return '$quantity × $name';
                })
                .where((text) => text.isNotEmpty)
                .join(', ');

            return Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.regular,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.regular),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.regular),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mealText,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '£${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}