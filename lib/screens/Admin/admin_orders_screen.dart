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

          if (snapshot.connectionState == ConnectionState.waiting) {
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
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order =
                  orders[index].data() as Map<String, dynamic>;

            final status = order['status'] ?? 'Unknown';
final total = order['total'] ?? 0;
final customer = order['customerName'] ?? 'Unknown customer';

final createdAt = order['createdAt'] as Timestamp?;

final placedAt = createdAt == null
    ? 'No date recorded'
    : DateFormat('dd MMM yyyy • HH:mm').format(
        createdAt.toDate(),
      );

              return ListTile(
  onTap: () {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: $customer'),
              const SizedBox(height: 8),
              Text('Total: £$total'),
              const SizedBox(height: 8),
            Text('Status: $status'),
const SizedBox(height: 8),
Text('Placed: $placedAt'),
const SizedBox(height: 8),
Text('Order ID: ${orders[index].id}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  },
                leading: const Icon(Icons.receipt_long),
              title: Text(customer),
subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('£$total • $status'),
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