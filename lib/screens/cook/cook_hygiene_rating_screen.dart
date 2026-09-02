import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class CookHygieneRatingScreen extends StatefulWidget {
  const CookHygieneRatingScreen({super.key});

  @override
  State<CookHygieneRatingScreen> createState() =>
      _CookHygieneRatingScreenState();
}

class _CookHygieneRatingScreenState
    extends State<CookHygieneRatingScreen> {
  bool _isLoading = true;
  bool _isUploading = false;

  String? _existingFileName;
  String? _existingDownloadUrl;
  String _reviewStatus = 'not_submitted';

  @override
  void initState() {
    super.initState();
    _loadCurrentRating();
  }

  Future<void> _loadCurrentRating() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final applicationSnapshot =
          await FirebaseFirestore.instance
              .collection('cookApplications')
              .doc(user.uid)
              .get();

      final data = applicationSnapshot.data();

      if (data != null) {
        final documents =
            data['documents'] as Map<String, dynamic>? ??
                <String, dynamic>{};

        final ratingData =
    documents['food_hygiene_rating'];

        if (ratingData is Map) {
          _existingFileName =
              ratingData['fileName']?.toString();

          _existingDownloadUrl =
              ratingData['downloadUrl']?.toString();
        }

        _reviewStatus =
            data['foodHygieneRatingReviewStatus']
                    ?.toString() ??
                (_existingDownloadUrl != null
                    ? 'pending_review'
                    : 'not_submitted');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Food hygiene rating details could not be loaded: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _chooseAndUploadRating() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isUploading) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;

    if (file.bytes == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The selected file could not be read.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final safeFileName = file.name.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );

      final storageReference = FirebaseStorage.instance
          .ref()
          .child('cook_verification')
          .child(user.uid)
          .child('foodHygieneRating')
          .child(
            '${DateTime.now().millisecondsSinceEpoch}_$safeFileName',
          );

      await storageReference.putData(
        file.bytes!,
        SettableMetadata(
          contentType: _contentTypeForFile(file.name),
        ),
      );

      final downloadUrl =
          await storageReference.getDownloadURL();

      final applicationReference =
          FirebaseFirestore.instance
              .collection('cookApplications')
              .doc(user.uid);

      await applicationReference.update({
  'documents.food_hygiene_rating': {
  'fileName': file.name,
  'downloadUrl': downloadUrl,
  'uploadedAt': FieldValue.serverTimestamp(),
},
  'declarations.awaitingCouncilRating': false,
  'foodHygieneRatingReviewStatus': 'pending_review',
  'foodHygieneRatingSubmittedAt':
      FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
});



      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'awaitingCouncilRating': false,
          'foodHygieneRatingReviewStatus':
              'pending_review',
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _existingFileName = file.name;
        _existingDownloadUrl = downloadUrl;
        _reviewStatus = 'pending_review';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your Food Hygiene Rating has been sent to HomeEats for review.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Food Hygiene Rating could not be uploaded: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _contentTypeForFile(String fileName) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.pdf')) {
      return 'application/pdf';
    }

    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }

    return 'image/jpeg';
  }

  String _statusLabel() {
    switch (_reviewStatus) {
      case 'approved':
        return 'Approved by HomeEats';
      case 'rejected':
      case 'changes_requested':
        return 'Changes required';
      case 'pending_review':
        return 'Waiting for HomeEats review';
      default:
        return 'Not yet submitted';
    }
  }

  IconData _statusIcon() {
    switch (_reviewStatus) {
      case 'approved':
        return Icons.verified_rounded;
      case 'rejected':
      case 'changes_requested':
        return Icons.warning_amber_rounded;
      case 'pending_review':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.upload_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Food Hygiene Rating',
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(
                  AppSpacing.page,
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      AppSpacing.large,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        AppRadius.card,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.health_and_safety_rounded,
                          color: AppColors.primary,
                          size: 44,
                        ),
                        const SizedBox(
                          height: AppSpacing.regular,
                        ),
                        const Text(
                          'Council Food Hygiene Rating',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Once your local council has completed its inspection and issued your Food Hygiene Rating, upload the evidence here.',
                          style: TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This is separate from your Food Hygiene Certificate course.',
                          style: TextStyle(
                            color:
                                AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: AppSpacing.large,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      AppSpacing.large,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        AppRadius.card,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _statusIcon(),
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusLabel(),
                                style: const TextStyle(
                                  color:
                                      AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_existingFileName != null &&
                            _existingFileName!
                                .trim()
                                .isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Current file',
                            style: TextStyle(
                              color:
                                  AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _existingFileName!,
                            style: const TextStyle(
                              color:
                                  AppColors.textPrimary,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(
                          height: AppSpacing.large,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isUploading
                                ? null
                                : _chooseAndUploadRating,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.upload_file_rounded,
                                  ),
                            label: Text(
                              _isUploading
                                  ? 'Uploading...'
                                  : _existingDownloadUrl ==
                                          null
                                      ? 'Upload rating'
                                      : 'Replace rating',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: AppSpacing.large,
                  ),
                  const Text(
                    'HomeEats will review the rating after you upload it. Your existing cook approval is not automatically removed while the new rating is being reviewed.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}