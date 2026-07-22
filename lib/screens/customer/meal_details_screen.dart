import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'basket_screen.dart';
import 'favourites_data.dart';
import 'basket_data.dart';

class MealDetailsScreen extends StatefulWidget {
  final String mealId;
   final String cookId;
  final String mealName;
  final String cookName;
  final String price;
  final double rating;
  final int reviewCount;
  final String deliveryText;
  final String emoji;
  final String? imageUrl;
  final String description;
  final List<String> ingredients;
  final List<String> allergens;

  const MealDetailsScreen({
    super.key,
    this.mealId = '',
    this.cookId = '',
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
  });

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  int quantity = 1;
  bool isFavourite = false;

  @override
  void initState() {
    super.initState();

    isFavourite = favouritesData.isFavourite(widget.mealName);
  }

  double get mealPrice {
    return double.tryParse(
          widget.price.replaceAll('£', '').trim(),
        ) ??
        0;
  }

  double get totalPrice => mealPrice * quantity;

  void increaseQuantity() {
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

  void toggleFavourite() {
    favouritesData.toggleFavourite({
      'name': widget.mealName,
      'cook': widget.cookName,
      'price': widget.price,
      'rating': widget.rating,
      'reviews': widget.reviewCount,
      'delivery': widget.deliveryText,
      'emoji': widget.emoji,
      'imageUrl': widget.imageUrl,
      'description': widget.description,
      'ingredients': widget.ingredients,
      'allergens': widget.allergens,
    });

    setState(() {
      isFavourite = favouritesData.isFavourite(widget.mealName);
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
  }
void addToBasket() {
  basketData.addItem(
  mealId: widget.mealId,
  cookId: widget.cookId,
  name: widget.mealName,
  cook: widget.cookName,
  price: widget.price,
  emoji: widget.emoji,
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
      child: Text(
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
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: [
        _buildInformationPill(
          icon: Icons.star_rounded,
          iconColor: AppColors.rating,
          text:
              '${widget.rating.toStringAsFixed(1)} (${widget.reviewCount} reviews)',
        ),
        _buildInformationPill(
          icon: Icons.delivery_dining_rounded,
          iconColor: AppColors.secondaryDark,
          text: widget.deliveryText,
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
    return Container(
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
            onPressed: openBasket,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket_rounded),
                const SizedBox(width: AppSpacing.small),
                const Text('Add to Basket'),
                const SizedBox(width: AppSpacing.small),
                Text(
                  '• £${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}