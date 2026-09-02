import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportCookScreen extends StatefulWidget {
  const ReportCookScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<ReportCookScreen> createState() => _ReportCookScreenState();
}

class _ReportCookScreenState extends State<ReportCookScreen> {
  final TextEditingController _detailsController =
      TextEditingController();

  final List<String> _reasons = [
    'Abusive behaviour',
    'Food safety concern',
    'Harassment',
    'Suspected fraud',
    'Order issue',
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

      final cookId = _readCookId(orderData);

      if (cookId.isEmpty) {
        throw Exception(
          'The cook could not be identified.',
        );
      }

      final complaintId =
          '${widget.orderId}_${currentUser.uid}_cook';

      final complaintReference = FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId);

await complaintReference.set(
  {
    'orderId': widget.orderId,
    'submittedByUserId': currentUser.uid,
    'submittedByRole': 'customer',
    'reportedUserId': cookId,
    'reportedUserRole': 'cook',
    'category': _selectedReason,
    'description': details,
    'status': 'open',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
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

  String _readCookId(
    Map<String, dynamic> orderData,
  ) {
    final cookId =
        orderData['cookId']?.toString().trim() ?? '';

    if (cookId.isNotEmpty) {
      return cookId;
    }

    final cookIds = orderData['cookIds'];

    if (cookIds is List && cookIds.isNotEmpty) {
      return cookIds.first.toString().trim();
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
        title: const Text('Report Cook'),
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