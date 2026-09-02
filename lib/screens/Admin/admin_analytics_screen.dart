import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

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

  Widget _buildAnalyticsCard({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Analytics'),
        centerTitle: true,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .snapshots(),
        builder: (context, ordersSnapshot) {
          if (ordersSnapshot.hasError) {
            return Center(
              child: Text(
                'Order analytics could not be loaded:\n'
                '${ordersSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!ordersSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final now = DateTime.now();

          double todaySales = 0;
          double todayCommission = 0;

          int paidOrdersToday = 0;
          int activeOrders = 0;
          int completedOrders = 0;

          for (final document
              in ordersSnapshot.data!.docs) {
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

            if (paymentStatus != 'paid') {
              continue;
            }

            if (status != 'completed' &&
                status != 'rejected') {
              activeOrders++;
            }

            final timestamp =
                data['paidAt'] ??
                data['createdAt'] ??
                data['updatedAt'];

            if (timestamp is! Timestamp) {
              continue;
            }

            final paidDate = timestamp.toDate();

            if (!_isSameDay(paidDate, now)) {
              continue;
            }

            paidOrdersToday++;

            todaySales += _readNumber(
              data,
              [
                'totalPaid',
                'total',
              ],
            );

            todayCommission += _readNumber(
              data,
              [
                'platformCommission',
              ],
            );
          }

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.hasError) {
                return Center(
                  child: Text(
                    'User analytics could not be loaded:\n'
                    '${usersSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!usersSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              int activeCooks = 0;
              int customers = 0;

              for (final document
                  in usersSnapshot.data!.docs) {
                final data = document.data();

                final role =
                    data['role']
                            ?.toString()
                            .toLowerCase() ??
                        '';

                final active =
                    data['active'] != false;

                if (role == 'cook' && active) {
                  activeCooks++;
                }

                if (role == 'customer' && active) {
                  customers++;
                }
              }

              return StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('meals')
                    .snapshots(),
                builder: (context, mealsSnapshot) {
                  if (mealsSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Meal analytics could not be loaded:\n'
                        '${mealsSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!mealsSnapshot.hasData) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  int liveMeals = 0;

                  for (final document
                      in mealsSnapshot.data!.docs) {
                    final data = document.data();

                    final active =
                        data['active'] == true;

                    final status =
                        data['status']
                                ?.toString()
                                .toLowerCase() ??
                            '';

                    if (active &&
                        status != 'unavailable') {
                      liveMeals++;
                    }
                  }

                  return ListView(
                    padding:
                        const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAnalyticsCard(
                        title: 'Sales today',
                        value:
                            '£${todaySales.toStringAsFixed(2)}',
                        icon:
                            Icons.payments_rounded,
                      ),
                      _buildAnalyticsCard(
                        title:
                            'HomeEats commission today',
                        value:
                            '£${todayCommission.toStringAsFixed(2)}',
                        icon:
                            Icons.percent_rounded,
                      ),
                      _buildAnalyticsCard(
                        title: 'Paid orders today',
                        value:
                            paidOrdersToday.toString(),
                        icon:
                            Icons.receipt_long_rounded,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Platform',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAnalyticsCard(
                        title: 'Active orders',
                        value:
                            activeOrders.toString(),
                        icon:
                            Icons.local_dining_rounded,
                      ),
                      _buildAnalyticsCard(
                        title: 'Completed orders',
                        value:
                            completedOrders.toString(),
                        icon:
                            Icons.task_alt_rounded,
                      ),
                      _buildAnalyticsCard(
                        title: 'Active cooks',
                        value:
                            activeCooks.toString(),
                        icon:
                            Icons.restaurant_rounded,
                      ),
                      _buildAnalyticsCard(
                        title: 'Customers',
                        value:
                            customers.toString(),
                        icon:
                            Icons.people_rounded,
                      ),
                      _buildAnalyticsCard(
                        title: 'Live meals',
                        value:
                            liveMeals.toString(),
                        icon:
                            Icons.restaurant_menu_rounded,
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}