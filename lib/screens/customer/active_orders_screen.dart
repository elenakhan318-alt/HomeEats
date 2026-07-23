import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'order_details_screen.dart';

class ActiveOrdersScreen extends StatelessWidget {
  const ActiveOrdersScreen({super.key});

  static const activeStatuses = {'pending', 'accepted', 'preparing', 'ready'};

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Active Orders'), centerTitle: true),
      body: user == null
          ? const Center(
              child: Text('Please sign in to view your active orders.'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('customerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.page),
                      child: Text(
                        'Active orders could not be loaded.\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders =
                    snapshot.data?.docs.where((document) {
                      final status =
                          document.data()['status']?.toString() ?? 'pending';

                      return activeStatuses.contains(status);
                    }).toList() ??
                    [];

                orders.sort((first, second) {
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

                if (orders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.page),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delivery_dining_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: AppSpacing.regular),
                          Text(
                            'No active orders',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: AppSpacing.small),
                          Text(
                            'New orders and live updates will appear here.',
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

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: AppSpacing.regular);
                  },
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return OrderDetailsScreen(orderId: order.id);
                            },
                          ),
                        );
                      },
                      child: _buildOrderCard(
                        orderId: order.id,
                        data: order.data(),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required Map<String, dynamic> data,
  }) {
    final status = data['status']?.toString() ?? 'pending';

    final fulfilmentType = data['fulfilmentType']?.toString() ?? 'collection';

    final totalValue = data['total'];

    final total = totalValue is num
        ? totalValue.toDouble()
        : double.tryParse(totalValue?.toString() ?? '') ?? 0;

    final createdAt = data['createdAt'] as Timestamp?;

    final dateText = createdAt == null
        ? 'Date unavailable'
        : _formatDate(createdAt.toDate());

    final itemsValue = data['items'];
    final items = itemsValue is List ? itemsValue : <dynamic>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.regular),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Icon(_statusIcon(status), color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.regular),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${_shortOrderId(orderId)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _capitalise(fulfilmentType),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '£${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.regular),

          for (final item in items)
            if (item is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${item['quantity'] ?? 1} × '
                  '${item['name'] ?? 'Meal'}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

          const SizedBox(height: AppSpacing.small),

          Row(
            children: [
              _buildStatusBadge(status),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.regular),
            child: Divider(),
          ),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                dateText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  _statusMessage(
                    status: status,
                    fulfilmentType: fulfilmentType,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _statusLabel(status),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.thumb_up_alt_outlined;
      case 'preparing':
        return Icons.restaurant_outlined;
      case 'ready':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'ACCEPTED';
      case 'preparing':
        return 'PREPARING';
      case 'ready':
        return 'READY';
      default:
        return 'PENDING';
    }
  }

  String _statusMessage({
    required String status,
    required String fulfilmentType,
  }) {
    switch (status) {
      case 'accepted':
        return 'Your order was accepted';
      case 'preparing':
        return 'Your meal is being prepared';
      case 'ready':
        return fulfilmentType == 'delivery'
            ? 'Ready for delivery'
            : 'Ready for collection';
      default:
        return 'Waiting for the cook';
    }
  }

  String _shortOrderId(String orderId) {
    if (orderId.length <= 6) {
      return orderId.toUpperCase();
    }

    return orderId.substring(0, 6).toUpperCase();
  }

  String _capitalise(String value) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _formatDate(DateTime date) {
    const months = [
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
