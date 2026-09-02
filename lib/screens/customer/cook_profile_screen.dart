import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'meal_details_screen.dart';
import 'favourites_data.dart';

class CookProfileScreen extends StatelessWidget {
  const CookProfileScreen({
    super.key,
    required this.cookId,
  });

  final String cookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
  title: const Text('Cook Profile'),
  centerTitle: true,
  actions: [
    AnimatedBuilder(
      animation: favouritesData,
      builder: (context, _) {
        final isFavourite =
            favouritesData.isCookFavourite(cookId);

        return IconButton(
          tooltip: isFavourite
              ? 'Remove favourite cook'
              : 'Favourite cook',
          icon: Icon(
            isFavourite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isFavourite
                ? Colors.red
                : AppColors.primary,
          ),
          onPressed: () async {
            try {
              final cookSnapshot =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(cookId)
                      .get();

              final cookData =
                  cookSnapshot.data() ??
                      <String, dynamic>{};

              final businessName =
                  cookData['businessName']
                      ?.toString()
                      .trim();

              final fullName =
                  cookData['fullName']
                      ?.toString()
                      .trim();

              final cookName =
                  businessName != null &&
                          businessName.isNotEmpty
                      ? businessName
                      : fullName != null &&
                              fullName.isNotEmpty
                          ? fullName
                          : 'HomeEats Cook';

              final profileImageUrl =
                  cookData['profileImageUrl']
                      ?.toString();

              await favouritesData.toggleCookFavourite(
                cookId: cookId,
                cookName: cookName,
                profileImageUrl: profileImageUrl,
              );
            } catch (error) {
              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      'Favourite could not be updated: $error',
                    ),
                  ),
                );
            }
          },
        );
      },
    ),
  ],
),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(cookId)
            .snapshots(),
        builder: (context, cookSnapshot) {
          if (cookSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(
                  AppSpacing.page,
                ),
                child: Text(
                  'Cook profile could not be loaded.\n'
                  '${cookSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (cookSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final cookDocument = cookSnapshot.data;

          if (cookDocument == null ||
              !cookDocument.exists) {
            return const Center(
              child: Text('Cook profile not found.'),
            );
          }

          final cookData =
              cookDocument.data() ??
                  <String, dynamic>{};

          final businessName =
              cookData['businessName']
                  ?.toString()
                  .trim();

          final fullName =
              cookData['fullName']
                  ?.toString()
                  .trim();

          final cookName =
              businessName != null &&
                      businessName.isNotEmpty
                  ? businessName
                  : fullName != null &&
                          fullName.isNotEmpty
                      ? fullName
                      : 'HomeEats Cook';

          final bio =
              cookData['bio']
                  ?.toString()
                  .trim();

          final locationValue =
              cookData['location']
                  ?.toString()
                  .trim();

          final addressValue =
              cookData['address']
                  ?.toString()
                  .trim();

          final location =
              locationValue != null &&
                      locationValue.isNotEmpty
                  ? locationValue
                  : addressValue != null &&
                          addressValue.isNotEmpty
                      ? addressValue
                      : 'Birmingham';

          final verificationStatus =
              cookData['verificationStatus']
                      ?.toString() ??
                  '';

          final isVerified =
              verificationStatus.toLowerCase() ==
                  'approved';

          final hygieneValue =
              cookData['hygieneRating']
                  ?.toString()
                  .trim();

          final hygieneRating =
              hygieneValue != null &&
                      hygieneValue.isNotEmpty
                  ? hygieneValue
                  : 'Not yet added';

          final ratingValue =
              cookData['averageRating'];

          final averageRating =
              ratingValue is num
                  ? ratingValue.toDouble()
                  : double.tryParse(
                        ratingValue
                                ?.toString() ??
                            '',
                      ) ??
                      0;

          final reviewCountValue =
              cookData['reviewCount'];

          final reviewCount =
              reviewCountValue is num
                  ? reviewCountValue.toInt()
                  : int.tryParse(
                        reviewCountValue
                                ?.toString() ??
                            '',
                      ) ??
                      0;

          final profileImageUrl =
              cookData['profileImageUrl']
                      ?.toString() ??
                  '';

          return ListView(
            padding: const EdgeInsets.all(
              AppSpacing.page,
            ),
            children: [
              _buildProfileHeader(
                cookName: cookName,
                profileImageUrl:
                    profileImageUrl,
                isVerified: isVerified,
                averageRating:
                    averageRating,
                reviewCount: reviewCount,
              ),

              const SizedBox(
                height: AppSpacing.regular,
              ),

              _buildInfoCard(
                icon:
                    Icons.location_on_outlined,
                title: 'Location',
                value: location,
              ),

              const SizedBox(
                height: AppSpacing.regular,
              ),

              _buildInfoCard(
                icon: Icons
                    .health_and_safety_outlined,
                title: 'Food hygiene rating',
                value: hygieneRating,
              ),

              const SizedBox(
                height: AppSpacing.regular,
              ),

              _buildAboutCard(
                bio: bio != null &&
                        bio.isNotEmpty
                    ? bio
                    : 'This verified local cook has not added a bio yet.',
              ),

              const SizedBox(
                height: AppSpacing.regular,
              ),

              _buildMealsSection(
                context: context,
                cookName: cookName,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader({
    required String cookName,
    required String profileImageUrl,
    required bool isVerified,
    required double averageRating,
    required int reviewCount,
  }) {
    return Container(
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
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
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
                    size: 50,
                    color: AppColors.primary,
                  )
                : null,
          ),

          const SizedBox(
            height: AppSpacing.regular,
          ),

          Text(
            cookName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),

          if (isVerified) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFE4F4E7),
                borderRadius:
                    BorderRadius.circular(
                  AppRadius.pill,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 17,
                    color: Colors.green,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Verified local cook',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(
            height: AppSpacing.regular,
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 22,
              ),
              const SizedBox(width: 5),
              Text(
                averageRating > 0
                    ? averageRating
                        .toStringAsFixed(1)
                    : 'No ratings yet',
                style: const TextStyle(
                  color:
                      AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              if (reviewCount > 0) ...[
                const SizedBox(width: 5),
                Text(
                  '($reviewCount reviews)',
                  style: const TextStyle(
                    color: AppColors
                        .textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard({
    required String bio,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: AppSpacing.regular,
          ),
          Text(
            bio,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsSection({
    required BuildContext context,
    required String cookName,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Meals from $cookName',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: AppSpacing.regular,
          ),

          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('meals')
                .where(
                  'cookId',
                  isEqualTo: cookId,
                )
                .where(
                  'active',
                  isEqualTo: true,
                )
                .snapshots(),
            builder: (context, mealSnapshot) {
              if (mealSnapshot.hasError) {
                return Text(
                  'Meals could not be loaded: '
                  '${mealSnapshot.error}',
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                );
              }

              if (mealSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final meals =
                  mealSnapshot.data?.docs
                          .where((document) {
                        final data =
                            document.data();

                        final remainingValue =
                            data[
                                    'remainingPortions'] ??
                                data['portions'];

                        final remaining =
                            remainingValue is num
                                ? remainingValue
                                    .toInt()
                                : int.tryParse(
                                      remainingValue
                                              ?.toString() ??
                                          '',
                                    ) ??
                                    0;

                        return remaining > 0;
                      }).toList() ??
                      [];

              meals.sort(
                (first, second) {
                  final firstTime =
                      first.data()['createdAt']
                          as Timestamp?;

                  final secondTime =
                      second.data()['createdAt']
                          as Timestamp?;

                  if (firstTime == null &&
                      secondTime == null) {
                    return 0;
                  }

                  if (firstTime == null) {
                    return 1;
                  }

                  if (secondTime == null) {
                    return -1;
                  }

                  return secondTime
                      .compareTo(firstTime);
                },
              );

              if (meals.isEmpty) {
                return const Text(
                  'This cook has no available meals at the moment.',
                  style: TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 14,
                  ),
                );
              }

              return Column(
                children: [
                  for (var index = 0;
                      index < meals.length;
                      index++) ...[
                    _buildMealCard(
                      context: context,
                      mealId:
                          meals[index].id,
                      cookName: cookName,
                      data:
                          meals[index].data(),
                    ),
                    if (index <
                        meals.length - 1)
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
      ),
    );
  }

  Widget _buildMealCard({
    required BuildContext context,
    required String mealId,
    required String cookName,
    required Map<String, dynamic> data,
  }) {
    final mealName =
        data['mealName']?.toString() ??
            'Unnamed meal';

    final priceValue = data['price'];

    final price = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(
              priceValue?.toString() ?? '',
            ) ??
            0;

    final portionsValue =
        data['remainingPortions'] ??
            data['portions'];

    final portions = portionsValue is num
        ? portionsValue.toInt()
        : int.tryParse(
              portionsValue?.toString() ??
                  '',
            ) ??
            0;

    final readyTime =
        data['readyTimeLabel']
                ?.toString() ??
            'Time not set';
            final cutOffTime =
    data['cutOffTimeLabel']
            ?.toString() ??
        'Time not set';    
final now = DateTime.now();

final mealDateValue = data['mealDate'];
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

    final ingredientsText =
        data['ingredients']
                ?.toString() ??
            '';

    final allergensText =
        data['allergens']
                ?.toString() ??
            'None';

    final ingredients =
        ingredientsText
            .split(',')
            .map((item) => item.trim())
            .where(
              (item) => item.isNotEmpty,
            )
            .toList();

    final allergens =
        allergensText
            .split(',')
            .map((item) => item.trim())
            .where(
              (item) => item.isNotEmpty,
            )
            .toList();

    final deliveryAvailable =
        data['deliveryAvailable'] == true;

    final collectionAvailable =
        data['collectionAvailable'] ==
            true;

    final fulfilmentOptions =
        <String>[];

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

    const placeholderImage =
        'https://images.unsplash.com/'
        'photo-1547592180-85f173990554'
        '?auto=format&fit=crop&w=1200&q=80';

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(
        AppRadius.medium,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          AppRadius.medium,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MealDetailsScreen(
                mealId: mealId,
                cookId: cookId,
                mealName: mealName,
                cookName: cookName,
                price:
                    '£${price.toStringAsFixed(2)}',
                rating: 0,
                reviewCount: 0,
                deliveryText:
                    '$fulfilmentText • Ready $readyTime',
                emoji: '🍽️',
                imageUrl:
                    placeholderImage,
                description:
                    'A freshly prepared homemade meal available through HomeEats.',
                ingredients:
                    ingredients.isEmpty
                        ? const [
                            'See cook for ingredients',
                          ]
                        : ingredients,
                allergens:
                    allergens.isEmpty
                        ? const [
                            'None listed',
                          ]
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
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color:
                      AppColors.primaryLight,
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.medium,
                  ),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primary,
                  size: 31,
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
                      style:
                          const TextStyle(
                        color: AppColors
                            .textPrimary,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$portions portions available',
                      style:
                          const TextStyle(
                        color:
                            AppColors.primary,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fulfilmentText,
                      style:
                          const TextStyle(
                        color: AppColors
                            .textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    '£${price.toStringAsFixed(2)}',
                    style:
                        const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 15,
                    color:
                        AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
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
                  title,
                  style: const TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color:
                        AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}