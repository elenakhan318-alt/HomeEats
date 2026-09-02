import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminCookVerificationReviewScreen extends StatefulWidget {
  const AdminCookVerificationReviewScreen({
    super.key,
    required this.cookId,
  });

  final String cookId;

  @override
  State<AdminCookVerificationReviewScreen> createState() =>
      _AdminCookVerificationReviewScreenState();
}

class _AdminCookVerificationReviewScreenState
    extends State<AdminCookVerificationReviewScreen> {
  final TextEditingController _reviewNotesController =
      TextEditingController();

  bool _isUpdating = false;

  @override
  void dispose() {
    _reviewNotesController.dispose();
    super.dispose();
  }

  Future<void> _updateVerificationStatus(
    String newStatus,
  ) async {
    if (_isUpdating) {
      return;
    }

    if (newStatus == 'changes_requested' &&
        _reviewNotesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a reason before requesting changes.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final adminUser = FirebaseAuth.instance.currentUser;

      if (adminUser == null) {
        throw Exception(
          'Admin account is not signed in.',
        );
      }

      final applicationReference =
          FirebaseFirestore.instance
              .collection('cookApplications')
              .doc(widget.cookId);
if (newStatus == 'approved') {
  final applicationSnapshot =
      await applicationReference.get();

  final applicationData =
      applicationSnapshot.data() ??
          <String, dynamic>{};

  final readiness =
      applicationData['readiness']
              as Map<String, dynamic>? ??
          <String, dynamic>{};

  const requiredReadinessItems = [
    'councilRegistrationVerified',
    'foodSafetyTrainingCompleted',
    'allergenReadinessCompleted',
    'menuPricingReviewed',
    'sfbbProceduresReady',
    'packagingFulfilmentReady',
    'homeEatsKitchenCheckPassed',
  ];

  final allReadinessComplete =
      requiredReadinessItems.every(
    (item) => readiness[item] == true,
  );

  if (!allReadinessComplete) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Complete all HomeEats Cook Readiness checks before approving this cook.',
        ),
      ),
    );

    return;
  }
}
      final userReference =
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.cookId);

