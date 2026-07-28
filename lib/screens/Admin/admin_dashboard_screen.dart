import 'package:flutter/material.dart';

import 'admin_users_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_meals_screen.dart';
import 'admin_complaints_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _AdminCard(
              icon: Icons.people_rounded,
              title: 'Users',
              subtitle: 'Manage accounts',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminUsersScreen(),
                  ),
                );
              },
            ),
            _AdminCard(
  icon: Icons.receipt_long_rounded,
  title: 'Orders',
  subtitle: 'View all orders',
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdminOrdersScreen(),
      ),
    );
  },
),
          _AdminCard(
  icon: Icons.restaurant_menu_rounded,
  title: 'Meals',
  subtitle: 'Manage listings',
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdminMealsScreen(),
      ),
    );
  },
),
          _AdminCard(
  icon: Icons.report_problem_rounded,
  title: 'Complaints',
  subtitle: 'Review reports',
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdminComplaintsScreen(),
      ),
    );
  },
),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}