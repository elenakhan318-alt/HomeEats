import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_business_settings_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_cook_verifications_screen.dart';
import 'admin_finance_screen.dart';
import 'admin_meals_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_payouts_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final bool? shouldSignOut =
                  await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Sign out'),
                    content: const Text(
                      'Are you sure you want to sign out?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            dialogContext,
                          ).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(
                            dialogContext,
                          ).pop(true);
                        },
                        child: const Text('Sign out'),
                      ),
                    ],
                  );
                },
              );

              if (shouldSignOut == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
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
                    builder: (_) =>
                        const AdminUsersScreen(),
                  ),
                );
              },
            ),
            _AdminCard(
              icon: Icons.verified_user_rounded,
              title: 'Cook Verifications',
              subtitle: 'Review applications',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminCookVerificationsScreen(),
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
                    builder: (_) =>
                        const AdminOrdersScreen(),
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
                    builder: (_) =>
                        const AdminMealsScreen(),
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
                    builder: (_) =>
                        const AdminComplaintsScreen(),
                  ),
                );
              },
            ),
            _AdminCard(
              icon: Icons.settings_rounded,
              title: 'Business Settings',
              subtitle: 'Fees and commission',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminBusinessSettingsScreen(),
                  ),
                );
              },
            ),
            _AdminCard(
              icon: Icons.account_balance_rounded,
              title: 'Finance',
              subtitle: 'Revenue and payouts',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminFinanceScreen(),
                  ),
                );
              },
            ),
            _AdminCard(
  icon: Icons.analytics_rounded,
  title: 'Analytics',
  subtitle: 'Platform overview',
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const AdminAnalyticsScreen(),
      ),
    );
  },
),
_AdminCard(
  icon: Icons.payments_rounded,
  title: 'Payouts',
  subtitle: 'Manage cook payments',
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const AdminPayoutsScreen(),
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
                textAlign: TextAlign.center,
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