import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../cook/cook_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../customer/customer_main_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const WelcomeScreen();
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (profileSnapshot.hasError) {
              return const _AuthErrorScreen(
                message: 'We could not load your account.',
              );
            }

            final profile = profileSnapshot.data?.data();

            if (profile == null) {
              return const _AuthErrorScreen(
                message: 'Your account profile could not be found.',
              );
            }

            final role = profile['role'] as String?;
            debugPrint('Logged in email: ${user.email}');
debugPrint('Role: $role');
if (role == 'admin') {
  return const AdminDashboardScreen();
}

if (role == 'cook') {
  return const CookDashboardScreen();
}

if (role == 'customer') {
  return const CustomerMainScreen();
}

return const _AuthErrorScreen(
  message: 'Your account role is not recognised.',
);
            return const _AuthErrorScreen(
              message: 'Your account role is not recognised.',
            );
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: const Text('Return to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}