import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'basket_data.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.initialFulfilmentType,
  });

  final String initialFulfilmentType;

  @override
  State<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController();
  final TextEditingController _addressController =
      TextEditingController();
  final TextEditingController _notesController =
      TextEditingController();

  static const double _deliveryFee = 2.50;

  String _fulfilmentType = 'delivery';
  bool _isSubmitting = false;

  bool get _isDelivery =>
      _fulfilmentType == 'delivery';

  bool get _deliveryAvailable {
    if (basketData.basketItems.isEmpty) {
      return false;
    }

    return basketData.basketItems.every(
      (item) =>
          item['deliveryAvailable'] as bool? ?? false,
    );
  }

  bool get _collectionAvailable {
    if (basketData.basketItems.isEmpty) {
      return false;
    }

    return basketData.basketItems.every(
      (item) =>
          item['collectionAvailable'] as bool? ?? false,
    );
  }

  double _priceToDouble(dynamic value) {
    final String priceText = value
        .toString()
        .replaceAll('£', '')
        .replaceAll(',', '')
        .trim();

    return double.tryParse(priceText) ?? 0;
  }

  double get _subtotal {
    double amount = 0;

    for (final Map<String, dynamic> item
        in basketData.basketItems) {
      final double price =
          _priceToDouble(item['price']);
      final int quantity =
          item['quantity'] as int? ?? 1;

      amount += price * quantity;
    }

    return amount;
  }

  double get _currentDeliveryFee {
    return _isDelivery ? _deliveryFee : 0;
  }

  double get _total {
    return _subtotal + _currentDeliveryFee;
  }

  @override
  void initState() {
    super.initState();
    _setInitialFulfilmentType();
    _loadCurrentUserDetails();
  }

  void _setInitialFulfilmentType() {
    final String requestedType =
        widget.initialFulfilmentType;

    if (requestedType == 'delivery' &&
        _deliveryAvailable) {
      _fulfilmentType = 'delivery';
      return;
    }

    if (requestedType == 'collection' &&
        _collectionAvailable) {
      _fulfilmentType = 'collection';
      return;
    }

    if (_deliveryAvailable) {
      _fulfilmentType = 'delivery';
    } else if (_collectionAvailable) {
      _fulfilmentType = 'collection';
    }
  }

  void _loadCurrentUserDetails() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    if (user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      _nameController.text =
          user.displayName!.trim();
    }

    if (user.phoneNumber != null &&
        user.phoneNumber!.trim().isNotEmpty) {
      _phoneController.text =
          user.phoneNumber!.trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your full name';
    }

    if (value.trim().length < 2) {
      return 'Enter a valid name';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your phone number';
    }

    final String cleanedPhone =
        value.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (cleanedPhone.length < 7) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  String? _validateAddress(String? value) {
    if (!_isDelivery) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'Enter your delivery address';
    }

    if (value.trim().length < 8) {
      return 'Enter a complete delivery address';
    }

    return null;
  }

  List<Map<String, dynamic>> _buildOrderItems() {
    return basketData.basketItems.map((item) {
      final double unitPrice =
          _priceToDouble(item['price']);
      final int quantity =
          item['quantity'] as int? ?? 1;

      return <String, dynamic>{
        'mealId':
            item['mealId']?.toString() ?? '',
        'cookId':
            item['cookId']?.toString() ?? '',
        'name':
            item['name']?.toString() ?? 'Meal',
        'cook':
            item['cook']?.toString() ??
                'Home cook',
        'emoji':
            item['emoji']?.toString() ?? '🍽️',
        'imageUrl':
            item['imageUrl']?.toString(),
        'unitPrice': unitPrice,
        'quantity': quantity,
        'itemTotal': unitPrice * quantity,
      };
    }).toList();
  }

  Set<String> _getCookIds() {
    return basketData.basketItems
        .map(
          (item) =>
              item['cookId']?.toString() ?? '',
        )
        .where((cookId) => cookId.isNotEmpty)
        .toSet();
  }

  Future<void> _startStripeCheckout({
    required String orderId,
  }) async {
    final FirebaseFunctions functions =
        FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    );

    final HttpsCallable callable =
        functions.httpsCallable(
      'createStripeCheckoutSession',
    );

    final String successUrl = kIsWeb
    ? '${Uri.base.origin}/#/payment-success/$orderId'
    : 'homeeats://payment-success/$orderId';

    final String cancelUrl = kIsWeb
        ? '${Uri.base.origin}/#/checkout'
        : 'https://home-food-marketplace-5a60f.web.app/#/checkout';

    final HttpsCallableResult<dynamic> result =
        await callable.call({
      'orderId': orderId,
      'amount': (_total * 100).round(),
      'customerEmail':
          FirebaseAuth.instance.currentUser?.email ??
              '',
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    });

    final String checkoutUrl =
        result.data['checkoutUrl'] as String;

    final bool opened;

