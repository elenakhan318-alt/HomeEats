import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class CookOrderDetailsScreen extends StatelessWidget {
  const CookOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Time unavailable';
    }

    final date = timestamp.toDate();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day}/${date.month}/${date.year} at $hour:$minute';
  }

  String _displayFulfilment(String value) {
    if (value.toLowerCase() == 'collection') {
      return 'Collection';
    }

    if (value.toLowerCase() == 'delivery') {
      return 'Delivery';
    }

    return value;
  }

  String _shortOrderId() {
    if (orderId.length <= 8) {
      return orderId.toUpperCase();
    }

    return orderId.substring(0, 8).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(
                  AppSpacing.page,
                ),
                child: Text(
                  'Order details could not be loaded.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final document = snapshot.data;

          if (document == null || !document.exists) {
            return const Center(
              child: Text('Order not found.'),
            );
          }

          final data =
              document.data() ?? <String, dynamic>{};

          final customerName =
              data['customerName']?.toString() ??
                  'Customer';

          final customerPhone =
              data['customerPhone']?.toString() ??
                  'Not provided';

          final fulfilmentType =
              data['fulfilmentType']?.toString() ??
                  'Unknown';

          final deliveryAddress =
              data['deliveryAddress']?.toString() ?? '';

          final notes =
              data['notes']?.toString() ?? '';

          final status =
              data['status']?.toString() ?? 'pending';

          final subtotal =
              _toDouble(data['subtotal']);

          final deliveryFee =
              _toDouble(data['deliveryFee']);

          final total =
              _toDouble(data['total']);

          final createdAt =
              data['createdAt'] as Timestamp?;

          final itemsValue = data['items'];

          final items = itemsValue is List
              ? itemsValue
              : <dynamic>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.page,
              AppSpacing.page,
              40,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildCard(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      _buildDetailRow(
                        icon:
                            Icons.person_outline_rounded,
                        label: 'Name',
                        value: customerName,
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      _buildDetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: customerPhone,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.regular,
                ),

                _buildCard(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order information',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      _buildDetailRow(
                        icon:
                            Icons.receipt_long_outlined,
                        label: 'Order',
                        value: _shortOrderId(),
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      _buildDetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Placed',
                        value:
                            _formatTimestamp(createdAt),
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      _buildDetailRow(
                        icon: fulfilmentType ==
                                'delivery'
                            ? Icons
                                .delivery_dining_rounded
                            : Icons.storefront_rounded,
                        label: 'Fulfilment',
                        value: _displayFulfilment(
                          fulfilmentType,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      const Text(
                        'Status',
                        style: TextStyle(
                          color:
                              AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildStatusBadge(status),
                    ],
                  ),
                ),

                if (fulfilmentType == 'delivery') ...[
                  const SizedBox(
                    height: AppSpacing.regular,
                  ),
                  _buildCard(
                    child: _buildDetailRow(
                      icon:
                          Icons.location_on_outlined,
                      label: 'Delivery address',
                      value: deliveryAddress.isEmpty
                          ? 'Not provided'
                          : deliveryAddress,
                    ),
                  ),
                ],

                const SizedBox(
                  height: AppSpacing.regular,
                ),

                _buildCard(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      if (items.isEmpty)
                        const Text(
                          'No items found for this order.',
                          style: TextStyle(
                            color:
                                AppColors.textSecondary,
                          ),
                        ),
                      for (final item in items)
                        if (item is Map)
                          _buildItemCard(item),
                    ],
                  ),
                ),

                if (notes.trim().isNotEmpty) ...[
                  const SizedBox(
                    height: AppSpacing.regular,
                  ),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              color: AppColors.primary,
                            ),
                            SizedBox(
                              width: AppSpacing.small,
                            ),
                            Text(
                              'Customer notes',
                              style: TextStyle(
                                color:
                                    AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: AppSpacing.regular,
                        ),
                        Text(
                          notes,
                          style: const TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(
                  height: AppSpacing.regular,
                ),

                _buildCard(
                  child: Column(
                    children: [
                      _buildPriceRow(
                        label: 'Subtotal',
                        value: subtotal,
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      _buildPriceRow(
                        label:
                            fulfilmentType == 'collection'
                                ? 'Collection'
                                : 'Delivery fee',
                        value: deliveryFee,
                        showFree:
                            fulfilmentType == 'collection',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical:
                              AppSpacing.regular,
                        ),
                        child: Divider(),
                      ),
                      _buildPriceRow(
                        label: 'Total',
                        value: total,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.regular,
                ),

                _buildStatusActions(
                  context: context,
                  status: status,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
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
      child: child,
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 22,
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
                label,
                style: const TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(Map<dynamic, dynamic> item) {
    final name =
        item['name']?.toString() ?? 'Meal';

    final quantityValue = item['quantity'];
    final quantity = quantityValue is num
        ? quantityValue.toInt()
        : int.tryParse(
              quantityValue?.toString() ?? '',
            ) ??
            1;

    final unitPrice =
        _toDouble(item['unitPrice']);

    final itemTotal =
        _toDouble(item['itemTotal']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: AppSpacing.regular,
      ),
      padding: const EdgeInsets.all(
        AppSpacing.regular,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(
          AppRadius.medium,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Quantity: $quantity',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '£${unitPrice.toStringAsFixed(2)} each',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: £${itemTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'accepted':
        backgroundColor =
            const Color(0xFFFFE0C7);
        textColor = AppColors.primary;
        label = 'ACCEPTED';
        break;

      case 'preparing':
        backgroundColor =
            const Color(0xFFFFE9D6);
        textColor = AppColors.primary;
        label = 'PREPARING';
        break;

      case 'ready':
        backgroundColor =
            const Color(0xFFE4F4E7);
        textColor = Colors.green;
        label = 'READY';
        break;

      case 'completed':
        backgroundColor =
            const Color(0xFFE4F4E7);
        textColor = Colors.green;
        label = 'COMPLETED';
        break;

      case 'rejected':
        backgroundColor =
            const Color(0xFFFFE3E3);
        textColor = Colors.red;
        label = 'REJECTED';
        break;

      default:
        backgroundColor =
            AppColors.primaryLight;
        textColor = AppColors.primary;
        label = 'PENDING';
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            AppRadius.pill,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusActions({
    required BuildContext context,
    required String status,
  }) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _updateOrderStatus(
                    context: context,
                    status: 'rejected',
                  );
                },
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(
              width: AppSpacing.small,
            ),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  _updateOrderStatus(
                    context: context,
                    status: 'accepted',
                  );
                },
                child: const Text('Accept'),
              ),
            ),
          ],
        );

      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              _updateOrderStatus(
                context: context,
                status: 'preparing',
              );
            },
            child: const Text('Start Preparing'),
          ),
        );

      case 'preparing':
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              _updateOrderStatus(
                context: context,
                status: 'ready',
              );
            },
            child: const Text('Mark Ready'),
          ),
        );

      case 'ready':
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              _updateOrderStatus(
                context: context,
                status: 'completed',
              );
            },
            child: const Text('Complete Order'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _updateOrderStatus({
    required BuildContext context,
    required String status,
  }) async {
    try {
      final orderReference =
          FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId);

      final orderSnapshot =
          await orderReference.get();

      final orderData =
          orderSnapshot.data() ??
              <String, dynamic>{};

      final customerId =
          orderData['customerId']
                  ?.toString() ??
              '';

      final batch =
          FirebaseFirestore.instance.batch();

      batch.update(orderReference, {
        'status': status,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (customerId.isNotEmpty) {
        final notificationReference =
            FirebaseFirestore.instance
                .collection('notifications')
                .doc();

        final readableStatus =
            status.replaceAll('_', ' ');

        batch.set(notificationReference, {
          'userId': customerId,
          'orderId': orderId,
          'type': 'order_status',
          'title': 'Order update',
          'message':
              'Your order is now $readableStatus.',
          'status': status,
          'isRead': false,
          'createdAt':
              FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Order updated to $status',
            ),
          ),
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
              'Order could not be updated: $error',
            ),
          ),
        );
    }
  }

  Widget _buildPriceRow({
    required String label,
    required double value,
    bool isTotal = false,
    bool showFree = false,
  }) {
    return Row(
      children: [
        Text(
          label,
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
          showFree
              ? 'Free'
              : '£${value.toStringAsFixed(2)}',
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
}