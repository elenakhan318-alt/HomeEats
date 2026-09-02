import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'add_today_meal_screen.dart';
import 'cook_orders_screen.dart';
import 'cook_reviews_screen.dart';
import 'cook_earnings_screen.dart';
import 'edit_today_meal_screen.dart';
import 'cook_order_history_screen.dart';
import 'contact_homeeats_screen.dart';
import 'cook_notifications_screen.dart';
import 'cook_hygiene_rating_screen.dart';

class CookDashboardScreen extends StatefulWidget {
  const CookDashboardScreen({super.key});

  @override
  State<CookDashboardScreen> createState() =>
      _CookDashboardScreenState();
}

class _CookDashboardScreenState
    extends State<CookDashboardScreen> {
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
      tooltip: 'Notifications',
      icon: const Icon(
        Icons.notifications_none_rounded,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const CookNotificationsScreen(),
          ),
        );
      },
    ),
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
        onPressed: () {
          Navigator.push(
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
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
  stream: user == null
      ? null
      : FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
  builder: (context, snapshot) {
    final data = snapshot.data?.data();

    final fullName =
        data?['fullName']?.toString().trim();

    final name =
        fullName != null && fullName.isNotEmpty
            ? fullName
            : 'Cook';

    return Text(
      'Good morning, $name',
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w900,
      ),
    );
  },
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
              Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.green.shade50,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(
      color: Colors.green.shade300,
    ),
  ),
  child: const Row(
    children: [
      Icon(
        Icons.verified_rounded,
        color: Colors.green,
        size: 32,
      ),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cook Verification Completed',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your account has been verified and approved.',
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
              const SizedBox(height: AppSpacing.large),
             _buildAvailabilityCard(),
const SizedBox(height: AppSpacing.large),
_buildHygieneRatingCard(context),
_buildRatingCard(context),
              const SizedBox(height: AppSpacing.large),
              _buildSummaryCards(context),
              const SizedBox(height: AppSpacing.large),
              _buildSectionTitle('Today’s Meals'),
const SizedBox(height: AppSpacing.regular),
_buildMealsSection(user),

const SizedBox(height: AppSpacing.large),

_buildSectionTitle('Upcoming Meals'),
const SizedBox(height: AppSpacing.regular),
_buildUpcomingMealsSection(user),

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

            const SizedBox(height: AppSpacing.large),

_buildSectionTitle('Previous Orders'),
const SizedBox(height: AppSpacing.regular),

InkWell(
  borderRadius: BorderRadius.circular(AppRadius.card),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CookOrderHistoryScreen(),
      ),
    );
  },
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.regular),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: const Row(
      children: [
        Icon(Icons.history_rounded),
        SizedBox(width: AppSpacing.regular),
        Expanded(
          child: Text(
            'View previous orders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(Icons.chevron_right_rounded),
      ],
    ),
  ),
), // InkWell
const SizedBox(height: AppSpacing.large),

_buildSectionTitle('Help & Support'),
const SizedBox(height: AppSpacing.regular),