if (kIsWeb) {
  opened = await launchUrl(
    Uri.parse(checkoutUrl),
    webOnlyWindowName: '_self',
  );
} else {
  opened = await launchUrl(
    Uri.parse(checkoutUrl),
    mode: LaunchMode.externalApplication,
  );
}

    if (!opened) {
      throw Exception(
        'The Stripe payment page could not be opened.',
      );
    }
  }
    Future<bool> _validateBasketStock() async {
    for (final item in basketData.basketItems) {
      final String mealId =
          item['mealId']?.toString() ?? '';

      final int quantity =
          item['quantity'] as int? ?? 1;

      if (mealId.isEmpty) {
        return false;
      }

      final mealDocument =
          await FirebaseFirestore.instance
              .collection('meals')
              .doc(mealId)
              .get();

      final mealData = mealDocument.data();

      if (mealData == null) {
        if (!mounted) {
          return false;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'One of the meals in your basket is no longer available.',
            ),
          ),
        );

        return false;
      }

      final remainingValue =
          mealData['remainingPortions'] ??
              mealData['portions'];

      final int remainingPortions =
          remainingValue is num
              ? remainingValue.toInt()
              : int.tryParse(
                    remainingValue?.toString() ?? '',
                  ) ??
                  0;

      if (quantity > remainingPortions) {
        if (!mounted) {
          return false;
        }

        final String mealName =
            item['name']?.toString() ??
                'This meal';

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '$mealName only has $remainingPortions portions left. '
                'Please update your basket.',
              ),
            ),
          );

        return false;
      }
    }

    return true;
  }

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();

    if (basketData.basketItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your basket is empty',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in before placing your order',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bool stockIsValid =
          await _validateBasketStock();

      if (!stockIsValid) {
        return;
      }

      final List<Map<String, dynamic>>
          orderItems =
          _buildOrderItems();

      final Set<String> cookIds =
          _getCookIds();

      final DocumentReference<Map<String, dynamic>>
          orderReference =
          FirebaseFirestore.instance
              .collection('orders')
              .doc();

      await orderReference.set({
        'orderId': orderReference.id,
        'customerId': user.uid,
        'customerEmail': user.email ?? '',
        'customerName':
            _nameController.text.trim(),
        'customerPhone':
            _phoneController.text.trim(),
        'fulfilmentType': _fulfilmentType,
        'deliveryAddress': _isDelivery
            ? _addressController.text.trim()
            : '',
        'notes':
            _notesController.text.trim(),
        'items': orderItems,
        'cookIds': cookIds.toList(),
        'subtotal': _subtotal,
        'deliveryFee':
            _currentDeliveryFee,
        'total': _total,
        'status': 'awaiting_payment',
        'paymentStatus':
            'awaiting_payment',
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      await _startStripeCheckout(
        orderId: orderReference.id,
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error.message ??
                  'Unable to place your order',
            ),
          ),
        );
    } catch (error) {
      debugPrint(
        'Checkout error: $error',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Something went wrong. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: basketData,
      builder: (context, child) {
        return Scaffold(
          backgroundColor:
              AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Checkout',
            ),
            centerTitle: true,
          ),
          body: Form(
            key: _formKey,
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.large,
                AppSpacing.page,
                140,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    'Contact details',
                  ),
                  const SizedBox(
                    height:
                        AppSpacing.regular,
                  ),
                  _buildCustomerDetailsCard(),
                  const SizedBox(
                    height:
                        AppSpacing.section,
                  ),
                  _buildSectionTitle(
                    'How would you like your order?',
                  ),
                  const SizedBox(
                    height:
                        AppSpacing.regular,
                  ),
                  _buildFulfilmentSelector(),
                  if (_isDelivery) ...[
                    const SizedBox(
                      height:
                          AppSpacing.regular,
                    ),
                    _buildAddressField(),
                  ],
                  const SizedBox(
                    height:
                        AppSpacing.section,
                  ),
                  _buildSectionTitle(
                    'Order notes',
                  ),
                  const SizedBox(
                    height:
                        AppSpacing.regular,
                  ),
                  _buildNotesField(),
                  const SizedBox(
                    height:
                        AppSpacing.section,
                  ),
                  _buildSectionTitle(
                    'Your order',
                  ),
                  const SizedBox(
                    height:
                        AppSpacing.regular,
                  ),
                  _buildItemsCard(),
                  const SizedBox(
                    height:
                        AppSpacing.regular,
                  ),
                  _buildOrderSummary(),
                ],
              ),
            ),
          ),
          bottomNavigationBar:
              basketData.basketItems.isEmpty
                  ? null
                  : _buildPlaceOrderArea(),
        );
      },
    );
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(
            color:
                AppColors.textPrimary,
            fontWeight:
                FontWeight.w900,
          ),
    );
  }
    Widget _buildCustomerDetailsCard() {
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
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            textInputAction:
                TextInputAction.next,
            textCapitalization:
                TextCapitalization.words,
            validator: _validateName,
            decoration:
                const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
            ),
          ),
          const SizedBox(
            height: AppSpacing.regular,
          ),
          TextFormField(
            controller: _phoneController,
            keyboardType:
                TextInputType.phone,
            textInputAction:
                TextInputAction.done,
            validator: _validatePhone,
            decoration:
                const InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(
                Icons.phone_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFulfilmentSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildFulfilmentOption(
            value: 'delivery',
            title: 'Delivery',
            subtitle: _deliveryAvailable
                ? 'Delivered to you'
                : 'Not available',
            icon:
                Icons.delivery_dining_rounded,
            isAvailable:
                _deliveryAvailable,
          ),
        ),
        const SizedBox(
          width: AppSpacing.regular,
        ),
        Expanded(
          child: _buildFulfilmentOption(
            value: 'collection',
            title: 'Collection',
            subtitle: _collectionAvailable
                ? 'Collect from cook'
                : 'Not available',
            icon:
                Icons.storefront_rounded,
            isAvailable:
                _collectionAvailable,
          ),
        ),
      ],
    );
  }

  Widget _buildFulfilmentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isAvailable,
  }) {
    final bool isSelected =
        _fulfilmentType == value;

    return InkWell(
      onTap:
          _isSubmitting || !isAvailable
              ? null
              : () {
                  setState(() {
                    _fulfilmentType =
                        value;

                    if (!_isDelivery) {
                      _addressController
                          .clear();
                    }
                  });
                },
      borderRadius:
          BorderRadius.circular(
        AppRadius.card,
      ),
      child: AnimatedOpacity(
        duration:
            const Duration(
          milliseconds: 180,
        ),
        opacity:
            isAvailable ? 1 : 0.45,
        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 180,
          ),
          padding:
              const EdgeInsets.all(
            AppSpacing.regular,
          ),
          decoration:
              BoxDecoration(
            color:
                isSelected &&
                        isAvailable
                    ? AppColors
                        .primaryLight
                    : Colors.white,
            borderRadius:
                BorderRadius.circular(
              AppRadius.card,
            ),
            border: Border.all(
              color:
                  isSelected &&
                          isAvailable
                      ? AppColors.primary
                      : AppColors
                          .surfaceSoft,
              width:
                  isSelected &&
                          isAvailable
                      ? 2
                      : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected &&
                            isAvailable
                        ? AppColors.primary
                        : AppColors
                            .textSecondary,
                size: 30,
              ),
              const SizedBox(
                height:
                    AppSpacing.small,
              ),
              Text(
                title,
                style: TextStyle(
                  color: AppColors
                      .textPrimary,
                  fontSize: 15,
                  fontWeight:
                      isSelected &&
                              isAvailable
                          ? FontWeight
                              .w900
                          : FontWeight
                              .w700,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                subtitle,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: AppColors
                      .textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField() {
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
      child: TextFormField(
        controller:
            _addressController,
        validator:
            _validateAddress,
        textCapitalization:
            TextCapitalization.sentences,
        keyboardType:
            TextInputType.streetAddress,
        minLines: 2,
        maxLines: 4,
        decoration:
            const InputDecoration(
          labelText:
              'Delivery address',
          alignLabelWithHint: true,
          prefixIcon: Icon(
            Icons.location_on_outlined,
          ),
          hintText:
              'House number, street and postcode',
        ),
      ),
    );
  }

  Widget _buildNotesField() {
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
      child: TextFormField(
        controller:
            _notesController,
        textCapitalization:
            TextCapitalization.sentences,
        minLines: 3,
        maxLines: 5,
        maxLength: 250,
        decoration:
            const InputDecoration(
          labelText:
              'Additional notes',
          alignLabelWithHint: true,
          prefixIcon: Icon(
            Icons.notes_rounded,
          ),
          hintText:
              'Delivery instructions or requests',
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AppSpacing.regular,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
      ),
      child: Column(
        children: basketData
            .basketItems
            .asMap()
            .entries
            .map((entry) {
          final int index =
              entry.key;

          final Map<String, dynamic>
              item =
              entry.value;

          final String name =
              item['name']?.toString() ??
                  'Meal';

          final String emoji =
              item['emoji']?.toString() ??
                  '🍽️';

          final int quantity =
              item['quantity'] as int? ??
                  1;

          final double unitPrice =
              _priceToDouble(
            item['price'],
          );

          final double itemTotal =
              unitPrice * quantity;

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration:
                        BoxDecoration(
                      color: AppColors
                          .primaryLight,
                      borderRadius:
                          BorderRadius
                              .circular(
                        AppRadius.medium,
                      ),
                    ),
                    alignment:
                        Alignment.center,
                    child: Text(
                      emoji,
                      style:
                          const TextStyle(
                        fontSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: AppSpacing
                        .regular,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          name,
                          style:
                              const TextStyle(
                            color: AppColors
                                .textPrimary,
                            fontSize: 14,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Quantity: $quantity',
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
                  Text(
                    '£${itemTotal.toStringAsFixed(2)}',
                    style:
                        const TextStyle(
                      color: AppColors
                          .textPrimary,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (index <
                  basketData
                          .basketItems
                          .length -
                      1)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical:
                        AppSpacing.regular,
                  ),
                  child:
                      Divider(height: 1),
                ),
            ],
          );
        }).toList(),
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
        children: [
          _buildPriceRow(
            title: 'Subtotal',
            price:
                '£${_subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(
            height: AppSpacing.regular,
          ),
          _buildPriceRow(
            title: _isDelivery
                ? 'Delivery fee'
                : 'Collection',
            price: _isDelivery
                ? '£${_currentDeliveryFee.toStringAsFixed(2)}'
                : 'Free',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.regular,
            ),
            child: Divider(),
          ),
          _buildPriceRow(
            title: 'Total',
            price:
                '£${_total.toStringAsFixed(2)}',
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
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal
                ? FontWeight.w900
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
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(
          AppSpacing.regular,
        ),
        decoration: const BoxDecoration(
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
          height: 56,
          child: FilledButton(
            onPressed:
                _isSubmitting ? null : _placeOrder,
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Continue to Payment  •  £${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}