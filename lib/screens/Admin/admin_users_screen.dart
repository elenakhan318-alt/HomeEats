import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('email')
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

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(
              child: Text('No users found'),
            );
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user =
                  users[index].data() as Map<String, dynamic>;

              final email = user['email'] ?? 'No email';
final role = user['role'] ?? 'Unknown';
final uid = user['uid'] ?? '';

              return ListTile(
  trailing: PopupMenuButton<String>(
   onSelected: (value) {
  if (value == 'View') {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('User Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: $email'),
              const SizedBox(height: 8),
              Text('Role: $role'),
              const SizedBox(height: 8),
              Text('UID: $uid'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  if (value == 'Change Role') {
  if (role == 'admin') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The admin account role cannot be changed.'),
      ),
    );
    return;
  }
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Customer'),
                onTap: () async {
                  await users[index].reference.update({
                    'role': 'customer',
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              ListTile(
                title: const Text('Cook'),
                onTap: () async {
                  await users[index].reference.update({
                    'role': 'cook',
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              ListTile(
                title: const Text('Admin'),
                onTap: () async {
                  await users[index].reference.update({
                    'role': 'admin',
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
},
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: 'View',
        child: Text('View'),
      ),
      PopupMenuItem(
        value: 'Change Role',
        child: Text('Change Role'),
      ),
      PopupMenuItem(
        value: 'Delete',
        child: Text('Delete'),
      ),
    ],
  ),
                leading: CircleAvatar(
  child: Icon(
    role == 'admin'
        ? Icons.admin_panel_settings
        : role == 'cook'
            ? Icons.restaurant
            : Icons.person,
  ),
),
                title: Text(email),
              subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(role),
    Text(
      uid,
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