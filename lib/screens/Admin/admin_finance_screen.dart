import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

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

  bool _isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Widget _buildFinanceCard({
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
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Dashboard'),
        centerTitle: true,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Finance data could not be loaded:\n'
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

          double todaySales = 0;
          double todayCommission = 0;
          double todayCookEarnings = 0;

          double lifetimeSales = 0;
          double lifetimeCommission = 0;
          double lifetimeCookEarnings = 0;

          double pendingCookPayouts = 0;

          int todayPaidOrders = 0;
          int totalPaidOrders = 0;
          int activeOrders = 0;
          int completedOrders = 0;
          int rejectedOrders = 0;

          final paidOrders =
              <QueryDocumentSnapshot<
                  Map<String, dynamic>>>[];

          for (final document
              in snapshot.data?.docs ?? []) {
            final data = document.data();

            final paymentStatus =
                data['paymentStatus']
                        ?.toString() ??
                    '';

            final status =
                data['status']?.toString() ?? '';

            if (status == 'completed') {
              completedOrders++;
            }

            if (status == 'rejected') {
              rejectedOrders++;
            }

            if (paymentStatus != 'paid') {
              continue;
            }

            totalPaidOrders++;
            paidOrders.add(document);

            if (status != 'completed' &&
                status != 'rejected') {
              activeOrders++;
            }

            final totalPaid = _readNumber(
              data,
              [
                'totalPaid',
                'total',
              ],
            );

            final platformCommission = _readNumber(
              data,
              [
                'platformCommission',
              ],
            );

            final cookEarnings = _readNumber(
              data,
              [
                'cookGrossEarnings',
              ],
            );

            lifetimeSales += totalPaid;
            lifetimeCommission += platformCommission;
            lifetimeCookEarnings += cookEarnings;

            if (status == 'completed') {
              pendingCookPayouts += cookEarnings;
            }

            final timestamp =
                data['paidAt'] ??
                data['createdAt'] ??
                data['updatedAt'];

            if (timestamp is Timestamp) {
              final paidDate = timestamp.toDate();

              if (_isSameDay(paidDate, now)) {
                todayPaidOrders++;
                todaySales += totalPaid;
                todayCommission += platformCommission;
                todayCookEarnings += cookEarnings;
              }
            }
          }

          paidOrders.sort((first, second) {
            final firstData = first.data();
            final secondData = second.data();

            final firstTimestamp =
                firstData['paidAt'] ??
                firstData['createdAt'] ??
                firstData['updatedAt'];

            final secondTimestamp =
                secondData['paidAt'] ??
                secondData['createdAt'] ??
                secondData['updatedAt'];

            if (firstTimestamp is! Timestamp &&
                secondTimestamp is! Timestamp) {
              return 0;
            }

            if (firstTimestamp is! Timestamp) {
              return 1;
            }

            if (secondTimestamp is! Timestamp) {
              return -1;
            }

            return secondTimestamp.compareTo(
              firstTimestamp,
            );
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Today',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _buildFinanceCard(
                title: 'Sales',
                value:
                    '£${todaySales.toStringAsFixed(2)}',
                icon: Icons.payments_rounded,
              ),
              _buildFinanceCard(
                title: 'HomeEats commission',
                value:
                    '£${todayCommission.toStringAsFixed(2)}',
                icon: Icons.percent_rounded,
              ),
              _buildFinanceCard(
                title: 'Cook earnings',
                value:
                    '£${todayCookEarnings.toStringAsFixed(2)}',
                icon:
                    Icons.account_balance_wallet_rounded,
              ),
              _buildFinanceCard(
                title: 'Paid orders',
                value: todayPaidOrders.toString(),
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(height: 24),
              const Text(
                'Platform totals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _buildFinanceCard(
                title: 'Lifetime sales',
                value:
                    '£${lifetimeSales.toStringAsFixed(2)}',
                icon: Icons.trending_up_rounded,
              ),
              _buildFinanceCard(
                title: 'Lifetime commission',
                value:
                    '£${lifetimeCommission.toStringAsFixed(2)}',
                icon: Icons.savings_rounded,
              ),
              _buildFinanceCard(
                title: 'Lifetime cook earnings',
                value:
                    '£${lifetimeCookEarnings.toStringAsFixed(2)}',
                icon: Icons.groups_rounded,
              ),
              _buildFinanceCard(
                title: 'Pending cook payouts',
                value:
                    '£${pendingCookPayouts.toStringAsFixed(2)}',
                icon: Icons.schedule_rounded,
                subtitle:
                    'Completed orders not yet marked as paid out',
              ),
              _buildFinanceCard(
                title: 'Total paid orders',
                value: totalPaidOrders.toString(),
                icon: Icons.check_circle_rounded,
              ),
              _buildFinanceCard(
                title: 'Active orders',
                value: activeOrders.toString(),
                icon: Icons.local_dining_rounded,
              ),
              _buildFinanceCard(
                title: 'Completed orders',
                value: completedOrders.toString(),
                icon: Icons.task_alt_rounded,
              ),
              _buildFinanceCard(
                title: 'Rejected orders',
                value: rejectedOrders.toString(),
                icon: Icons.cancel_outlined,
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent paid orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (paidOrders.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No paid orders yet.',
                    ),
                  ),
                )
              else
                ...paidOrders.take(10).map(
                  (document) {
                    final data = document.data();

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

                    final totalPaid = _readNumber(
                      data,
                      [
                        'totalPaid',
                        'total',
                      ],
                    );

                    final commission = _readNumber(
                      data,
                      [
                        'platformCommission',
                      ],
                    );

                    final status =
                        data['status']?.toString() ??
                            'pending';

                    final timestamp =
                        data['paidAt'] ??
                        data['createdAt'] ??
                        data['updatedAt'];

                    final dateText =
                        timestamp is Timestamp
                            ? _formatDate(
                                timestamp.toDate(),
                              )
                            : 'Date unavailable';

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.receipt_long,
                          ),
                        ),
                        title: Text(customerName),
                        subtitle: Text(
                          '$dateText\n'
                          '${status.toUpperCase()}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              '£${totalPaid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Commission '
                              '£${commission.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
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