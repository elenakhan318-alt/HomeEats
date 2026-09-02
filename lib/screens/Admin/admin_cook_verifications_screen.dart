import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_cook_verification_review_screen.dart';

class AdminCookVerificationsScreen extends StatelessWidget {
  const AdminCookVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cook Verifications'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
    .collection('cookApplications')
    .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load cook applications.\n\n'
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

         final allApplications = snapshot.data?.docs ?? [];

final applications = allApplications.where((application) {
  final data = application.data();

  final verificationStatus =
      data['verificationStatus']
          ?.toString()
          .trim()
          .toLowerCase();

  final onboardingStatus =
      data['onboardingStatus']
          ?.toString()
          .trim()
          .toLowerCase();

  final hygieneRatingReviewStatus =
    data['foodHygieneRatingReviewStatus']
        ?.toString()
        .trim()
        .toLowerCase();

if (verificationStatus == 'approved' &&
    hygieneRatingReviewStatus != 'pending_review') {
  return false;
}

 return onboardingStatus == 'awaiting_contact' ||
    verificationStatus == 'pending' ||
    verificationStatus == 'changes_requested' ||
    verificationStatus == 'draft' ||
    verificationStatus == 'documents_required' ||
    verificationStatus == 'rejected' ||
    hygieneRatingReviewStatus == 'pending_review';
}).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              final data = application.data();

              final businessName =
                  data['businessName']?.toString().trim();

              final phone =
                  data['phone']?.toString().trim();

              final localAuthority =
                  data['localAuthority']?.toString().trim();
                  final verificationStatus =
    data['verificationStatus']
        ?.toString()
        .trim()
        .toLowerCase();

final onboardingStatus =
    data['onboardingStatus']
        ?.toString()
        .trim()
        .toLowerCase();

final hygieneRatingReviewStatus =
    data['foodHygieneRatingReviewStatus']
        ?.toString()
        .trim()
        .toLowerCase();

String statusLabel;

if (hygieneRatingReviewStatus == 'pending_review') {
  statusLabel = 'Food hygiene rating review';
} else if (onboardingStatus == 'awaiting_contact') {
  statusLabel = 'Awaiting contact';
} else if (verificationStatus == 'documents_required') {
  statusLabel = 'Documents unlocked';
} else if (verificationStatus == 'pending') {
  statusLabel = 'Pending review';
} else if (verificationStatus == 'changes_requested') {
  statusLabel = 'Changes requested';
} else if (verificationStatus == 'rejected') {
  statusLabel = 'Rejected';
} else {
  statusLabel = 'In progress';
}

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.restaurant_rounded,
                    ),
                  ),
                  title: Text(
                    businessName == null ||
                            businessName.isEmpty
                        ? 'Unnamed cook business'
                        : businessName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          phone == null || phone.isEmpty
                              ? 'Phone: Not provided'
                              : 'Phone: $phone',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localAuthority == null ||
                                  localAuthority.isEmpty
                              ? 'Local authority: Not provided'
                              : 'Local authority: '
                                  '$localAuthority',
                        ),
                        const SizedBox(height: 8),
                        Row(
  children: [
    const Icon(
      Icons.schedule_rounded,
      size: 18,
    ),
    const SizedBox(width: 6),
    Text(
      statusLabel,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ],
),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                onTap: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          AdminCookVerificationReviewScreen(
        cookId: application.id,
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