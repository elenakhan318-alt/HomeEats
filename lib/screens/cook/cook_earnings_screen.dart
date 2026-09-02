import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CookEarningsScreen extends StatelessWidget {
  const CookEarningsScreen({super.key});

  double _readNumber(
    Map<String, dynamic> data,
    List<String> fieldNames,
  ) {
    for (final fieldName in fieldNames) {
      final value = data[fieldName];

      if (value is num) {
        return value.toDouble();
      }

      final parsed = double.tryParse(
        value?.toString() ?? '',
      );

      if (parsed != null) {
        return parsed;
      }
    }

    return 0;
  }

  double _readOrderTotal(
    Map<String, dynamic> data,
  ) {
    return _readNumber(
      data,
      [
        'totalPaid',
        'total',
        'totalAmount',
        'grandTotal',
        'orderTotal',
      ],
    );
  }

  double _readCookEarnings(
    Map<String, dynamic> data,
  ) {
    final storedEarnings = _readNumber(
      data,
      [
        'cookGrossEarnings',
      ],
    );

    if (storedEarnings > 0) {
      return storedEarnings;
    }

    final total = _readOrderTotal(data);

    final commissionPercent = _readNumber(
      data,
      [
        'commissionPercent',
      ],
    );

    if (commissionPercent >= 0 &&
        commissionPercent <= 100) {
      return total *
          ((100 - commissionPercent) / 100);
    }

    return total;
  }

  double _readPlatformCommission(
    Map<String, dynamic> data,
  ) {
    final storedCommission = _readNumber(
      data,
      [
        'platformCommission',
      ],
    );

    if (storedCommission > 0) {
      return storedCommission;
    }

    final total = _readOrderTotal(data);

    final commissionPercent = _readNumber(
      data,
      [
        'commissionPercent',
      ],
    );

    if (commissionPercent >= 0 &&
        commissionPercent <= 100) {
      return total *
          (commissionPercent / 100);
    }

    return 0;
  }

  bool _isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isInCurrentWeek(
    DateTime date,
    DateTime now,
  ) {
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

    final startOfNextWeek = startOfWeek.add(
      const Duration(days: 7),
    );

    return !date.isBefore(startOfWeek) &&
        date.isBefore(startOfNextWeek);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in again.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cook Wallet'),
        centerTitle: true,
      ),
      body: StreamBuilder<
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
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Wallet could not be loaded:\n'
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

          final now = DateTime.now();

          double todayEarnings = 0;
          double weekEarnings = 0;
          double monthEarnings = 0;
          double lifetimeEarnings = 0;
          double pendingBalance = 0;
          double commissionPaid = 0;
         double totalPaidOut = 0;

          int completedOrders = 0;

          final completedOrderDocuments =
              <QueryDocumentSnapshot<
                  Map<String, dynamic>>>[];

          for (final document
              in snapshot.data?.docs ?? []) {
            final data = document.data();

            final paymentStatus =
                data['paymentStatus']
                        ?.toString() ??
                    '';

            if (paymentStatus != 'paid') {
              continue;
            }

            final status =
                data['status']?.toString() ?? '';

            final cookEarnings =
                _readCookEarnings(data);

            final platformCommission =
                _readPlatformCommission(data);

            if (status != 'completed') {
              if (status != 'rejected') {
                pendingBalance += cookEarnings;
              }

              continue;
            }

            final timestamp =
                data['completedAt'] ??
                data['updatedAt'] ??
                data['createdAt'];

            if (timestamp is! Timestamp) {
              continue;
            }

            final completedDate =
                timestamp.toDate();

            completedOrders++;
            lifetimeEarnings += cookEarnings;
            commissionPaid += platformCommission;
final String payoutStatus =
    data['payoutStatus']?.toString() ?? '';

if (payoutStatus == 'paid') {
  totalPaidOut += _readNumber(
    data,
    [
      'payoutAmount',
      'cookGrossEarnings',
    ],
  );
}
            completedOrderDocuments.add(
              document,
            );

            if (_isSameDay(
              completedDate,
              now,
            )) {
              todayEarnings += cookEarnings;
            }

            if (_isInCurrentWeek(
              completedDate,
              now,
            )) {
              weekEarnings += cookEarnings;
            }

            if (completedDate.year == now.year &&
                completedDate.month ==
                    now.month) {
              monthEarnings += cookEarnings;
            }
          }

          completedOrderDocuments.sort(
            (first, second) {
              final firstData = first.data();
              final secondData = second.data();

              final firstTimestamp =
                  firstData['completedAt'] ??
                  firstData['updatedAt'] ??
                  firstData['createdAt'];

              final secondTimestamp =
                  secondData['completedAt'] ??
                  secondData['updatedAt'] ??
                  secondData['createdAt'];

              if (firstTimestamp
                      is! Timestamp &&
                  secondTimestamp
                      is! Timestamp) {
                return 0;
              }

              if (firstTimestamp
                  is! Timestamp) {
                return 1;
              }

              if (secondTimestamp
                  is! Timestamp) {
                return -1;
              }

              return secondTimestamp.compareTo(
                firstTimestamp,
              );
            },
          );

        final double availableBalance =
    lifetimeEarnings - totalPaidOut;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(
                title: 'Available balance',
                value:
                    '£${availableBalance.toStringAsFixed(2)}',
                icon:
                    Icons.account_balance_wallet_rounded,
                subtitle:
                    'Completed paid orders',
              ),
              _buildSummaryCard(
  title: 'Paid out',
  value: '£${totalPaidOut.toStringAsFixed(2)}',
  icon: Icons.account_balance_rounded,
  subtitle: 'Recorded cook payouts',
),
              _buildSummaryCard(
                title: 'Pending balance',
                value:
                    '£${pendingBalance.toStringAsFixed(2)}',
                icon:
                    Icons.schedule_rounded,
                subtitle:
                    'Paid orders not yet completed',
              ),
              _buildSummaryCard(
                title: 'Today',
                value:
                    '£${todayEarnings.toStringAsFixed(2)}',
                icon: Icons.today_rounded,
              ),
              _buildSummaryCard(
                title: 'This week',
                value:
                    '£${weekEarnings.toStringAsFixed(2)}',
                icon:
                    Icons.date_range_rounded,
              ),
              _buildSummaryCard(
                title: 'This month',
                value:
                    '£${monthEarnings.toStringAsFixed(2)}',
                icon:
                    Icons.calendar_month_rounded,
              ),
              _buildSummaryCard(
                title: 'Lifetime earnings',
                value:
                    '£${lifetimeEarnings.toStringAsFixed(2)}',
                icon:
                    Icons.trending_up_rounded,
              ),
              _buildSummaryCard(
                title:
                    'HomeEats commission paid',
                value:
                    '£${commissionPaid.toStringAsFixed(2)}',
                icon:
                    Icons.percent_rounded,
              ),
              _buildSummaryCard(
                title: 'Completed orders',
                value:
                    completedOrders.toString(),
                icon:
                    Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 24),
              const Text(
                'Completed order history',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (completedOrderDocuments.isEmpty)
                const Card(
                  child: Padding(
                    padding:
                        EdgeInsets.all(18),
                    child: Text(
                      'No completed paid orders yet.',
                    ),
                  ),
                )
              else
                ...completedOrderDocuments.map(
                  (document) {
                    final data =
                        document.data();

                    final customerName =
                        data['customerName']
                                    ?.toString()
                                    .trim()
                                    .isNotEmpty ==
                                true
                            ? data['customerName']
                                .toString()
                                .trim()
                            : 'Customer';

                    final orderTotal =
                        _readOrderTotal(data);

                    final cookEarnings =
                        _readCookEarnings(data);

                    final timestamp =
                        data['completedAt'] ??
                        data['updatedAt'] ??
                        data['createdAt'];

                    final dateText =
                        timestamp is Timestamp
                            ? _formatDate(
                                timestamp.toDate(),
                              )
                            : 'Date unavailable';

                    final items =
                        data['items'] as List? ??
                            [];

                    final itemText =
                        items
                            .map((item) {
                              if (item
                                  is! Map) {
                                return '';
                              }

                              final quantity =
                                  item['quantity'] ??
                                      1;

                              final name =
                                  item['name'] ??
                                      item[
                                          'mealName'] ??
                                      'Item';

                              return '$quantity × '
                                  '$name';
                            })
                            .where(
                              (text) =>
                                  text.isNotEmpty,
                            )
                            .join(', ');

                    return Card(
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.receipt_long,
                          ),
                        ),
                        title:
                            Text(customerName),
                        subtitle: Text(
                          itemText.isEmpty
                              ? dateText
                              : '$itemText\n'
                                  '$dateText\n'
                                  'Order total: '
                                  '£${orderTotal.toStringAsFixed(2)}',
                        ),
                        isThreeLine:
                            itemText.isNotEmpty,
                        trailing: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'You earned',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '£${cookEarnings.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}