import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders found'),
            );
          }

          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final order =
                  orders[index].data()
                      as Map<String, dynamic>;

              final status =
                  order['status']?.toString() ??
                      'Unknown';

              final paymentStatus =
                  order['paymentStatus']
                          ?.toString() ??
                      'Unknown';

              final total =
                  (order['total'] as num?)
                          ?.toDouble() ??
                      0;

              final subtotal =
                  (order['subtotal'] as num?)
                          ?.toDouble() ??
                      0;

              final deliveryFee =
                  (order['deliveryFee'] as num?)
                          ?.toDouble() ??
                      0;

              final customer =
                  order['customerName']
                          ?.toString() ??
                      'Unknown customer';

              final customerEmail =
                  order['customerEmail']
                          ?.toString() ??
                      '';

              final customerPhone =
                  order['customerPhone']
                          ?.toString() ??
                      '';

              final fulfilmentType =
                  order['fulfilmentType']
                          ?.toString() ??
                      '';

              final deliveryAddress =
                  order['deliveryAddress']
                          ?.toString() ??
                      '';

              final notes =
                  order['notes']?.toString() ??
                      '';

              final createdAt =
                  order['createdAt']
                      as Timestamp?;

              final placedAt =
                  createdAt == null
                      ? 'No date recorded'
                      : DateFormat(
                          'dd MMM yyyy • HH:mm',
                        ).format(
                          createdAt.toDate(),
                        );

              final items =
                  order['items'] as List? ?? [];

              final cookIds =
                  order['cookIds'] as List? ??
                      [];

              final mealLines =
                  items.map((item) {
                if (item is! Map) {
                  return '';
                }

                final quantity =
                    item['quantity'] ?? 1;

                final name =
                    item['name'] ?? 'Meal';

                final cook =
                    item['cook'] ?? '';

                final unitPrice =
                    (item['unitPrice'] as num?)
                            ?.toDouble() ??
                        0;

                final cookText =
                    cook.toString().trim().isEmpty
                        ? ''
                        : ' • $cook';

                return '$quantity × $name$cookText'
                    ' • £${unitPrice.toStringAsFixed(2)} each';
              }).where(
                (text) => text.isNotEmpty,
              ).toList();

              return ListTile(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (
                      dialogContext,
                    ) {
                      return AlertDialog(
                        title: const Text(
                          'Order Details',
                        ),
                        content:
                            SingleChildScrollView(
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Customer: $customer',
                              ),

                              if (customerEmail
                                  .isNotEmpty) ...[
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  'Email: $customerEmail',
                                ),
                              ],

                              if (customerPhone
                                  .isNotEmpty) ...[
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  'Phone: $customerPhone',
                                ),
                              ],

                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                'Status: $status',
                              ),

                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                'Payment: $paymentStatus',
                              ),

                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                'Placed: $placedAt',
                              ),

                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                'Order ID: ${orders[index].id}',
                              ),

                              if (cookIds
                                  .isNotEmpty) ...[
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  'Cook ID: ${cookIds.join(', ')}',
                                ),
                              ],

                              const Divider(
                                height: 24,
                              ),

                              const Text(
                                'Items',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              if (mealLines.isEmpty)
                                const Text(
                                  'No meal details recorded.',
                                )
                              else
                                ...mealLines.map(
                                  (line) => Padding(
                                    padding:
                                        const EdgeInsets.only(
                                      bottom: 6,
                                    ),
                                    child: Text(line),
                                  ),
                                ),

                              const Divider(
                                height: 24,
                              ),

                              if (fulfilmentType
                                  .isNotEmpty)
                                Text(
                                  'Fulfilment: ${fulfilmentType.toUpperCase()}',
                                ),

                              if (fulfilmentType ==
                                      'delivery' &&
                                  deliveryAddress
                                      .isNotEmpty) ...[
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  'Delivery address: $deliveryAddress',
                                ),
                              ],

                              if (notes
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  'Order notes: $notes',
                                ),
                              ],

                              const Divider(
                                height: 24,
                              ),

                              Text(
                                'Subtotal: £${subtotal.toStringAsFixed(2)}',
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                fulfilmentType ==
                                        'delivery'
                                    ? 'Delivery fee: £${deliveryFee.toStringAsFixed(2)}'
                                    : 'Delivery fee: £0.00',
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                'Total: £${total.toStringAsFixed(2)}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(
                              dialogContext,
                            ),
                            child: const Text(
                              'Close',
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                leading: const Icon(
                  Icons.receipt_long,
                ),
                title: Text(customer),
                subtitle: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '£${total.toStringAsFixed(2)} • $status',
                    ),
                    Text(
                      placedAt,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}