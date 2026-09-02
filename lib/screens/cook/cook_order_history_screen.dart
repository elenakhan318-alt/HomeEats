import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'cook_order_details_screen.dart';

class CookOrderHistoryScreen extends StatelessWidget {
  const CookOrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Previous Orders'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(
              child: Text('You are not signed in.'),
            )
          : StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where(
                    'cookIds',
                    arrayContains: user.uid,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppSpacing.page,
                      ),
                      child: Text(
                        'Previous orders could not be loaded.\n'
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

                final orders =
                    snapshot.data?.docs.where((order) {
                          final data = order.data();

                          final paymentStatus =
                              data['paymentStatus']
                                      ?.toString() ??
                                  '';

                          final status =
                              data['status']?.toString() ??
                                  '';

                          return paymentStatus == 'paid' &&
                              (status == 'completed' ||
                                  status == 'rejected');
                        }).toList() ??
                        [];

                orders.sort((first, second) {
                  final firstData = first.data();
                  final secondData = second.data();

                  final firstDate =
                      firstData['completedAt']
                              as Timestamp? ??
                          firstData['rejectedAt']
                              as Timestamp? ??
                          firstData['createdAt']
                              as Timestamp?;

                  final secondDate =
                      secondData['completedAt']
                              as Timestamp? ??
                          secondData['rejectedAt']
                              as Timestamp? ??
                          secondData['createdAt']
                              as Timestamp?;

                  if (firstDate == null &&
                      secondDate == null) {
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

                if (orders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        AppSpacing.page,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 56,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(
                            height: AppSpacing.regular,
                          ),
                          Text(
                            'No previous orders yet.',
                            style: TextStyle(
                              color:
                                  AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(
                            height: AppSpacing.small,
                          ),
                          Text(
                            'Completed and rejected orders '
                            'will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(
                    AppSpacing.page,
                  ),
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
    final String customerName =
        data['customerName']?.toString() ??
            'Customer';

    final String fulfilmentType =
        data['fulfilmentType']?.toString() ??
            'Unknown';

    final String status =
        data['status']?.toString() ?? 'completed';

    final dynamic totalValue = data['total'];

    final double total = totalValue is num
        ? totalValue.toDouble()
        : double.tryParse(
              totalValue?.toString() ?? '',
            ) ??
            0;

    final dynamic itemsValue = data['items'];

    final List<dynamic> items =
        itemsValue is List
            ? itemsValue
            : <dynamic>[];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CookOrderDetailsScreen(
                orderId: orderId,
              ),
            ),
          );
        },
        child: Container(
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor:
                        AppColors.primaryLight,
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.primary,
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
                          customerName,
                          style: const TextStyle(
                            color:
                                AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _capitalise(
                            fulfilmentType,
                          ),
                          style: const TextStyle(
                            color:
                                AppColors.textSecondary,
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

              const SizedBox(
                height: AppSpacing.regular,
              ),

              for (final item in items)
                if (item is Map)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 6,
                    ),
                    child: Text(
                      '${item['quantity'] ?? 1} × '
                      '${item['name'] ?? 'Meal'}',
                      style: const TextStyle(
                        color:
                            AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

              const SizedBox(
                height: AppSpacing.small,
              ),

              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'completed'
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(
                        AppRadius.pill,
                      ),
                    ),
                    child: Text(
                      status == 'completed'
                          ? 'COMPLETED'
                          : 'REJECTED',
                      style: TextStyle(
                        color: status == 'completed'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalise(String value) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}'
        '${value.substring(1)}';
  }
}