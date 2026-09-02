import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../widgets/document_upload_card.dart';

class CookVerificationScreen extends StatefulWidget {
  const CookVerificationScreen({super.key});

  @override
  State<CookVerificationScreen> createState() =>
      _CookVerificationScreenState();
}

class _CookVerificationScreenState
    extends State<CookVerificationScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isLoadingDraft = true;

  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _localAuthorityController = TextEditingController();

  bool _informationConfirmed = false;
  bool _allergenConfirmed = false;
  bool _termsAccepted = false;

  bool _awaitingCouncilRating = false;

  final Map<VerificationDocumentType, VerificationDocumentState>
      _documents = {
    VerificationDocumentType.foodBusinessRegistration:
        VerificationDocumentState(),
    VerificationDocumentType.foodHygieneCertificate:
        VerificationDocumentState(),
    VerificationDocumentType.foodHygieneRating:
        VerificationDocumentState(),
    VerificationDocumentType.publicLiabilityInsurance:
        VerificationDocumentState(),
    VerificationDocumentType.photoId:
        VerificationDocumentState(),
    VerificationDocumentType.profilePhoto:
        VerificationDocumentState(),
  };
@override
void initState() {
  super.initState();
  _loadVerificationDraft();
}
Future<bool> _saveVerificationDraft() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return false;
  }

  try {
    final documentData =
        <String, Map<String, dynamic>>{};

    for (final entry in _documents.entries) {
      if (entry.value.downloadUrl != null) {
        documentData[entry.key.storageName] = {
          'fileName': entry.value.fileName,
          'downloadUrl': entry.value.downloadUrl,
        };
      }
    }

    await FirebaseFirestore.instance
        .collection('cookApplications')
        .doc(user.uid)
        .set(
      {
        'cookId': user.uid,
        'email': user.email,
        'businessName':
            _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'businessAddress':
            _addressController.text.trim(),
        'postcode':
            _postcodeController.text.trim(),
        'localAuthority':
            _localAuthorityController.text.trim(),
        'declarations': {
  'informationConfirmed':
      _informationConfirmed,
  'allergenConfirmed':
      _allergenConfirmed,
  'termsAccepted': _termsAccepted,
  'awaitingCouncilRating':
      _awaitingCouncilRating,
},
        'documents': documentData,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return true;
  } on FirebaseException catch (error) {
    if (!mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.message ??
              'Your verification draft could not be saved.',
        ),
      ),
    );

    return false;
  }
}
Future<void> _loadVerificationDraft() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    if (mounted) {
      setState(() {
        _isLoadingDraft = false;
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

    if (!applicationSnapshot.exists) {
      return;
    }

    final data =
        applicationSnapshot.data() ??
            <String, dynamic>{};
            final verificationStatus =
    data['verificationStatus']
        ?.toString()
        .trim()
        .toLowerCase();

if (verificationStatus == 'documents_required' ||
    verificationStatus == 'changes_requested') {
  _currentStep = 1;
}

    final declarations =
        data['declarations']
                as Map<String, dynamic>? ??
            <String, dynamic>{};

    final documents =
        data['documents']
                as Map<String, dynamic>? ??
            <String, dynamic>{};

    _businessNameController.text =
        data['businessName']?.toString() ?? '';

    _phoneController.text =
        data['phone']?.toString() ?? '';

    _addressController.text =
        data['businessAddress']?.toString() ?? '';

    _postcodeController.text =
        data['postcode']?.toString() ?? '';

    _localAuthorityController.text =
        data['localAuthority']?.toString() ?? '';

    _informationConfirmed =
        declarations['informationConfirmed'] == true;

    _allergenConfirmed =
        declarations['allergenConfirmed'] == true;

    _termsAccepted =
        declarations['termsAccepted'] == true;

        _awaitingCouncilRating =
    declarations['awaitingCouncilRating'] == true;

    for (final documentType
        in VerificationDocumentType.values) {
      final documentData =
          documents[documentType.storageName];

      if (documentData is Map) {
        final documentState =
            _documents[documentType]!;

        documentState.fileName =
            documentData['fileName']?.toString();

        documentState.downloadUrl =
            documentData['downloadUrl']?.toString();

        if (documentState.downloadUrl != null) {
          documentState.progress = 1;
        }
      }
    }
  } on FirebaseException catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.message ??
              'Your saved verification details could not be loaded.',
        ),
      ),
    );
 } finally {
  if (mounted) {
    setState(() {
      _isLoadingDraft = false;
     });
    }
  }
}

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _localAuthorityController.dispose();
    super.dispose();
  }

  String? _requiredValidator(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName.';
    }

    return null;
  }

  Future<void> _pickAndUploadDocument(
    VerificationDocumentType documentType,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be signed in to upload documents.',
          ),
        ),
      );
      return;
    }

    final documentState = _documents[documentType]!;

    try {
final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: const [
    'pdf',
    'jpg',
    'jpeg',
    'png',
  ],
  allowMultiple: false,
  withData: true,
);

      if (result == null || result.files.isEmpty) {
        return;
      }

      final selectedFile = result.files.single;
      final fileBytes = selectedFile.bytes;

      if (fileBytes == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The selected file could not be read.',
            ),
          ),
        );
        return;
      }

      if (selectedFile.size > 10 * 1024 * 1024) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The file must be smaller than 10 MB.',
            ),
          ),
        );
        return;
      }

      final extension =
          selectedFile.extension?.toLowerCase() ?? 'pdf';

      final contentType = _contentTypeForExtension(extension);

      setState(() {
        documentState.isUploading = true;
        documentState.progress = 0;
      });

      final previousDownloadUrl =
          documentState.downloadUrl;

      final storageReference = FirebaseStorage.instance
          .ref()
          .child('cook_verification')
          .child(user.uid)
          .child(
            '${documentType.storageName}.$extension',
          );

      final uploadTask = storageReference.putData(
        fileBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'documentType': documentType.storageName,
            'originalFileName': selectedFile.name,
            'uploadedBy': user.uid,
          },
        ),
      );

      final progressSubscription =
          uploadTask.snapshotEvents.listen((snapshot) {
        if (!mounted || snapshot.totalBytes == 0) {
          return;
        }

        setState(() {
          documentState.progress =
              snapshot.bytesTransferred /
                  snapshot.totalBytes;
        });
      });

      await uploadTask;
      await progressSubscription.cancel();

      final downloadUrl =
          await storageReference.getDownloadURL();

      if (previousDownloadUrl != null &&
          previousDownloadUrl != downloadUrl) {
        try {
          final previousReference =
              FirebaseStorage.instance.refFromURL(
            previousDownloadUrl,
          );

          if (previousReference.fullPath !=
              storageReference.fullPath) {
            await previousReference.delete();
          }
        } catch (_) {
          // The new upload succeeded, so an old-file
          // deletion failure should not stop the process.
        }
      }

      if (!mounted) return;

      setState(() {
        documentState.fileName = selectedFile.name;
        documentState.downloadUrl = downloadUrl;
        documentState.progress = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${documentType.title} uploaded.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'The document could not be uploaded.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          documentState.isUploading = false;
        });
      }
    }
  }

 Future<void> _removeDocument(
  VerificationDocumentType documentType,
) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return;
  }

  final documentState = _documents[documentType]!;
  final downloadUrl = documentState.downloadUrl;

  if (downloadUrl == null) {
    return;
  }

  try {
    await FirebaseStorage.instance
        .refFromURL(downloadUrl)
        .delete();

    await FirebaseFirestore.instance
        .collection('cookApplications')
        .doc(user.uid)
        .update({
      'documents.${documentType.storageName}':
          FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    setState(() {
      documentState.fileName = null;
      documentState.downloadUrl = null;
      documentState.progress = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${documentType.title} removed. Upload the replacement document.',
        ),
      ),
    );
  } on FirebaseException catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.message ??
              'The document could not be removed.',
        ),
      ),
    );
  }
}
  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/pdf';
    }
  }

  bool get _allRequiredDocumentsUploaded {
  for (final entry in _documents.entries) {
    if (entry.key == VerificationDocumentType.foodHygieneRating &&
        _awaitingCouncilRating) {
      continue;
    }

    if (entry.value.downloadUrl == null) {
      return false;
    }
  }

  return true;
}
  bool get _anyDocumentUploading {
    return _documents.values.any(
      (document) => document.isUploading,
    );
  }

 Future<void> _continue() async {
  if (_currentStep == 0) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_informationConfirmed ||
        !_allergenConfirmed ||
        !_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm all declarations before continuing.',
          ),
        ),
      );
      return;
    }

    final saved = await _saveVerificationDraft();

    if (!saved || !mounted) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }
    final applicationSnapshot =
    await FirebaseFirestore.instance
        .collection('cookApplications')
        .doc(user.uid)
        .get();

