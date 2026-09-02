import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'order_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {

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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Notifications could not be loaded:\n'
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

          final notifications =
              snapshot.data?.docs.toList() ?? [];

          notifications.sort((first, second) {
            final firstTime =
                first.data()['createdAt'] as Timestamp?;

            final secondTime =
                second.data()['createdAt'] as Timestamp?;

            if (firstTime == null &&
                secondTime == null) {
              return 0;
            }

            if (firstTime == null) {
              return 1;
            }

            if (secondTime == null) {
              return -1;
            }

            return secondTime.compareTo(firstTime);
          });

          if (notifications.isEmpty) {
            return const Center(
              child: Text('No notifications yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final document = notifications[index];
              final data = document.data();

              final title =
                  data['title']?.toString() ??
                      'Notification';

              final message =
                  data['message']?.toString() ?? '';

              final isRead = data['isRead'] == true;

              final createdAt =
                  data['createdAt'] as Timestamp?;

              final dateText = createdAt == null
                  ? 'Date unavailable'
                  : _formatDate(createdAt.toDate());

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      isRead
                          ? Icons.notifications_none_rounded
                          : Icons
                              .notifications_active_rounded,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead
                          ? FontWeight.w600
                          : FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    '$message\n$dateText',
                  ),
                  isThreeLine: true,
                onTap: () async {
  final String orderId =
      data['orderId']?.toString() ?? '';

  if (!isRead) {
    await document.reference.update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  if (!context.mounted || orderId.isEmpty) {
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => OrderDetailsScreen(
        orderId: orderId,
      ),
    ),
  );
},
                ),
              );
            },
          );
        },
      ),
    );
  }
}