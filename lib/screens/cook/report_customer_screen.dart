import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportCustomerScreen extends StatefulWidget {
  const ReportCustomerScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<ReportCustomerScreen> createState() =>
      _ReportCustomerScreenState();
}

class _ReportCustomerScreenState
    extends State<ReportCustomerScreen> {
  final TextEditingController _detailsController =
      TextEditingController();

  final List<String> _reasons = [
    'Abusive behaviour',
    'Threatening behaviour',
    'Customer unavailable',
    'Incorrect address',
    'Failed to collect order',
    'Suspected fraud',
    'False complaint',
    'Other',
  ];

  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final details = _detailsController.text.trim();

    if (currentUser == null) {
      _showMessage(
        'You must be signed in to submit a complaint.',
      );
      return;
    }

    if (_selectedReason == null) {
      _showMessage('Please select a reason.');
      return;
    }

    if (details.length < 10) {
      _showMessage(
        'Please provide at least 10 characters of detail.',
      );
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

      final customerId = _readCustomerId(orderData);

      if (customerId.isEmpty) {
        throw Exception(
          'The customer could not be identified.',
        );
      }

      final complaintId =
          '${widget.orderId}_${currentUser.uid}_customer';

      final complaintReference = FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final existingComplaint =
              await transaction.get(complaintReference);

          if (existingComplaint.exists) {
            throw Exception(
              'You have already reported this customer for this order.',
            );
          }

          transaction.set(
            complaintReference,
            {
              'orderId': widget.orderId,
              'submittedByUserId': currentUser.uid,
              'submittedByRole': 'cook',
              'reportedUserId': customerId,
              'reportedUserRole': 'customer',
              'category': _selectedReason,
              'description': details,
              'status': 'open',
              'createdAt': FieldValue.serverTimestamp(),
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
          content: Text(
            'Your complaint has been submitted.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Complaint could not be submitted: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _readCustomerId(
    Map<String, dynamic> orderData,
  ) {
    final customerId =
        orderData['customerId']?.toString().trim() ?? '';

    if (customerId.isNotEmpty) {
      return customerId;
    }

    final userId =
        orderData['userId']?.toString().trim() ?? '';

    if (userId.isNotEmpty) {
      return userId;
    }

    return '';
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
      appBar: AppBar(
        title: const Text('Report Customer'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Submit a complaint',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your complaint is private and will be reviewed by HomeEats.',
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: _reasons.map((reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _selectedReason = value;
                      });
                    },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _detailsController,
              enabled: !_isSubmitting,
              minLines: 5,
              maxLines: 8,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText: 'Explain what happened.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isSubmitting ? null : _submitComplaint,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.flag_outlined),
                label: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : 'Submit complaint',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}