final currentStatus =
    applicationSnapshot.data()?['verificationStatus']
        ?.toString()
        .trim()
        .toLowerCase();

if (currentStatus == 'changes_requested') {
  setState(() {
    _currentStep = 1;
  });
  return;
}

    await FirebaseFirestore.instance
        .collection('cookApplications')
        .doc(user.uid)
        .set(
      {
        'onboardingStatus': 'awaiting_contact',
        'documentsUnlocked': false,
        'setupFeePaid': false,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'verificationStatus': 'awaiting_contact',
        'documentsUnlocked': false,
        'setupFeePaid': false,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return;
  }

  if (_currentStep == 1) {
    if (_anyDocumentUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait for all uploads to finish.',
          ),
        ),
      );
      return;
    }

    if (!_allRequiredDocumentsUploaded) {
  final missingDocument = _documents.entries
      .firstWhere(
        (entry) {
          if (entry.key ==
                  VerificationDocumentType.foodHygieneRating &&
              _awaitingCouncilRating) {
            return false;
          }

          return entry.value.downloadUrl == null;
        },
      )
      .key;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Upload ${missingDocument.title} before continuing.',
      ),
    ),
  );

  return;
}
}

  final saved = await _saveVerificationDraft();

  if (!saved || !mounted) {
    return;
  }

  if (_currentStep == 2) {
    _submitVerification();
    return;
  }

  setState(() {
    _currentStep++;
  });
}
  Future<void> _submitVerification() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be signed in to submit verification.',
          ),
        ),
      );
      return;
    }

    if (!_allRequiredDocumentsUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All required documents must be uploaded.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final documentData =
          <String, Map<String, dynamic>>{};

      for (final entry in _documents.entries) {
        documentData[entry.key.storageName] = {
          'fileName': entry.value.fileName,
          'downloadUrl': entry.value.downloadUrl,
        };
      }

      await FirebaseFirestore.instance
          .collection('cookApplications')
          .doc(user.uid)
          .set(
        {
          'cookId': user.uid,
          'email': user.email,
          'businessName':
              _businessNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'businessAddress':
              _addressController.text.trim(),
          'postcode':
              _postcodeController.text.trim(),
          'localAuthority':
              _localAuthorityController.text.trim(),
          'declarations': {
            'informationConfirmed':
                _informationConfirmed,
            'allergenConfirmed':
                _allergenConfirmed,
            'termsAccepted': _termsAccepted,
          },
          'documents': documentData,
          'verificationStatus': 'pending',
          'submittedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'verificationStatus': 'pending',
          'verificationSubmittedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your verification application has been submitted.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'The application could not be submitted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Submission failed: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
void _goBack() {
  if (_currentStep > 0 && !_isSubmitting) {
    setState(() {
      _currentStep--;
    });
  }
}
@override
Widget build(BuildContext context) {
  if (_isLoadingDraft) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  return Scaffold(
      appBar: AppBar(
  title: const Text('Cook verification'),
  actions: [
    IconButton(
      tooltip: 'Save & sign out',
      icon: const Icon(Icons.logout_rounded),
      onPressed: _isSubmitting
          ? null
          : () async {
              final saved =
                  await _saveVerificationDraft();

              if (!saved) {
                return;
              }

              await FirebaseAuth.instance.signOut();
            },
    ),
  ],
),
      body: SafeArea(
        child: Stepper(
  currentStep: _currentStep,
          onStepContinue:
              _isSubmitting ? null : _continue,
          onStepCancel:
              _currentStep == 0 ? null : _goBack,
          controlsBuilder: (context, details) {
            final isLastStep = _currentStep == 2;

            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting
                          ? null
                          : details.onStepContinue,
                      child: _isSubmitting &&
                              isLastStep
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isLastStep
                                  ? 'Submit verification'
                                  : 'Continue',
                            ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
  steps: [
  Step(
    title: const Text('Business details'),
    subtitle: const Text('Step 1 of 3'),
    isActive: _currentStep >= 0,
    state: _currentStep > 0
        ? StepState.complete
        : StepState.indexed,
    content: _buildBusinessDetailsStep(),
  ),
  Step(
    title: const Text('Required documents'),
    subtitle: const Text('Step 2 of 3'),
    isActive: _currentStep >= 1,
    state: _currentStep > 1
        ? StepState.complete
        : StepState.indexed,
    content: _buildDocumentsStep(),
  ),
  Step(
    title: const Text('Review and submit'),
    subtitle: const Text('Step 3 of 3'),
    isActive: _currentStep >= 2,
    state: StepState.indexed,
    content: _buildReviewStep(),
  ),
],
        ),
      ),
    );
  }

  Widget _buildBusinessDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _businessNameController,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              labelText:
                  'Business or trading name',
              prefixIcon:
                  Icon(Icons.storefront_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                _requiredValidator(
              value,
              'business or trading name',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telephone number',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                _requiredValidator(
              value,
              'telephone number',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            textCapitalization:
                TextCapitalization.words,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Business address',
              prefixIcon:
                  Icon(Icons.home_work_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                _requiredValidator(
              value,
              'business address',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _postcodeController,
            textCapitalization:
                TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Postcode',
              prefixIcon:
                  Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                _requiredValidator(
              value,
              'postcode',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller:
                _localAuthorityController,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Local council',
              prefixIcon:
                  Icon(Icons.account_balance_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                _requiredValidator(
              value,
              'localAuthority'
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _informationConfirmed,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I confirm that the information provided is accurate.',
            ),
            onChanged: (value) {
              setState(() {
                _informationConfirmed =
                    value ?? false;
              });
            },
          ),
          CheckboxListTile(
            value: _allergenConfirmed,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'I understand that HomeEats will contact me to explain '
'the onboarding and verification process.'
            ),
            onChanged: (value) {
              setState(() {
                _allergenConfirmed =
                    value ?? false;
              });
            },
          ),
          CheckboxListTile(
            value: _termsAccepted,
            contentPadding: EdgeInsets.zero,
            title: const Text(
            'I understand that I will need to review and accept '
'the relevant HomeEats terms, food-safety requirements '
'and policies before I can become an approved cook.'
            ),
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Upload every required document before submitting your application.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.orange.shade50,
    borderRadius: BorderRadius.circular(12),
  ),
  child: CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    value: _awaitingCouncilRating,
    title: const Text(
      'I am awaiting my council food hygiene inspection/rating',
      style: TextStyle(
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: const Text(
      'You can continue without uploading a Food Hygiene Rating if your business is registered and you are waiting for the council inspection. You can upload the rating later.',
    ),
    onChanged: (value) {
      setState(() {
        _awaitingCouncilRating = value ?? false;
      });
    },
  ),
),

const SizedBox(height: 16),
        for (final documentType
            in VerificationDocumentType.values) ...[
          _buildDocumentCard(documentType),
          const SizedBox(height: 16),
        ],
        const Text(
          'Accepted files: PDF, JPG or PNG. Maximum size: 10 MB per file.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(
    VerificationDocumentType documentType,
  ) {
    final documentState =
        _documents[documentType]!;

        final bool isCouncilRating =
    documentType == VerificationDocumentType.foodHygieneRating;

final bool ratingCanBeAddedLater =
    isCouncilRating && _awaitingCouncilRating;

    return DocumentUploadCard(
      title: documentType.title,
      description: ratingCanBeAddedLater
    ? 'Awaiting council inspection — this rating can be uploaded later.'
    : documentType.description,
      icon: documentType.icon,
      fileName: documentState.fileName,
      isUploading:
          documentState.isUploading,
      uploadProgress:
          documentState.progress,
onUpload: ratingCanBeAddedLater
    ? null
    : () => _pickAndUploadDocument(documentType),
      onRemove:
          documentState.downloadUrl == null
              ? null
              : () => _removeDocument(
                    documentType,
                  ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _reviewRow(
          'Business name',
          _businessNameController.text.trim(),
        ),
        _reviewRow(
          'Telephone',
          _phoneController.text.trim(),
        ),
        _reviewRow(
          'Address',
          _addressController.text.trim(),
        ),
        _reviewRow(
          'Postcode',
          _postcodeController.text.trim(),
        ),
        _reviewRow(
        'Local council',
          _localAuthorityController.text.trim(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Documents',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (final documentType
            in VerificationDocumentType.values)
          _buildDocumentReviewRow(documentType),
      ],
    );
  }

  Widget _buildDocumentReviewRow(
    VerificationDocumentType documentType,
  ) {
    final uploaded =
        _documents[documentType]!.downloadUrl !=
            null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
  uploaded
      ? Icons.check_circle
      : documentType ==
                  VerificationDocumentType.foodHygieneRating &&
              _awaitingCouncilRating
          ? Icons.schedule_rounded
          : Icons.cancel_outlined,
  color: uploaded
      ? Colors.green
      : documentType ==
                  VerificationDocumentType.foodHygieneRating &&
              _awaitingCouncilRating
          ? Colors.orange
          : Colors.red,
),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
  uploaded
      ? '${documentType.title} uploaded'
      : documentType ==
                  VerificationDocumentType.foodHygieneRating &&
              _awaitingCouncilRating
          ? '${documentType.title} — awaiting council inspection'
          : '${documentType.title} missing',
  style: const TextStyle(
    fontWeight: FontWeight.w600,
  ),
),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(
    String label,
    String value,
  ) {
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty
                  ? 'Not provided'
                  : value,
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationDocumentState {
  String? fileName;
  String? downloadUrl;
  bool isUploading = false;
  double progress = 0;
}

enum VerificationDocumentType {
  foodBusinessRegistration,
  foodHygieneCertificate,
  foodHygieneRating,
  publicLiabilityInsurance,
  photoId,
  profilePhoto,
}

extension VerificationDocumentTypeDetails
    on VerificationDocumentType {
  String get title {
    switch (this) {
      case VerificationDocumentType
            .foodBusinessRegistration:
        return 'Food Business Registration';
      case VerificationDocumentType
            .foodHygieneCertificate:
        return 'Food Hygiene Certificate';
      case VerificationDocumentType
            .foodHygieneRating:
        return 'Food Hygiene Rating';
      case VerificationDocumentType
            .publicLiabilityInsurance:
        return 'Public Liability Insurance';
      case VerificationDocumentType.photoId:
        return 'Photo ID';
      case VerificationDocumentType.profilePhoto:
        return 'Profile Photo';
    }
  }

  String get description {
    switch (this) {
      case VerificationDocumentType
            .foodBusinessRegistration:
      return 'Evidence that your food business is registered with your local council.';
      case VerificationDocumentType
            .foodHygieneCertificate:
        return 'Upload your valid food hygiene or food safety certificate.';
      case VerificationDocumentType
            .foodHygieneRating:
        return 'Evidence of your latest local council food hygiene rating.';
      case VerificationDocumentType
            .publicLiabilityInsurance:
        return 'Upload your current public liability insurance certificate.';
      case VerificationDocumentType.photoId:
        return 'Upload a clear copy of a valid government-issued photo ID.';
      case VerificationDocumentType.profilePhoto:
        return 'Upload a clear profile photograph for your HomeEats cook account.';
    }
  }

  String get storageName {
    switch (this) {
      case VerificationDocumentType
            .foodBusinessRegistration:
        return 'food_business_registration';
      case VerificationDocumentType
            .foodHygieneCertificate:
        return 'food_hygiene_certificate';
      case VerificationDocumentType
            .foodHygieneRating:
        return 'food_hygiene_rating';
      case VerificationDocumentType
            .publicLiabilityInsurance:
        return 'public_liability_insurance';
      case VerificationDocumentType.photoId:
        return 'photo_id';
      case VerificationDocumentType.profilePhoto:
        return 'profile_photo';
    }
  }

  IconData get icon {
    switch (this) {
      case VerificationDocumentType
            .foodBusinessRegistration:
        return Icons.account_balance_outlined;
      case VerificationDocumentType
            .foodHygieneCertificate:
        return Icons.workspace_premium_outlined;
      case VerificationDocumentType
            .foodHygieneRating:
        return Icons.star_outline;
      case VerificationDocumentType
            .publicLiabilityInsurance:
        return Icons.shield_outlined;
      case VerificationDocumentType.photoId:
        return Icons.badge_outlined;
      case VerificationDocumentType.profilePhoto:
        return Icons.person_outline;
    }
  }
}