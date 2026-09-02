import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin_dashboard_screen.dart';
import '../cook/cook_dashboard_screen.dart';
import '../cook/cook_verification_screen.dart';
import '../cook/cook_verification_status_screen.dart';
import '../customer/customer_main_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
    stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (authSnapshot.hasError) {
          return const _AuthErrorScreen(
            message:
                'We could not check your login status.',
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const WelcomeScreen();
        }

        return StreamBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (profileSnapshot.hasError) {
              debugPrint(
                'Profile loading error: '
                '${profileSnapshot.error}',
              );

              return const _AuthErrorScreen(
                message:
                    'We could not load your account.',
              );
            }

            final profileDocument =
                profileSnapshot.data;

            if (profileDocument == null ||
                !profileDocument.exists) {
              debugPrint(
                'No users document found for UID: '
                '${user.uid}',
              );

              return const _AuthErrorScreen(
                message:
                    'Your account profile could not be found.',
              );
            }

            final profile = profileDocument.data();

            if (profile == null) {
              return const _AuthErrorScreen(
                message:
                    'Your account profile is empty.',
              );
            }

            final role = profile['role']
                ?.toString()
                .trim()
                .toLowerCase();

            final isActive =
                profile['active'] != false;

            final verificationStatus =
                profile['verificationStatus']
                    ?.toString()
                    .trim()
                    .toLowerCase();

            debugPrint(
              'Logged in email: ${user.email}',
            );
            debugPrint(
              'Logged in UID: ${user.uid}',
            );
            debugPrint('Profile role: $role');
            debugPrint(
              'Account active: $isActive',
            );
            debugPrint(
              'Verification status: '
              '$verificationStatus',
            );

            if (!isActive) {
              return const _AuthErrorScreen(
                message:
                    'Your account is currently inactive.',
              );
            }
if ((role == 'customer' || role == 'cook') &&
    !user.emailVerified) {
  return _EmailVerificationScreen(
    email: user.email ?? '',
  );
}
            switch (role) {
              case 'admin':
                return const AdminDashboardScreen();

              case 'cook':
                return _buildCookScreen(
                  verificationStatus,
                );

              case 'customer':
                return const CustomerMainScreen();

              default:
                return _AuthErrorScreen(
                  message:
                      'Your account role is not recognised: '
                      '${role ?? 'missing'}',
                );
            }
          },
        );
      },
    );
  }

  Widget _buildCookScreen(
    String? verificationStatus,
  ) {
    switch (verificationStatus) {
      case 'approved':
        return const CookDashboardScreen();
case 'awaiting_contact':
      case 'pending':
      case 'changes_requested':
      case 'rejected':
        return _CookApplicationStatusLoader(
          status: verificationStatus!,
        );

      case 'draft':
      case null:
      case '':
        return const CookVerificationScreen();

      default:
        return const CookVerificationScreen();
    }
  }
}

class _CookApplicationStatusLoader
    extends StatelessWidget {
  const _CookApplicationStatusLoader({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('cookApplications')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final application =
            snapshot.data?.data();

        final reviewNotes =
            application?['reviewNotes']
                ?.toString()
                .trim();

        return CookVerificationStatusScreen(
          status: status,
          reviewNotes: reviewNotes,
        );
      },
    );
  }
}
class _EmailVerificationScreen
    extends StatefulWidget {
  const _EmailVerificationScreen({
    required this.email,
  });

  final String email;

  @override
  State<_EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<_EmailVerificationScreen> {
  bool _checking = false;
  bool _sending = false;

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
    });

    try {
      final currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        return;
      }

      await currentUser.reload();

      final refreshedUser =
          FirebaseAuth.instance.currentUser;

      if (refreshedUser?.emailVerified == true) {
        _showMessage(
          'Email verified successfully.',
        );
      } else {
        _showMessage(
          'Your email is not verified yet. '
          'Please open the verification link '
          'we sent you, then try again.',
        );
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(
        error.message ??
            'We could not check your email verification.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      _sending = true;
    });

    try {
      final currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        return;
      }

      if (currentUser.emailVerified) {
        _showMessage(
          'Your email is already verified.',
        );
        return;
      }

      await currentUser.sendEmailVerification();

      _showMessage(
        'A new verification email has been sent.',
      );
    } on FirebaseAuthException catch (error) {
      _showMessage(
        error.message ??
            'The verification email could not be sent.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_unread_rounded,
                  size: 72,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification link to\n'
                  '${widget.email}\n\n'
                  'Open the link in your email, '
                  'then return to HomeEats.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _checking
                            ? null
                            : _checkVerification,
                    child: Text(
                      _checking
                          ? 'Checking...'
                          : 'I have verified my email',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      _sending
                          ? null
                          : _resendVerification,
                  child: Text(
                    _sending
                        ? 'Sending...'
                        : 'Resend verification email',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance
                        .signOut();
                  },
                  child: const Text(
                    'Return to sign in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                    await FirebaseAuth.instance
                        .signOut();
                  },
                  child: const Text(
                    'Return to sign in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}