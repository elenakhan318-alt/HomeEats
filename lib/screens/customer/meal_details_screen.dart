import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'basket_screen.dart';
import 'favourites_data.dart';
import 'basket_data.dart';
import 'cook_profile_screen.dart';

class MealDetailsScreen extends StatefulWidget {
  final String mealId;
   final String cookId;
  final String mealName;
  final String cookName;
  final String price;
  final double rating;
  final int portionsLeft;
  final int reviewCount;
  final String deliveryText;
  final String emoji;
  final String? imageUrl;
  final String description;
  final List<String> ingredients;
  final List<String> allergens;
  final bool canOrderNow;
final String readyTime;
final String cutOffTime;

const MealDetailsScreen({
  super.key,
this.mealId = '',
this.cookId = '',
this.portionsLeft = 0,
  required this.mealName,
  required this.cookName,
  required this.price,
  required this.rating,
  required this.reviewCount,
  required this.deliveryText,
  required this.emoji,
  this.imageUrl,
  required this.description,
  required this.ingredients,
  required this.allergens,
  required this.canOrderNow,
required this.readyTime,
required this.cutOffTime,
});
  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  int quantity = 1;
  bool isFavourite = false;
  bool? _firestoreCanOrderNow;
  bool _checkingOrderWindow = true;
  String _orderStatusText = 'Ordering unavailable';

@override
void initState() {
  super.initState();

  isFavourite =
      favouritesData.isMealFavourite(widget.mealId);

  _checkCurrentOrderWindow();
}
Future<void> _checkCurrentOrderWindow() async {
  try {
    final mealDocument = await FirebaseFirestore.instance
        .collection('meals')
        .doc(widget.mealId)
        .get();

    final data = mealDocument.data();

   if (data == null) {
  if (!mounted) {
    return;
  }

  setState(() {
    _firestoreCanOrderNow = false;
    _checkingOrderWindow = false;
    _orderStatusText = 'Ordering unavailable';
  });

  return;
}

final now = DateTime.now();
    final orderOpenValue = data['orderOpenAt'];
    final orderCloseValue = data['orderCloseAt'];
    final mealDateValue = data['mealDate'];

    final orderOpenAt = orderOpenValue is Timestamp
        ? orderOpenValue.toDate()
        : null;

    final orderCloseAt = orderCloseValue is Timestamp
        ? orderCloseValue.toDate()
        : null;

    final mealDate = mealDateValue is Timestamp
        ? mealDateValue.toDate()
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

    final canOrder =
        !isFutureMeal &&
        !isBeforeOrdering &&
        !isAfterOrdering;

    if (!mounted) {
      return;
    }

    setState(() {
  _firestoreCanOrderNow = canOrder;
  _checkingOrderWindow = false;

  if (canOrder) {
    _orderStatusText = 'Add to Basket';
  } else if (isFutureMeal || isBeforeOrdering) {
    _orderStatusText = 'Ordering not open yet';
  } else if (isAfterOrdering) {
    _orderStatusText = 'Ordering closed';
  } else {
    _orderStatusText = 'Ordering unavailable';
  }
});
  } catch (error) {
  debugPrint(
    'ORDER WINDOW ERROR: $error',
  );

  if (!mounted) {
    return;
  }

  setState(() {
    _firestoreCanOrderNow = false;
    _checkingOrderWindow = false;
    _orderStatusText = 'Ordering unavailable';
  });
}
}
  double get mealPrice {
  return double.tryParse(
        widget.price.replaceAll('£', '').trim(),
      ) ??
      0;
}
double get totalPrice => mealPrice * quantity;
bool get deliveryAvailable {
  final String fulfilment =
      widget.deliveryText.toLowerCase().trim();

  return fulfilment.contains('delivery');
}

bool get collectionAvailable {
  final String fulfilment =
      widget.deliveryText.toLowerCase().trim();

  return fulfilment.contains('collection') ||
      fulfilment.contains('collect');
}

  void increaseQuantity() {
  if (quantity >= widget.portionsLeft) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Only ${widget.portionsLeft} portions are available.',
          ),
        ),
      );

    return;
  }

  setState(() {
    quantity++;
  });
}

  void decreaseQuantity() {
    if (quantity <= 1) {
      return;
    }

    setState(() {
      quantity--;
    });
  }

Future<void> toggleFavourite() async {
  try {
    await favouritesData.toggleMealFavourite(
  mealId: widget.mealId,
  cookId: widget.cookId,
  name: widget.mealName,
  cook: widget.cookName,
  price: widget.price,
  emoji: widget.emoji,
  imageUrl: widget.imageUrl,
  rating: widget.rating,
  reviewCount: widget.reviewCount,
  delivery: widget.deliveryText,
  portionsLeft: widget.portionsLeft,
  description: widget.description,
  ingredients: widget.ingredients,
  allergens: widget.allergens,
);
    if (!mounted) {
      return;
    }

    setState(() {
      isFavourite = favouritesData.isMealFavourite(
        widget.mealId,
      );
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isFavourite
                ? '${widget.mealName} added to favourites'
                : '${widget.mealName} removed from favourites',
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
            'Favourite could not be updated: $error',
          ),
        ),
      );
  }
}
void addToBasket() {
  basketData.addItem(
    mealId: widget.mealId,
    cookId: widget.cookId,
    name: widget.mealName,
    cook: widget.cookName,
    price: widget.price,
    emoji: widget.emoji,
    deliveryAvailable: deliveryAvailable,
    collectionAvailable: collectionAvailable,
    portionsLeft: widget.portionsLeft,
    imageUrl: widget.imageUrl,
    quantity: quantity,
  );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          '$quantity × ${widget.mealName} added to your basket',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}