InkWell(
  borderRadius: BorderRadius.circular(AppRadius.card),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ContactHomeEatsScreen(),
      ),
    );
  },
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.regular),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: const Row(
      children: [
        Icon(
          Icons.support_agent_rounded,
          color: AppColors.primary,
        ),
        SizedBox(width: AppSpacing.regular),
        Expanded(
          child: Text(
            'Contact HomeEats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(Icons.chevron_right_rounded),
      ],
    ),
  ),
),
], // Column children
          ), // Column
        ), // SingleChildScrollView
      ), // SafeArea
    ); // Scaffold
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

      final now = DateTime.now();

      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final meals = snapshot.data?.docs.where((meal) {
            final data = meal.data();

            final mealDateValue = data['mealDate'];

            if (mealDateValue is! Timestamp) {
              return false;
            }

            final mealDate = mealDateValue.toDate();

            final normalizedMealDate = DateTime(
              mealDate.year,
              mealDate.month,
              mealDate.day,
            );

            return normalizedMealDate == today;
          }).toList() ??
          [];

      meals.sort((first, second) {
        final firstReadyAt =
            first.data()['readyAt'] as Timestamp?;

        final secondReadyAt =
            second.data()['readyAt'] as Timestamp?;

        if (firstReadyAt == null && secondReadyAt == null) {
          return 0;
        }

        if (firstReadyAt == null) {
          return 1;
        }

        if (secondReadyAt == null) {
          return -1;
        }

        return firstReadyAt.compareTo(secondReadyAt);
      });

      if (meals.isEmpty) {
        return _buildMessageCard(
          icon: Icons.restaurant_menu_rounded,
          title: 'No meals published for today',
          message:
              'Future meals will appear in your upcoming menu.',
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
              const SizedBox(
                height: AppSpacing.regular,
              ),
          ],
        ],
      );
    },
  );
}
Widget _buildUpcomingMealsSection(User? user) {
  if (user == null) {
    return _buildMessageCard(
      icon: Icons.lock_outline_rounded,
      title: 'You are not signed in',
      message: 'Sign in again to view your upcoming meals.',
    );
  }

  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('meals')
        .where(
          'cookId',
          isEqualTo: user.uid,
        )
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
          snapshot.data?.docs.where((meal) {
                final data = meal.data();

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

                return normalizedMealDate
                        .isAfter(today) &&
                    normalizedMealDate
                        .isBefore(endOfWindow);
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
              'Meals you advertise for future days will appear here.',
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
                height: AppSpacing.regular,
              ),
          ],
        ],
      );
    },
  );
}
  Widget _buildAvailabilityCard() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const SizedBox.shrink();
  }

  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots(),
    builder: (context, snapshot) {
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

      final data = snapshot.data?.data();

      final isAvailable = data?['isAvailable'] == true;

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today’s availability',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAvailable
                        ? 'Open and accepting orders'
                        : 'Closed for today',
                    style: TextStyle(
                      color: isAvailable
                          ? Colors.green
                          : Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isAvailable,
              onChanged: (value) async {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'isAvailable': value,
                    'availabilityUpdatedAt':
                        FieldValue.serverTimestamp(),
                  });
                } catch (error) {
  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Availability could not be updated: $error',
      ),
    ),
  );
}
              },
            ),
          ],
        ),
      );
    },
  );
}
Widget _buildHygieneRatingCard(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const SizedBox.shrink();
  }

  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('cookApplications')
        .doc(user.uid)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox.shrink();
      }

      final data = snapshot.data?.data();

      final declarations =
          data?['declarations'] as Map<String, dynamic>? ??
              <String, dynamic>{};

      final documents =
          data?['documents'] as Map<String, dynamic>? ??
              <String, dynamic>{};

      final awaitingCouncilRating =
          declarations['awaitingCouncilRating'] == true;

      final ratingData =
          documents['foodHygieneRating'];

      String? fileName;

      if (ratingData is Map) {
        fileName = ratingData['fileName']?.toString();
      }

      final hasRating =
          fileName != null && fileName.trim().isNotEmpty;

      final reviewStatus =
          data?['foodHygieneRatingReviewStatus']
                  ?.toString() ??
              (hasRating
                  ? 'pending_review'
                  : 'not_submitted');

      String statusText;

      if (reviewStatus == 'approved') {
  statusText = 'Council rating approved';
} else if (reviewStatus == 'pending_review') {
  statusText = 'Rating waiting for HomeEats review';
} else if (reviewStatus == 'changes_requested' ||
    reviewStatus == 'rejected') {
  statusText = 'Replacement required by HomeEats';
} else if (awaitingCouncilRating) {
  statusText = 'Awaiting council inspection/rating';
} else {
  statusText = 'Council rating not uploaded';
}

      return InkWell(
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const CookHygieneRatingScreen(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            AppSpacing.large,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              AppRadius.card,
            ),
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
                  Icons.health_and_safety_rounded,
                  color: AppColors.primary,
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
                    const Text(
                      'Council Food Hygiene Rating',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
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
      );
    },
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

 Widget _buildSummaryCards(BuildContext context) {
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const SizedBox.shrink();
  }

  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('orders')
        .where(
          'cookIds',
          arrayContains: user.uid,
        )
        .snapshots(),
    builder: (context, snapshot) {
      int activeOrderCount = 0;
      double todayEarnings = 0;

      final DateTime now = DateTime.now();

      if (snapshot.hasData) {
        for (final document in snapshot.data!.docs) {
          final Map<String, dynamic> data = document.data();

          final String paymentStatus =
              data['paymentStatus']?.toString() ?? '';

          final String status =
              data['status']?.toString() ?? '';

          if (paymentStatus != 'paid') {
            continue;
          }

          if (status != 'completed' &&
              status != 'rejected') {
            activeOrderCount++;
          }

          if (status == 'completed') {
            final dynamic timestampValue =
                data['completedAt'] ??
                data['updatedAt'] ??
                data['createdAt'];

            if (timestampValue is Timestamp) {
              final DateTime completedDate =
                  timestampValue.toDate();

              final bool completedToday =
                  completedDate.year == now.year &&
                  completedDate.month == now.month &&
                  completedDate.day == now.day;

              if (completedToday) {
                final dynamic totalValue = data['total'];

                final double total = totalValue is num
                    ? totalValue.toDouble()
                    : double.tryParse(
                          totalValue?.toString() ?? '',
                        ) ??
                        0;

                todayEarnings += total;
              }
            }
          }
        }
      }

      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.receipt_long_rounded,
              title: 'Orders',
              value: activeOrderCount.toString(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const CookOrdersScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.regular),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.payments_outlined,
              title: 'Today',
              value: '£${todayEarnings.toStringAsFixed(2)}',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const CookEarningsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
Widget _buildSummaryCard({
  required IconData icon,
  required String title,
  required String value,
  VoidCallback? onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(AppRadius.card),
    onTap: onTap,
    child: Container(
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
  bool showMealDate = false,
}) {
  final mealName =
      data['mealName']?.toString() ?? 'Unnamed meal';

  final priceValue = data['price'];
  final price = priceValue is num
      ? priceValue.toDouble()
      : double.tryParse(
            priceValue?.toString() ?? '',
          ) ??
          0;

  final remainingValue =
      data['remainingPortions'] ?? data['portions'];

  final remainingPortions = remainingValue is num
      ? remainingValue.toInt()
      : int.tryParse(
            remainingValue?.toString() ?? '',
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

  final deliveryAvailable =
      data['deliveryAvailable'] == true;

  final collectionAvailable =
      data['collectionAvailable'] == true;

  final active = data['active'] != false;
  final imageUrl =
    data['imageUrl']?.toString().trim() ?? '';

  final fulfilmentOptions = <String>[];

  if (deliveryAvailable) {
    fulfilmentOptions.add('Delivery');
  }

  if (collectionAvailable) {
    fulfilmentOptions.add('Collection');
  }

  final fulfilmentText =
      fulfilmentOptions.isEmpty
          ? 'No fulfilment option'
          : fulfilmentOptions.join(' • ');

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(
      AppSpacing.regular,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(AppRadius.card),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            ClipRRect(
  borderRadius: BorderRadius.circular(
    AppRadius.medium,
  ),
  child: SizedBox(
    width: 82,
    height: 82,
    child: imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                color: AppColors.primaryLight,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              );
            },
          )
        : Container(
            color: AppColors.primaryLight,
            alignment: Alignment.center,
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.primary,
              size: 38,
            ),
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
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          mealName,
                          style:
                              const TextStyle(
                            color:
                                AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '£${price.toStringAsFixed(2)}',
                        style:
                            const TextStyle(
                          color:
                              AppColors.primary,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                if (showMealDate && mealDateText.isNotEmpty) ...[
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
                                      const SizedBox(height: 5),
                  Text('$remainingPortions portions left',
                    style:
                        const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
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
  'Orders close $cutOffTime',
  style: const TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
  ),
),
const SizedBox(height: 4),
Text(
  fulfilmentText,
                    style:
                        const TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.green
                              .withValues(
                                alpha: 0.12,
                              )
                          : Colors.grey
                              .withValues(
                                alpha: 0.15,
                              ),
                      borderRadius:
                          BorderRadius.circular(
                        50,
                      ),
                    ),
                    child: Text(
                      active
                          ? 'Available'
                          : 'Unavailable',
                      style: TextStyle(
                        color: active
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(
          height: AppSpacing.regular,
        ),
        const Divider(height: 1),
        const SizedBox(
          height: AppSpacing.small,
        ),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Edit meal',
              icon: const Icon(
                Icons.edit_outlined,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditTodayMealScreen(
                      mealId: mealId,
                      mealData: data,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip:
                  active
                      ? 'Hide meal'
                      : 'Show meal',
              icon: Icon(
                active
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('meals')
                      .doc(mealId)
                      .update({
                    'active': !active,
                    'updatedAt':
                        FieldValue.serverTimestamp(),
                  });

                 if (!mounted) {
  return;
}

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        active
                            ? '$mealName has been hidden.'
                            : '$mealName is now available.',
                      ),
                    ),
                  );
                } catch (error) {
                 if (!mounted) {
  return;
}

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Meal visibility could not be updated: $error',
                      ),
                    ),
                  );
                }
              },
            ),
            IconButton(
              tooltip: 'Delete meal',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
              onPressed: () async {
                final shouldDelete =
                    await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text(
                        'Delete meal?',
                      ),
                      content: Text(
                        'Are you sure you want to permanently delete $mealName?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              false,
                            );
                          },
                          child:
                              const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          },
                          style:
                              FilledButton.styleFrom(
                            backgroundColor:
                                Colors.red,
                          ),
                          child:
                              const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );

                if (shouldDelete != true) {
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('meals')
                      .doc(mealId)
                      .delete();

                 if (!mounted) {
  return;
}

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        '$mealName has been deleted.',
                      ),
                    ),
                  );
                } catch (error) {
                if (!mounted) {
  return;
}

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'The meal could not be deleted: $error',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
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