if (newStatus == 'approved') {
  // readiness checking block here
}


      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        applicationReference,
        {
          'verificationStatus': newStatus,

          if (newStatus == 'documents_required' ||
              newStatus == 'changes_requested') ...{
            'documentsUnlocked': true,
            'onboardingStatus': newStatus,
          },

          if (newStatus == 'approved') ...{
            'onboardingStatus': 'approved',
            'verified': true,
          },

          if (newStatus == 'rejected') ...{
            'onboardingStatus': 'rejected',
          },

          'reviewNotes':
              _reviewNotesController.text.trim(),
          'reviewedBy': adminUser.uid,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        userReference,
        {
          'verificationStatus': newStatus,

          if (newStatus == 'documents_required' ||
              newStatus == 'changes_requested') ...{
            'documentsUnlocked': true,
            'onboardingStatus': newStatus,
            'verified': false,
          },

          if (newStatus == 'approved') ...{
            'onboardingStatus': 'approved',
            'verified': true,
          },

          if (newStatus == 'rejected') ...{
            'onboardingStatus': 'rejected',
            'verified': false,
          },

          'verificationReviewedAt':
              FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (!mounted) {
        return;
      }

      String message;

      switch (newStatus) {
        case 'approved':
          message = 'Cook verification approved.';
          break;

        case 'changes_requested':
          message = 'Changes have been requested.';
          break;

        case 'rejected':
          message = 'Cook verification rejected.';
          break;

        default:
          message = 'Verification updated.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update verification: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
Future<void> _updateReadinessItem({
  required String itemKey,
  required bool value,
}) async {
  if (_isUpdating) {
    return;
  }

  final adminUser =
      FirebaseAuth.instance.currentUser;

  if (adminUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Admin account is not signed in.',
        ),
      ),
    );
    return;
  }

  try {
    await FirebaseFirestore.instance
        .collection('cookApplications')
        .doc(widget.cookId)
        .update({
      'readiness.$itemKey': value,
      'readinessUpdatedBy': adminUser.uid,
      'readinessUpdatedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  } catch (error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to update readiness: $error',
        ),
      ),
    );
  }
}
  Future<void> _allowReapplication() async {
    if (_isUpdating) {
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Allow reapplication',
      message:
          'Allow this cook to start a new verification application?',
      buttonText: 'Allow reapplication',
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final adminUser = FirebaseAuth.instance.currentUser;

      if (adminUser == null) {
        throw Exception(
          'Admin account is not signed in.',
        );
      }

      final applicationReference =
          FirebaseFirestore.instance
              .collection('cookApplications')
              .doc(widget.cookId);

      final userReference =
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.cookId);

      final applicationSnapshot =
          await applicationReference.get();

      final oldData =
          applicationSnapshot.data() ??
              <String, dynamic>{};

      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        applicationReference,
        {
          // Preserve the previous rejection for admin history.
          'previousRejection': {
            'reviewNotes': oldData['reviewNotes'],
            'reviewedBy': oldData['reviewedBy'],
            'reviewedAt': oldData['reviewedAt'],
            'status': oldData['verificationStatus'],
          },

          // Reset the cook to the beginning.
          'verificationStatus': 'draft',
          'onboardingStatus': 'draft',
          'documentsUnlocked': false,
          'reviewNotes': '',

          // A reapplication should require new documents.
          'documents': <String, dynamic>{},
          'declarations': <String, dynamic>{},

          'submittedAt': FieldValue.delete(),
          'reviewedBy': FieldValue.delete(),
          'reviewedAt': FieldValue.delete(),

          'reapplicationAllowed': true,
          'reapplicationAllowedBy': adminUser.uid,
          'reapplicationAllowedAt':
              FieldValue.serverTimestamp(),

          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        userReference,
        {
          'verificationStatus': 'draft',
          'onboardingStatus': 'draft',
          'documentsUnlocked': false,
          'verificationSubmitted': false,

          'verificationSubmittedAt':
              FieldValue.delete(),
          'verificationReviewedAt':
              FieldValue.delete(),

          'reapplicationAllowed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This cook can now reapply.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to allow reapplication: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String buttonText,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(buttonText),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _openDocument(
    String downloadUrl,
  ) async {
    final uri = Uri.tryParse(downloadUrl);

    if (uri == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This document link is invalid.',
          ),
        ),
      );

      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The document could not be opened.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The document could not be opened: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Application'),
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('cookApplications')
            .doc(widget.cookId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load this application.\n\n'
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

          final document = snapshot.data;

          if (document == null || !document.exists) {
            return const Center(
              child: Text(
                'This cook application could not be found.',
              ),
            );
          }

          final data =
              document.data() ?? <String, dynamic>{};

          final documents =
              data['documents']
                      as Map<String, dynamic>? ??
                  <String, dynamic>{};
                  final readiness =
    data['readiness']
            as Map<String, dynamic>? ??
        <String, dynamic>{};

          final businessName =
              _readText(data, 'businessName');

          final phone =
              _readText(data, 'phone');

          final address =
              _readText(data, 'businessAddress');

          final postcode =
              _readText(data, 'postcode');

          final localAuthority =
              _readText(data, 'localAuthority');

          final status =
              _readText(data, 'verificationStatus');
              final hygieneRatingReviewStatus =
    data['foodHygieneRatingReviewStatus']
        ?.toString()
        .trim()
        .toLowerCase() ??
    '';

          final normalizedStatus =
              status.trim().toLowerCase();

          final onboardingStatus =
              _readText(data, 'onboardingStatus');

          final normalizedOnboardingStatus =
              onboardingStatus.trim().toLowerCase();

          final documentsUnlocked =
              data['documentsUnlocked'] == true;

          final isAwaitingContact =
              normalizedOnboardingStatus ==
                      'awaiting_contact' &&
                  !documentsUnlocked;

          final isPending =
              normalizedStatus == 'pending';

          final isRejected =
              normalizedStatus == 'rejected';

          return AbsorbPointer(
            absorbing: _isUpdating,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionCard(
                  title: 'Application status',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatStatus(status),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _SectionCard(
                  title: 'Business details',
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Business name',
                        value: businessName,
                      ),
                      _DetailRow(
                        label: 'Phone',
                        value: phone,
                      ),
                      _DetailRow(
                        label: 'Address',
                        value: address,
                      ),
                      _DetailRow(
                        label: 'Postcode',
                        value: postcode,
                      ),
                      _DetailRow(
                        label: 'Local authority',
                        value: localAuthority,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _SectionCard(
                  title: 'Uploaded documents',
                  child: Column(
                    children: [
                      _DocumentReviewRow(
                        title:
                            'Food Business Registration',
                        documentData: documents[
                            'food_business_registration'],
                        onOpen: _openDocument,
                      ),
                      _DocumentReviewRow(
  title: 'Food Hygiene Certificate',
  documentData:
      documents['food_hygiene_certificate'],
  onOpen: _openDocument,
),

_DocumentReviewRow(
  title: 'Food Hygiene Rating',
  documentData:
      documents['food_hygiene_rating'],
  onOpen: _openDocument,
  awaitingCouncilInspection:
      data['declarations']
              ?['awaitingCouncilRating'] ==
          true,
),

if (hygieneRatingReviewStatus == 'pending_review') ...[
  const SizedBox(height: 12),

  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Council Food Hygiene Rating review',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Review the uploaded council rating above, then approve it or request a replacement.',
        ),

        const SizedBox(height: 14),

        FilledButton.icon(
          onPressed: _isUpdating
              ? null
              : () async {
                  final confirmed =
                      await _confirmAction(
                    title: 'Approve rating',
                    message:
                        'Approve this council Food Hygiene Rating?',
                    buttonText: 'Approve rating',
                  );

                  if (!confirmed) return;

                  setState(() {
                    _isUpdating = true;
                  });

                  try {
                    await FirebaseFirestore.instance
                        .collection('cookApplications')
                        .doc(widget.cookId)
                        .update({
                      'foodHygieneRatingReviewStatus':
                          'approved',
                      'foodHygieneRatingReviewedAt':
                          FieldValue.serverTimestamp(),
                      'updatedAt':
                          FieldValue.serverTimestamp(),
                    });

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.cookId)
                        .set(
                      {
                        'foodHygieneRatingReviewStatus':
                            'approved',
                        'foodHygieneRatingReviewedAt':
                            FieldValue.serverTimestamp(),
                        'updatedAt':
                            FieldValue.serverTimestamp(),
                      },
                      SetOptions(merge: true),
                    );

                  if (!context.mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Food Hygiene Rating approved.',
                        ),
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isUpdating = false;
                      });
                    }
                  }
                },
          icon: const Icon(
            Icons.check_circle_rounded,
          ),
          label: const Text(
            'Approve rating',
          ),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: _isUpdating
              ? null
              : () async {
                  final confirmed =
                      await _confirmAction(
                    title: 'Request replacement',
                    message:
                        'Ask the cook to replace their council Food Hygiene Rating?',
                    buttonText:
                        'Request replacement',
                  );

                  if (!confirmed) return;

                  setState(() {
                    _isUpdating = true;
                  });

                  try {
                    await FirebaseFirestore.instance
                        .collection('cookApplications')
                        .doc(widget.cookId)
                        .update({
                      'foodHygieneRatingReviewStatus':
                          'changes_requested',
                      'foodHygieneRatingReviewNotes':
                          _reviewNotesController.text
                              .trim(),
                      'foodHygieneRatingReviewedAt':
                          FieldValue.serverTimestamp(),
                      'updatedAt':
                          FieldValue.serverTimestamp(),
                    });

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.cookId)
                        .set(
                      {
                        'foodHygieneRatingReviewStatus':
                            'changes_requested',
                        'updatedAt':
                            FieldValue.serverTimestamp(),
                      },
                      SetOptions(merge: true),
                    );
if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Replacement requested.',
                        ),
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isUpdating = false;
                      });
                    }
                  }
                },
          icon: const Icon(
            Icons.refresh_rounded,
          ),
          label: const Text(
            'Request replacement',
          ),
        ),
      ],
    ),
  ),

  const SizedBox(height: 12),
],
                      _DocumentReviewRow(
                        title:
                            'Public Liability Insurance',
                        documentData: documents[
                            'public_liability_insurance'],
                        onOpen: _openDocument,
                      ),
                      _DocumentReviewRow(
                        title: 'Photo ID',
                        documentData:
                            documents['photo_id'],
                        onOpen: _openDocument,
                      ),
                      _DocumentReviewRow(
                        title: 'Profile Photo',
                        documentData:
                            documents['profile_photo'],
                        onOpen: _openDocument,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
const SizedBox(height: 12),

_SectionCard(
  title: 'HomeEats Cook Readiness',
  child: Column(
    children: [
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: readiness[
                'councilRegistrationVerified'] ==
            true,
        title: const Text(
          'Council registration verified',
        ),
        subtitle: const Text(
          'HomeEats has checked that the food business is registered with the local authority.',
        ),
        onChanged: (value) {
          _updateReadinessItem(
            itemKey:
                'councilRegistrationVerified',
            value: value ?? false,
          );
        },
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: readiness[
                'foodSafetyTrainingCompleted'] ==
            true,
        title: const Text(
          'Food safety training completed',
        ),
        subtitle: const Text(
          'Required food safety training or certificate has been reviewed.',
        ),
        onChanged: (value) {
          _updateReadinessItem(
            itemKey:
                'foodSafetyTrainingCompleted',
            value: value ?? false,
          );
        },
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: readiness[
                'allergenReadinessCompleted'] ==
            true,
        title: const Text(
          'Allergen readiness completed',
        ),
        subtitle: const Text(
          'Menu allergen information and cross-contact controls have been reviewed.',
        ),
        onChanged: (value) {
          _updateReadinessItem(
            itemKey:
                'allergenReadinessCompleted',
            value: value ?? false,
          );
        },
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: readiness[
                'menuPricingReviewed'] ==
            true,
        title: const Text(
          'Menu and pricing reviewed',
        ),
        subtitle: const Text(
          'Menu, portions, costs, selling prices and realistic production capacity have been reviewed.',
        ),
        onChanged: (value) {
          _updateReadinessItem(
            itemKey: 'menuPricingReviewed',
            value: value ?? false,
          );
        },
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: readiness[
                'sfbbProceduresReady'] ==
            true,
        title: const Text(
          'Food safety procedures ready',
        ),
        subtitle: const Text(
          'Cleaning, chilling, cooking, cross-contamination and food safety records are in place.',
        ),
        onChanged: (value) {
          _updateReadinessItem(
            itemKey: 'sfbbProceduresReady',
            value: value ?? false,
          );
        },
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: readiness[
                'packagingFulfilmentReady'] ==
            true,
        title: const Text(
          'Packaging and fulfilment ready',
        ),
        subtitle: const Text(
          'Packaging, collection/delivery process and order handling have been reviewed.',
        ),
        onChanged: (value) {
          _updateReadinessItem(
            itemKey:
                'packagingFulfilmentReady',
            value: value ?? false,
          );
        },
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: readiness[
                'homeEatsKitchenCheckPassed'] ==
            true,
        title: const Text(
          'HomeEats Kitchen Check passed',
        ),
        subtitle: const Text(
          'HomeEats has completed its own pre-go-live kitchen readiness check.',
        ),
        onChanged: (value) {
          _updateReadinessItem(
            itemKey:
                'homeEatsKitchenCheckPassed',
            value: value ?? false,
          );
        },
      ),
    ],
  ),
),

