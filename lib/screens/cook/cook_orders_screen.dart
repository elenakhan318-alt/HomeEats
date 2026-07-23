import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class CookOrdersScreen extends StatelessWidget {
  const CookOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Incoming Orders'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(
              child: Text('You are not signed in.'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('cookIds', arrayContains: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.page),
                      child: Text(
                        'Orders could not be loaded.\n${snapshot.error}',
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

                final orders = snapshot.data?.docs.toList() ?? [];

                orders.sort((first, second) {
                  final firstCreatedAt =
                      first.data()['createdAt'] as Timestamp?;
                  final secondCreatedAt =
                      second.data()['createdAt'] as Timestamp?;

                  if (firstCreatedAt == null &&
                      secondCreatedAt == null) {
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
                      child: Text(
                        'No incoming orders yet.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(
                      height: AppSpacing.regular,
                    );
                  },
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    return _buildOrderCard(
                      context: context,
                      orderId: order.id,
                      data: order.data(),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required String orderId,
    required Map<String, dynamic> data,
  }) {
    final customerName =
        data['customerName']?.toString() ?? 'Customer';

    final fulfilmentType =
        data['fulfilmentType']?.toString() ?? 'Unknown';

    final status =
        data['status']?.toString() ?? 'pending';

    final totalValue = data['total'];

    final total = totalValue is num
        ? totalValue.toDouble()
        : double.tryParse(totalValue?.toString() ?? '') ?? 0;

    final itemsValue = data['items'];

    final items = itemsValue is List
        ? itemsValue
        : <dynamic>[];

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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fulfilmentType,
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
                  '${item['quantity'] ?? 1} × ${item['name'] ?? 'Meal'}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

          const SizedBox(height: AppSpacing.small),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          if (status == 'pending') ...[
            const SizedBox(height: AppSpacing.regular),
            Row(
              children: [
  Expanded(
  child: OutlinedButton(
    onPressed: () {
      _showRejectDialog(
        context: context,
        orderId: orderId,
      );
    },
    child: const Text('Reject'),
  ),
),
const SizedBox(width: AppSpacing.small),
Expanded(
  child: FilledButton(
    onPressed: () {
      _updateStatus(
        context: context,
        orderId: orderId,
        status: 'accepted',
      );
    },
    child: const Text('Accept'),
  ),
),
 ],
  ),
],
          if (status == 'accepted') ...[
            const SizedBox(height: AppSpacing.regular),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  _updateStatus(
                    context: context,
                    orderId: orderId,
                    status: 'preparing',
                  );
                },
                child: const Text('Start Preparing'),
              ),
            ),
          ],

          if (status == 'preparing') ...[
            const SizedBox(height: AppSpacing.regular),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  _updateStatus(
                    context: context,
                    orderId: orderId,
                    status: 'ready',
                  );
                },
                child: const Text('Mark Ready'),
              ),
            ),
          ],

          if (status == 'ready') ...[
            const SizedBox(height: AppSpacing.regular),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  _updateStatus(
                    context: context,
                    orderId: orderId,
                    status: 'completed',
                  );
                },
                child: const Text('Complete Order'),
              ),
            ),
          ],
        ],
      ),
    );
  }
Future<void> _showRejectDialog({
  required BuildContext context,
  required String orderId,
}) async {
  final controller = TextEditingController();

  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Reject order'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Tell the customer why...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();

              if (text.isEmpty) {
                return;
              }

              Navigator.of(dialogContext).pop(text);
            },
            child: const Text('Reject'),
          ),
        ],
      );
    },
  );

  controller.dispose();

  if (reason == null || reason.isEmpty) {
    return;
  }

  try {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({
      'status': 'rejected',
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order rejected'),
      ),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order could not be rejected: $error',
        ),
      ),
    );
  }
}
  Future<void> _updateStatus({
    required BuildContext context,
    required String orderId,
    required String status,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order could not be updated: $error',
          ),
        ),
      );
    }
  }
}