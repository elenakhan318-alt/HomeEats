import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: Text(
                  'Order could not be loaded.\n${snapshot.error}',
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

          final document = snapshot.data;

          if (document == null || !document.exists) {
            return const Center(
              child: Text('This order could not be found.'),
            );
          }

          final data = document.data() ?? <String, dynamic>{};

          return _buildOrderDetails(
            context: context,
            data: data,
          );
        },
      ),
    );
  }

  Widget _buildOrderDetails({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) {
    final status = data['status']?.toString() ?? 'pending';

    final rejectionReason =
        data['rejectionReason']?.toString().trim() ?? '';

    final customerAcknowledgedRejection =
        data['customerAcknowledgedRejection'] == true;

    final fulfilmentType =
        data['fulfilmentType']?.toString() ?? 'collection';

    final totalValue = data['total'];

    final total = totalValue is num
        ? totalValue.toDouble()
        : double.tryParse(totalValue?.toString() ?? '') ?? 0;

    final itemsValue = data['items'];
    final items = itemsValue is List ? itemsValue : <dynamic>[];

    final createdAt = data['createdAt'] as Timestamp?;

    final createdDate = createdAt == null
        ? 'Date unavailable'
        : _formatDate(createdAt.toDate());

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        _buildSummaryCard(
          status: status,
          fulfilmentType: fulfilmentType,
          total: total,
          createdDate: createdDate,
        ),
        const SizedBox(height: AppSpacing.regular),
        if (status == 'rejected') ...[
          _buildRejectionCard(
            context: context,
            rejectionReason: rejectionReason,
            acknowledged: customerAcknowledgedRejection,
          ),
          const SizedBox(height: AppSpacing.regular),
        ],
        _buildProgressCard(status),
        const SizedBox(height: AppSpacing.regular),
        _buildItemsCard(items),
        const SizedBox(height: AppSpacing.regular),
        _buildTotalCard(total),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String status,
    required String fulfilmentType,
    required double total,
    required String createdDate,
  }) {
    final isRejected = status == 'rejected';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.regular),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isRejected
                    ? Colors.red.shade100
                    : AppColors.primaryLight,
                child: Icon(
                  isRejected
                      ? Icons.cancel_outlined
                      : Icons.receipt_long_outlined,
                  color: isRejected
                      ? Colors.red.shade700
                      : AppColors.primary,
                ),
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
                        fontSize: 17,
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
                style: TextStyle(
                  color: isRejected
                      ? Colors.red.shade700
                      : AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.regular,
            ),
            child: Divider(),
          ),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 17,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  createdDate,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard({
    required BuildContext context,
    required String rejectionReason,
    required bool acknowledged,
  }) {
    final displayedReason = rejectionReason.isEmpty
        ? 'The cook did not provide a reason.'
        : rejectionReason;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.regular),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.red.shade100,
                child: Icon(
                  Icons.cancel_outlined,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(width: AppSpacing.regular),
              Expanded(
                child: Text(
                  'Order rejected',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.regular),
          const Text(
            'Reason from the cook',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            displayedReason,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (!acknowledged) ...[
            const SizedBox(height: AppSpacing.regular),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _acknowledgeRejection(context);
                },
                child: const Text('OK, I understand'),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.regular),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  'Rejection acknowledged',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acknowledgeRejection(
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'customerAcknowledgedRejection': true,
        'customerAcknowledgedRejectionAt':
            FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rejection acknowledged.'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not acknowledge the rejection: $error',
          ),
        ),
      );
    }
  }

  Widget _buildProgressCard(String status) {
    final rejected = status == 'rejected';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.regular),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order progress',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.regular),
          if (rejected)
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.red.shade100,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: AppSpacing.regular),
                const Expanded(
                  child: Text(
                    'This order was rejected by the cook.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            _buildProgressStep(
              label: 'Order placed',
              isComplete: _statusIndex(status) >= 0,
              isLast: false,
            ),
            _buildProgressStep(
              label: 'Accepted',
              isComplete: _statusIndex(status) >= 1,
              isLast: false,
            ),
            _buildProgressStep(
              label: 'Preparing',
              isComplete: _statusIndex(status) >= 2,
              isLast: false,
            ),
            _buildProgressStep(
              label: 'Ready',
              isComplete: _statusIndex(status) >= 3,
              isLast: false,
            ),
            _buildProgressStep(
              label: 'Completed',
              isComplete: _statusIndex(status) >= 4,
              isLast: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressStep({
    required String label,
    required bool isComplete,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: isComplete
                  ? AppColors.primary
                  : AppColors.primaryLight,
              child: Icon(
                isComplete
                    ? Icons.check_rounded
                    : Icons.circle_outlined,
                size: 17,
                color: isComplete
                    ? Colors.white
                    : AppColors.primary,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isComplete
                    ? AppColors.primary
                    : AppColors.primaryLight,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.regular),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            label,
            style: TextStyle(
              color: isComplete
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: isComplete
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard(List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.regular),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.regular),
          if (items.isEmpty)
            const Text(
              'No items found.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            )
          else
            for (var index = 0;
                index < items.length;
                index++) ...[
              if (items[index] is Map)
                _buildItemRow(items[index] as Map),
              if (index != items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.small,
                  ),
                  child: Divider(),
                ),
            ],
        ],
      ),
    );
  }

  Widget _buildItemRow(
    Map<dynamic, dynamic> item,
  ) {
    final quantityValue = item['quantity'];

    final quantity = quantityValue is num
        ? quantityValue.toInt()
        : int.tryParse(quantityValue?.toString() ?? '') ?? 1;

    final totalValue = item['itemTotal'];

    final itemTotal = totalValue is num
        ? totalValue.toDouble()
        : double.tryParse(totalValue?.toString() ?? '') ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius:
                BorderRadius.circular(AppRadius.medium),
          ),
          child: Text(
            item['emoji']?.toString() ?? '🍽️',
            style: const TextStyle(fontSize: 22),
          ),
        ),
        const SizedBox(width: AppSpacing.regular),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name']?.toString() ?? 'Meal',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Quantity: $quantity',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          '£${itemTotal.toStringAsFixed(2)}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(double total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.regular),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Order total',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '£${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isRejected = status == 'rejected';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isRejected
            ? Colors.red.shade100
            : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: isRejected
              ? Colors.red.shade700
              : AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  int _statusIndex(String status) {
    switch (status) {
      case 'accepted':
        return 1;
      case 'preparing':
        return 2;
      case 'ready':
        return 3;
      case 'completed':
        return 4;
      case 'pending':
      default:
        return 0;
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
      case 'completed':
        return 'COMPLETED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'PENDING';
    }
  }

  String _shortOrderId(String value) {
    if (value.length <= 6) {
      return value.toUpperCase();
    }

    return value.substring(0, 6).toUpperCase();
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

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day} ${months[date.month - 1]} '
        '${date.year} at $hour:$minute';
  }
}
