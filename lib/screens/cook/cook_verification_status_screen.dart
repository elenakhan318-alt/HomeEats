import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cook_verification_screen.dart';

class CookVerificationStatusScreen extends StatelessWidget {
  const CookVerificationStatusScreen({
    super.key,
    required this.status,
    this.reviewNotes,
  });

  final String status;
  final String? reviewNotes;

  @override
  Widget build(BuildContext context) {

  debugPrint('COOK STATUS RECEIVED: "$status"');

final details = _detailsForStatus(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cook verification'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 560,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        details.icon,
                        size: 72,
                        color: details.color,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        details.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        details.message,
                        textAlign: TextAlign.center,
                      ),
                      if (reviewNotes != null &&
                          reviewNotes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin review notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(reviewNotes!.trim()),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (status == 'changes_requested')
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CookVerificationScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.edit_rounded,
                            ),
                            label: const Text(
                              'Update application',
                            ),
                          ),
                        ),
                      if (status == 'rejected')
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await FirebaseAuth.instance
                                  .signOut();
                            },
                            icon: const Icon(
                              Icons.logout_rounded,
                            ),
                            label: const Text('Sign out'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _VerificationStatusDetails _detailsForStatus(
  String status,
) {
  switch (status) {
    case 'awaiting_contact':
      return const _VerificationStatusDetails(
        title: 'Thanks — we’ve received your details',
        message:
            'Your first step is complete. '
            'A member of the HomeEats team will contact you '
            'to discuss the next stage of becoming a HomeEats cook. '
            'You do not need to upload any documents yet. '
            'We will let you know when your account is ready '
            'to continue to the next stage.',
        icon: Icons.phone_in_talk_rounded,
        color: Colors.orange,
      );
    case 'pending':
      return const _VerificationStatusDetails(
          title: 'Application under review',
          message:
              'Your verification application has been submitted. '
              'You will receive access to the cook dashboard after '
              'an administrator approves your application.',
          icon: Icons.schedule_rounded,
          color: Colors.orange,
        );

      case 'changes_requested':
        return const _VerificationStatusDetails(
          title: 'Changes required',
          message:
              'An administrator has requested changes to your '
              'verification application. Review the notes below '
              'and update your application.',
          icon: Icons.edit_note_rounded,
          color: Colors.blue,
        );

      case 'rejected':
        return const _VerificationStatusDetails(
          title: 'Application rejected',
          message:
              'Your cook verification application was not approved. '
              'Review the administrator’s notes below.',
          icon: Icons.cancel_rounded,
          color: Colors.red,
        );

      default:
        return const _VerificationStatusDetails(
          title: 'Verification required',
          message:
              'Complete your cook verification application before '
              'accessing the cook dashboard.',
          icon: Icons.verified_user_outlined,
          color: Colors.orange,
        );
    }
  }
}

class _VerificationStatusDetails {
  const _VerificationStatusDetails({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}