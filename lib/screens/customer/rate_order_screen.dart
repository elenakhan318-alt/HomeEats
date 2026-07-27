import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class RateOrderScreen extends StatefulWidget {
  const RateOrderScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  final TextEditingController _reviewController =
      TextEditingController();

  int _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('You must be signed in to submit a rating.');
      return;
    }

    if (_selectedRating == 0) {
      _showMessage('Please select a star rating.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final orderReference = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId);

      final orderSnapshot = await orderReference.get();

      if (!orderSnapshot.exists) {
        throw Exception('Order could not be found.');
      }

      final orderData =
          orderSnapshot.data() ?? <String, dynamic>{};

      final status = orderData['status']?.toString() ?? '';

      if (status != 'completed') {
        throw Exception(
          'Only completed orders can be rated.',
        );
      }

      final customerId =
          orderData['customerId']?.toString() ?? '';

      if (customerId != user.uid) {
  throw Exception(
    'You can only rate your own order.',
  );
}
final userSnapshot = await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .get();

final userData =
    userSnapshot.data() ?? <String, dynamic>{};

final customerName =
    userData['fullName']?.toString().trim().isNotEmpty == true
        ? userData['fullName'].toString().trim()
        : 'Customer';
      final cookIdsValue = orderData['cookIds'];

      String cookId = '';

      if (cookIdsValue is List && cookIdsValue.isNotEmpty) {
        cookId = cookIdsValue.first.toString();
      }

      if (cookId.isEmpty) {
        final itemsValue = orderData['items'];

        if (itemsValue is List && itemsValue.isNotEmpty) {
          final firstItem = itemsValue.first;

          if (firstItem is Map) {
            cookId = firstItem['cookId']?.toString() ?? '';
          }
        }
      }

      if (cookId.isEmpty) {
        throw Exception(
          'The cook could not be identified.',
        );
      }

      final ratingReference = FirebaseFirestore.instance
          .collection('ratings')
          .doc(widget.orderId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final existingRating =
              await transaction.get(ratingReference);

          if (existingRating.exists) {
            throw Exception(
              'You have already rated this order.',
            );
          }

          transaction.set(
            ratingReference,
            {
            'orderId': widget.orderId,
'customerId': user.uid,
'customerName': customerName,
'cookId': cookId,
              'rating': _selectedRating,
              'review': _reviewController.text.trim(),
              'status': 'published',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );

          transaction.update(
            orderReference,
            {
              'hasRating': true,
              'ratingValue': _selectedRating,
              'ratedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your rating.'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Rating could not be submitted: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate Order'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.restaurant_rounded,
                    size: 54,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.regular),
                  const Text(
                    'How was your meal?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  const Text(
                    'Tap a star to rate your experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;
                      final isSelected =
                          starNumber <= _selectedRating;

                      return IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _selectedRating = starNumber;
                                });
                              },
                        iconSize: 42,
                        icon: Icon(
                          isSelected
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppColors.primary,
                        ),
                      );
                    }),
                  ),
                  if (_selectedRating > 0) ...[
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      _ratingLabel(_selectedRating),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.regular),
            Container(
              padding: const EdgeInsets.all(AppSpacing.regular),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(AppRadius.card),
              ),
              child: TextField(
                controller: _reviewController,
                enabled: !_isSubmitting,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Write a review (optional)',
                  hintText:
                      'Tell other customers what you enjoyed.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.regular),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed:
                    _isSubmitting ? null : _submitRating,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.star_rounded),
                label: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : 'Submit rating',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}