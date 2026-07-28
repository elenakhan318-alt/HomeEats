import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
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
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = document.data();

      _nameController.text =
          (data?['fullName'] ?? '').toString();

      _phoneController.text =
          (data?['phone'] ?? '').toString();

      _addressController.text =
          (data?['address'] ?? '').toString();

      _email =
          (data?['email'] ?? user.email ?? '').toString();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not load profile: $error',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not update profile: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(
                  AppSpacing.page,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const CircleAvatar(
                        radius: 46,
                        backgroundColor:
                            AppColors.primaryLight,
                        child: Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.large,
                      ),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization:
                            TextCapitalization.words,
                        decoration: _inputDecoration(
                          label: 'Full name',
                          icon: Icons.person_outline,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your name';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      TextFormField(
                        initialValue: _email,
                        enabled: false,
                        decoration: _inputDecoration(
                          label: 'Email address',
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          label: 'Phone number',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.regular,
                      ),
                      TextFormField(
                        controller: _addressController,
                        textCapitalization:
                            TextCapitalization.sentences,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(
                        height: AppSpacing.large,
                      ),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.save_outlined,
                                ),
                          label: Text(
                            _isSaving
                                ? 'Saving...'
                                : 'Save Changes',
                          ),
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