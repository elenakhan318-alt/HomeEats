import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'basket_data.dart';
import 'checkout_screen.dart';
import 'customer_main_screen.dart';

class BasketScreen extends StatefulWidget {
  const BasketScreen({super.key});

  @override
  State<BasketScreen> createState() =>
      _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  static const double deliveryFee = 2.50;

  String _fulfilmentMethod = 'delivery';

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) =>
            const CustomerMainScreen(),
      ),
      (route) => false,
    );
  }

  bool get deliveryAvailable {
    if (basketData.basketItems.isEmpty) {
      return false;
    }

    return basketData.basketItems.every(
      (item) =>
          item['deliveryAvailable'] as bool? ??
          false,
    );
  }

  bool get collectionAvailable {
    if (basketData.basketItems.isEmpty) {
      return false;
    }

    return basketData.basketItems.every(
      (item) =>
          item['collectionAvailable'] as bool? ??
          false,
    );
  }

  bool get isCollectionOnly =>
      collectionAvailable && !deliveryAvailable;

  double get currentDeliveryFee =>
      _fulfilmentMethod == 'collection'
          ? 0
          : deliveryFee;

  double _priceToDouble(dynamic value) {
    final priceText = value
        .toString()
        .replaceAll('£', '')
        .trim();

    return double.tryParse(priceText) ?? 0;
  }

  double get subtotal {
    double amount = 0;

    for (final item in basketData.basketItems) {
      final price =
          _priceToDouble(item['price']);

      final quantity =
          item['quantity'] as int? ?? 1;

      amount += price * quantity;
    }

    return amount;
  }

  double get total =>
      subtotal + currentDeliveryFee;

  void _checkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          initialFulfilmentType:
              _fulfilmentMethod,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: basketData,
      builder: (context, child) {
        final basketIsEmpty =
            basketData.basketItems.isEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Your Basket'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Home',
                icon: const Icon(
                  Icons.home_outlined,
                ),
                onPressed: _goHome,
              ),
            ],
          ),
          body: basketIsEmpty
              ? _buildEmptyBasket()
              : _buildBasketContents(),
          bottomNavigationBar:
              basketIsEmpty
                  ? null
                  : _buildCheckoutArea(),
        );
      },
    );
  }

  Widget _buildEmptyBasket() {
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
              decoration:
                  const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 55,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(
              height: AppSpacing.large,
            ),
            const Text(
              'Your basket is empty',
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
              'Add a homemade meal to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(
              height: AppSpacing.large,
            ),
            FilledButton(
              onPressed: _goHome,
              child:
                  const Text('Browse Meals'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasketContents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(
        AppSpacing.page,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          ...basketData.basketItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.regular,
              ),
              child: _buildMealCard(item),
            ),
          ),
          const SizedBox(
            height: AppSpacing.section,
          ),
          _buildFulfilmentSelector(),
          const SizedBox(
            height: AppSpacing.section,
          ),
          _buildOrderSummary(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildMealCard(
    Map<String, dynamic> item,
  ) {
    final mealName =
        item['name']?.toString() ?? 'Meal';

    final cookName =
        item['cook']?.toString() ??
        'Home cook';

    final price =
        item['price']?.toString() ??
        '0.00';

    final emoji =
        item['emoji']?.toString() ??
        '🍽️';

    final itemQuantity =
        item['quantity'] as int? ?? 1;

    final availablePortions =
        item['portionsLeft'] as int? ??
        item['remainingPortions'] as int? ??
        0;

    final displayPrice =
        price.contains('£')
            ? price
            : '£$price';

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
                const SizedBox(height: 5),
                Text(
                  '$displayPrice each',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cookName,
                  style: const TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: AppSpacing.regular,
                ),
                Row(
                  children: [
                    _buildQuantityButton(
                      icon:
                          Icons.remove_rounded,
                      onPressed: () {
                        basketData
                            .decreaseQuantity(
                          mealName,
                        );
                      },
                    ),
                    Container(
                      width: 42,
                      alignment:
                          Alignment.center,
                      child: Text(
                        '$itemQuantity',
                        style:
                            const TextStyle(
                          color: AppColors
                              .textPrimary,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon:
                          Icons.add_rounded,
                      onPressed: () {
                        if (itemQuantity >=
                            availablePortions) {
                          ScaffoldMessenger.of(
                            context,
                          )
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Only $availablePortions portions are available.',
                                ),
                              ),
                            );

                          return;
                        }

                        basketData
                            .increaseQuantity(
                          mealName,
                        );
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        basketData.removeItem(
                          mealName,
                        );
                      },
                      icon: const Icon(
                        Icons
                            .delete_outline_rounded,
                        color:
                            Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              AppRadius.small,
            ),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildFulfilmentSelector() {
    if (!deliveryAvailable &&
        !collectionAvailable) {
      return const SizedBox.shrink();
    }

    if (deliveryAvailable &&
        !collectionAvailable) {
      _fulfilmentMethod = 'delivery';
      return const SizedBox.shrink();
    }

    if (!deliveryAvailable &&
        collectionAvailable) {
      _fulfilmentMethod = 'collection';
      return const SizedBox.shrink();
    }

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
            'How would you like to receive your order?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: AppSpacing.regular,
          ),
          RadioGroup<String>(
            groupValue: _fulfilmentMethod,
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _fulfilmentMethod = value;
              });
            },
            child: const Column(
              children: [
                RadioListTile<String>(
                  contentPadding:
                      EdgeInsets.zero,
                  title: Text('Delivery'),
                  subtitle: Text(
                    'Delivery fee £2.50',
                  ),
                  value: 'delivery',
                ),
                RadioListTile<String>(
                  contentPadding:
                      EdgeInsets.zero,
                  title: Text('Collection'),
                  subtitle: Text(
                    'Collect from the cook',
                  ),
                  value: 'collection',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
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
            'Order Summary',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: AppSpacing.large,
          ),
          _buildPriceRow(
            title: 'Subtotal',
            price:
                '£${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(
            height: AppSpacing.regular,
          ),
          _buildPriceRow(
            title: isCollectionOnly
                ? 'Collection'
                : 'Delivery fee',
            price: isCollectionOnly
                ? 'Free'
                : '£${currentDeliveryFee.toStringAsFixed(2)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical:
                  AppSpacing.regular,
            ),
            child: Divider(),
          ),
          _buildPriceRow(
            title: 'Total',
            price:
                '£${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required String title,
    required String price,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize:
                isTotal ? 17 : 14,
            fontWeight: isTotal
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          price,
          style: TextStyle(
            color: isTotal
                ? AppColors.primary
                : AppColors.textPrimary,
            fontSize:
                isTotal ? 19 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(
          AppSpacing.regular,
        ),
        decoration:
            const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 18,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _checkout,
            child: Text(
              'Proceed to Checkout  •  £${total.toStringAsFixed(2)}',
            ),
          ),
        ),
      ),
    );
  }
}