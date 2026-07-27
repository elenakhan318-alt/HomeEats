import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CookEarningsScreen extends StatelessWidget {
  const CookEarningsScreen({super.key});

  double _readOrderTotal(Map<String, dynamic> data) {
    final possibleValues = [
      data['total'],
      data['totalAmount'],
      data['grandTotal'],
      data['orderTotal'],
    ];

    for (final value in possibleValues) {
      if (value is num) {
        return value.toDouble();
      }

      final parsed = double.tryParse(value?.toString() ?? '');

      if (parsed != null) {
        return parsed;
      }
    }

    return 0;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isInCurrentWeek(DateTime date, DateTime now) {
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

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              icon,
              size: 34,
              color: Colors.amber,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in again.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where(
              'status',
              isEqualTo: 'completed',
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Earnings could not be loaded: '
                '${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final now = DateTime.now();

          double todayEarnings = 0;
          double weekEarnings = 0;
          double monthEarnings = 0;
          double totalEarnings = 0;
          int completedOrders = 0;

          for (final document in snapshot.data!.docs) {
            final data = document.data();

            final cookIdsValue = data['cookIds'];

            final belongsToCook =
                cookIdsValue is List &&
                    cookIdsValue
                        .map((value) => value.toString())
                        .contains(user.uid);

            if (!belongsToCook) {
              continue;
            }

            final total = _readOrderTotal(data);

            final timestamp =
                data['completedAt'] ??
                data['updatedAt'] ??
                data['createdAt'];

            if (timestamp is! Timestamp) {
              continue;
            }

            final completedDate = timestamp.toDate();

            completedOrders++;
            totalEarnings += total;

            if (_isSameDay(completedDate, now)) {
              todayEarnings += total;
            }

            if (_isInCurrentWeek(completedDate, now)) {
              weekEarnings += total;
            }

            if (completedDate.year == now.year &&
                completedDate.month == now.month) {
              monthEarnings += total;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(
                title: 'Today',
                value:
                    '£${todayEarnings.toStringAsFixed(2)}',
                icon: Icons.today,
              ),
              _buildSummaryCard(
                title: 'This week',
                value:
                    '£${weekEarnings.toStringAsFixed(2)}',
                icon: Icons.date_range,
              ),
              _buildSummaryCard(
                title: 'This month',
                value:
                    '£${monthEarnings.toStringAsFixed(2)}',
                icon: Icons.calendar_month,
              ),
              _buildSummaryCard(
                title: 'Total earnings',
                value:
                    '£${totalEarnings.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet,
              ),
              _buildSummaryCard(
                title: 'Completed orders',
                value: completedOrders.toString(),
                icon: Icons.check_circle_outline,
              ),
            ],
          );
        },
      ),
    );
  }
}