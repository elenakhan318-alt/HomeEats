import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPayoutsScreen extends StatelessWidget {
  const AdminPayoutsScreen({super.key});

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

  Future<void> _markAsPaid({
    required BuildContext context,
    required DocumentReference<
        Map<String, dynamic>> orderReference,
    required double amount,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mark payout as paid'),
          content: Text(
            'Confirm that £${amount.toStringAsFixed(2)} '
            'has been paid to the cook by bank transfer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Confirm paid'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await orderReference.update({
        'payoutStatus': 'paid',
        'payoutAmount': amount,
        'payoutPaidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cook payout marked as paid.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payout could not be updated: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cook Payouts'),
        centerTitle: true,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Payouts could not be loaded:\n'
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

          final pendingOrders =
              snapshot.data?.docs.where((document) {
                    final data = document.data();

                    final paymentStatus =
                        data['paymentStatus']
                                ?.toString() ??
                            '';

                    final payoutStatus =
                        data['payoutStatus']
                                ?.toString() ??
                            'pending';

                    return paymentStatus == 'paid' &&
                        payoutStatus != 'paid';
                  }).toList() ??
                  [];

          final paidOrders =
              snapshot.data?.docs.where((document) {
                    final data = document.data();

                    return data['paymentStatus']
                                ?.toString() ==
                            'paid' &&
                        data['payoutStatus']
                                ?.toString() ==
                            'paid';
                  }).toList() ??
                  [];

          double pendingTotal = 0;
          double paidTotal = 0;

          for (final document in pendingOrders) {
            pendingTotal += _readNumber(
              document.data(),
              [
                'cookGrossEarnings',
                'total',
              ],
            );
          }

          for (final document in paidOrders) {
            paidTotal += _readNumber(
              document.data(),
              [
                'payoutAmount',
                'cookGrossEarnings',
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.schedule_rounded),
                  ),
                  title: const Text('Pending payouts'),
                  subtitle: Text(
                    '${pendingOrders.length} completed orders',
                  ),
                  trailing: Text(
                    '£${pendingTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.task_alt_rounded),
                  ),
                  title: const Text('Total paid out'),
                  subtitle: Text(
                    '${paidOrders.length} recorded payouts',
                  ),
                  trailing: Text(
                    '£${paidTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Awaiting payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (pendingOrders.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'There are no pending cook payouts.',
                    ),
                  ),
                )
              else
                ...pendingOrders.map((document) {
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

                  final cookIds =
                      data['cookIds'] is List
                          ? List<String>.from(
                              (data['cookIds'] as List)
                                  .map(
                                    (value) =>
                                        value.toString(),
                                  ),
                            )
                          : <String>[];

                  final cookEarnings = _readNumber(
                    data,
                    [
                      'cookGrossEarnings',
                      'total',
                    ],
                  );

                  final timestamp =
                      data['completedAt'] ??
                      data['updatedAt'];

                  final dateText =
                      timestamp is Timestamp
                          ? _formatDate(
                              timestamp.toDate(),
                            )
                          : 'Date unavailable';

                  return Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(
                                  Icons.account_balance_wallet,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    Text(dateText),
                                  ],
                                ),
                              ),
                              Text(
                                '£${cookEarnings.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cookIds.isEmpty
                                ? 'Cook ID unavailable'
                                : 'Cook ID: ${cookIds.first}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                _markAsPaid(
                                  context: context,
                                  orderReference:
                                      document.reference,
                                  amount: cookEarnings,
                                );
                              },
                              icon: const Icon(
                                Icons.check_rounded,
                              ),
                              label: const Text(
                                'Mark as Paid',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              const Text(
                'Payout history',
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
                      'No payouts have been recorded.',
                    ),
                  ),
                )
              else
                ...paidOrders.map((document) {
                  final data = document.data();

                  final payoutAmount = _readNumber(
                    data,
                    [
                      'payoutAmount',
                      'cookGrossEarnings',
                    ],
                  );

                  final timestamp =
                      data['payoutPaidAt'];

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
                          Icons.check_rounded,
                        ),
                      ),
                      title: Text(
                        '£${payoutAmount.toStringAsFixed(2)}',
                      ),
                      subtitle: Text(
                        'Paid $dateText',
                      ),
                      trailing: const Text(
                        'PAID',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}