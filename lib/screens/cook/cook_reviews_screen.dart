import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class CookReviewsScreen extends StatelessWidget {
  const CookReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(
              child: Text('You are not signed in.'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('ratings')
                  .where('cookId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.page),
                      child: Text(
                        'Reviews could not be loaded.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final reviews = snapshot.data?.docs ?? [];

                reviews.sort((first, second) {
                  final firstDate =
                      first.data()['createdAt'] as Timestamp?;
                  final secondDate =
                      second.data()['createdAt'] as Timestamp?;

                  if (firstDate == null && secondDate == null) {
                    return 0;
                  }

                  if (firstDate == null) {
                    return 1;
                  }

                  if (secondDate == null) {
                    return -1;
                  }

                  return secondDate.compareTo(firstDate);
                });

                if (reviews.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.page),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_border_rounded,
                            color: AppColors.primary,
                            size: 58,
                          ),
                          SizedBox(height: AppSpacing.regular),
                          Text(
                            'No reviews yet',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Customer reviews will appear here after completed orders.',
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

                double total = 0;

                for (final review in reviews) {
                  final value = review.data()['rating'];

                  if (value is num) {
                    total += value.toDouble();
                  }
                }

                final average = total / reviews.length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.regular,
                    AppSpacing.page,
                    AppSpacing.large,
                  ),
                  children: [
                    _buildSummaryCard(
                      average: average,
                      reviewCount: reviews.length,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    const Text(
                      'All reviews',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.regular),
                    for (var index = 0;
                        index < reviews.length;
                        index++) ...[
                      _buildReviewCard(reviews[index].data()),
                      if (index < reviews.length - 1)
                        const SizedBox(height: AppSpacing.regular),
                    ],
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryCard({
    required double average,
    required int reviewCount,
  }) {
    return Container(
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
            size: 52,
          ),
          const SizedBox(width: AppSpacing.regular),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$reviewCount review${reviewCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> data) {
    final ratingValue = data['rating'];

    final rating = ratingValue is num
        ? ratingValue.toInt()
        : int.tryParse(ratingValue?.toString() ?? '') ?? 0;

    final review = data['review']?.toString().trim() ?? '';
    final customerName =
    (data['customerName']?.toString().trim().isNotEmpty ?? false)
        ? data['customerName'].toString().trim()
        : 'Customer';
    final createdAt = data['createdAt'] as Timestamp?;

    final dateText = createdAt == null
        ? 'Date unavailable'
        : _formatDate(createdAt.toDate());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var index = 1; index <= 5; index++)
                Icon(
                  index <= rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
              const Spacer(),
              Text(
                dateText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.regular),
          Text(
            review.isEmpty ? 'No written review.' : review,
            style: TextStyle(
              color: review.isEmpty
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              fontSize: 15,
              height: 1.4,
              fontStyle:
                  review.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
  customerName,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}