const SizedBox(height: 12),
                _SectionCard(
                  title: 'Admin review notes',
                  child: TextField(
                    controller:
                        _reviewNotesController,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(
                      hintText:
                          'Add a reason for rejection or '
                          'requested changes.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // FIRST STAGE:
                // Admin contacts cook and unlocks documents.
                if (isAwaitingContact) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          phone == 'Not provided'
                              ? null
                              : () async {
                                  final cleanedPhone =
                                      phone.replaceAll(
                                    ' ',
                                    '',
                                  );

                                  final uri = Uri(
                                    scheme: 'tel',
                                    path: cleanedPhone,
                                  );

                                  if (await canLaunchUrl(
                                    uri,
                                  )) {
                                    await launchUrl(uri);
                                  } else if (context
                                      .mounted) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Unable to open '
                                          'the phone dialler.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                      icon: const Icon(
                        Icons.phone_rounded,
                      ),
                      label:
                          const Text('Call cook'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  FilledButton.icon(
                    onPressed: _isUpdating
                        ? null
                        : () async {
                            final confirmed =
                                await _confirmAction(
                              title:
                                  'Unlock documents',
                              message:
                                  'Allow this cook to '
                                  'continue to the document '
                                  'upload stage?',
                              buttonText:
                                  'Unlock documents',
                            );

                            if (confirmed) {
                              await _updateVerificationStatus(
                                'documents_required',
                              );
                            }
                          },
                    icon: const Icon(
                      Icons.lock_open_rounded,
                    ),
                    label: const Text(
                      'Unlock documents',
                    ),
                  ),
                ],

                // PENDING:
                // Documents have been submitted for review.
                if (isPending) ...[
                  FilledButton.icon(
                    onPressed: _isUpdating
                        ? null
                        : () async {
                            final confirmed =
                                await _confirmAction(
                              title: 'Approve cook',
                              message:
                                  'Approve this cook '
                                  'verification?',
                              buttonText: 'Approve',
                            );

                            if (confirmed) {
                              await _updateVerificationStatus(
                                'approved',
                              );
                            }
                          },
                    icon: const Icon(
                      Icons.check_circle_rounded,
                    ),
                    label: const Text('Approve'),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: _isUpdating
                        ? null
                        : () async {
                            final confirmed =
                                await _confirmAction(
                              title:
                                  'Request changes',
                              message:
                                  'Send the review notes '
                                  'to the cook and allow '
                                  'them to resubmit?',
                              buttonText:
                                  'Request changes',
                            );

                            if (confirmed) {
                              await _updateVerificationStatus(
                                'changes_requested',
                              );
                            }
                          },
                    icon: const Icon(
                      Icons.edit_note_rounded,
                    ),
                    label: const Text(
                      'Request changes',
                    ),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: _isUpdating
                        ? null
                        : () async {
                            final confirmed =
                                await _confirmAction(
                              title:
                                  'Reject application',
                              message:
                                  'Reject this cook '
                                  'verification application?',
                              buttonText: 'Reject',
                            );

                            if (confirmed) {
                              await _updateVerificationStatus(
                                'rejected',
                              );
                            }
                          },
                    icon: const Icon(
                      Icons.cancel_rounded,
                    ),
                    label: const Text('Reject'),
                  ),
                ],

                // REJECTED:
                // Only HomeEats can explicitly allow another application.
                if (isRejected) ...[
                  FilledButton.icon(
                    onPressed: _isUpdating
                        ? null
                        : _allowReapplication,
                    icon: const Icon(
                      Icons.restart_alt_rounded,
                    ),
                    label: const Text(
                      'Allow reapplication',
                    ),
                  ),
                ],

                if (_isUpdating) ...[
                  const SizedBox(height: 20),
                  const Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _readText(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key]?.toString().trim();

    if (value == null || value.isEmpty) {
      return 'Not provided';
    }

    return value;
  }

  String _formatStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return 'Approved';

      case 'changes_requested':
        return 'Changes requested';

      case 'rejected':
        return 'Rejected';

      case 'pending':
        return 'Pending review';

      case 'documents_required':
        return 'Documents unlocked';

      case 'awaiting_contact':
        return 'Awaiting contact';

      case 'draft':
        return 'Draft';

      default:
        return status == 'Not provided'
            ? 'Unknown'
            : status;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _DocumentReviewRow extends StatelessWidget {
  const _DocumentReviewRow({
    required this.title,
    required this.documentData,
    required this.onOpen,
    this.awaitingCouncilInspection = false,
  });

  final String title;
  final dynamic documentData;
  final bool awaitingCouncilInspection;

  final Future<void> Function(
    String downloadUrl,
  ) onOpen;

  @override
  Widget build(BuildContext context) {
    String? fileName;
    String? downloadUrl;

    if (documentData is Map) {
      final data =
          Map<String, dynamic>.from(
        documentData as Map,
      );

      fileName =
          data['fileName']?.toString().trim();

      downloadUrl =
          data['downloadUrl']?.toString().trim();
    }

    final isUploaded =
        downloadUrl != null &&
        downloadUrl.isNotEmpty;

        final isAwaitingCouncilInspection =
    awaitingCouncilInspection && !isUploaded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Icon(
  isUploaded
      ? Icons.check_circle_rounded
      : isAwaitingCouncilInspection
          ? Icons.schedule_rounded
          : Icons.cancel_outlined,
  color: isUploaded
      ? Colors.green
      : isAwaitingCouncilInspection
          ? Colors.orange
          : Colors.red,
),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isUploaded
                      ? fileName == null ||
                              fileName.isEmpty
                          ? 'Uploaded'
                          : fileName
                      : isAwaitingCouncilInspection
    ? 'Awaiting council inspection'
    : 'Not uploaded',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
          if (isUploaded)
            TextButton.icon(
              onPressed: () async {
                await onOpen(downloadUrl!);
              },
              icon: const Icon(
                Icons.open_in_new_rounded,
              ),
              label: const Text('Open'),
            ),
        ],
      ),
    );
  }
}