void openBasket() {
  addToBasket();

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const BasketScreen(),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.large,
                AppSpacing.page,
                130,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMealHeading(),
                  const SizedBox(height: AppSpacing.regular),
                  _buildRatingAndDelivery(),
                  const SizedBox(height: AppSpacing.large),
                  _buildCookInformation(),
                  const SizedBox(height: AppSpacing.section),
                  _buildInformationSection(
                    title: 'About this meal',
                    child: Text(
                      widget.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _buildInformationSection(
                    title: 'Ingredients',
                    child: _buildIngredientList(),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _buildInformationSection(
                    title: 'Allergens',
                    child: _buildAllergenList(),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _buildDeliveryInformation(),
                  const SizedBox(height: AppSpacing.section),
                  _buildQuantitySelector(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBasketBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 330,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.95),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: Colors.white.withValues(alpha: 0.95),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: toggleFavourite,
              icon: Icon(
                isFavourite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavourite
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildLargeMealImage(),
      ),
    );
  }

  Widget _buildLargeMealImage() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildImagePlaceholder();
    }

    return Image.network(
      widget.imageUrl!,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: AppColors.primaryLight,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            color: AppColors.primary,
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF5D4BC),
            Color(0xFFEFA46F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: widget.imageUrl != null &&
        widget.imageUrl!.trim().isNotEmpty
    ? ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: Image.network(
          widget.imageUrl!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 120),
              ),
            );
          },
        ),
      )
    : Text(
        widget.emoji,
        style: const TextStyle(fontSize: 120),
      ),
    );
  }

  Widget _buildMealHeading() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.mealName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.regular),
        Text(
          widget.price,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingAndDelivery() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: [
          _buildInformationPill(
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
            text: widget.reviewCount == 0
                ? 'No reviews yet'
                : '${widget.rating.toStringAsFixed(1)} '
                    '(${widget.reviewCount} reviews)',
          ),
          _buildInformationPill(
            icon: Icons.delivery_dining_rounded,
            iconColor: AppColors.secondaryDark,
            text: widget.deliveryText,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.regular),
      Text(
      widget.portionsLeft <= 5
    ? 'Only ${widget.portionsLeft} portions left'
    : '${widget.portionsLeft} portions available',
        style: TextStyle(
          color: widget.portionsLeft <= 5
              ? Colors.red
              : AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
  Widget _buildInformationPill({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.surfaceSoft,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookInformation() {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CookProfileScreen(
              cookId: widget.cookId,
            ),
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
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.regular),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prepared by',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.cookName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppColors.secondaryDark,
                        size: 17,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Verified local cook',
                        style: TextStyle(
                          color: AppColors.secondaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildInformationSection({
    required String title,
    required Widget child,
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
        const SizedBox(height: AppSpacing.regular),
        child,
      ],
    );
  }

  Widget _buildIngredientList() {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: widget.ingredients.map((ingredient) {
        return Chip(
          avatar: const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: AppColors.secondaryDark,
          ),
          label: Text(ingredient),
          backgroundColor: Colors.white,
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  Widget _buildAllergenList() {
    if (widget.allergens.isEmpty) {
      return const Text(
        'No allergens have been listed for this meal.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: widget.allergens.map((allergen) {
        return Chip(
          avatar: const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          label: Text(allergen),
          backgroundColor: AppColors.primaryLight,
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.regular),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.delivery_dining_rounded,
            color: AppColors.secondaryDark,
            size: 30,
          ),
          const SizedBox(width: AppSpacing.regular),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated delivery',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.deliveryText,
                  style: const TextStyle(
                    color: AppColors.secondaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Quantity',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: decreaseQuantity,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: increaseQuantity,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBasketBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          12,
          AppSpacing.page,
          12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          child: FilledButton(
          onPressed: !_checkingOrderWindow &&
        (_firestoreCanOrderNow ?? false)
    ? openBasket
    : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket_rounded),
                const SizedBox(width: AppSpacing.small),
   Text(
  (_firestoreCanOrderNow ?? false)
      ? 'Add to Basket'
      : _orderStatusText,
),
if (_firestoreCanOrderNow ?? false) ...[
  const SizedBox(width: AppSpacing.small),
  Text(
    '• £${totalPrice.toStringAsFixed(2)}',
    style: const TextStyle(
      fontWeight: FontWeight.w900,
    ),
  ),
  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}