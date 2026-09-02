import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ContactHomeEatsScreen extends StatefulWidget {
  const ContactHomeEatsScreen({super.key});

  @override
  State<ContactHomeEatsScreen> createState() =>
      _ContactHomeEatsScreenState();
}

class _ContactHomeEatsScreenState
    extends State<ContactHomeEatsScreen> {
  final TextEditingController _detailsController =
      TextEditingController();

  final List<String> _issueTypes = [
    'Account issue',
    'Meal issue',
    'Order issue',
    'Payment issue',
    'Verification issue',
    'Technical problem',
    'General question',
    'Other',
  ];

  String? _selectedIssue;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    final details = _detailsController.text.trim();

    if (user == null) {
      _showMessage('You must be signed in.');
      return;
    }

    if (_selectedIssue == null) {
      _showMessage('Please select an issue type.');
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
      await FirebaseFirestore.instance
          .collection('complaints')
          .add({
        'submittedByUserId': user.uid,
        'submittedByRole': 'cook',
        'category': _selectedIssue,
        'description': details,
        'status': 'open',
        'type': 'contact_homeeats',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your message has been sent to HomeEats.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Your message could not be sent: $error',
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
      appBar: AppBar(
        title: const Text('Contact HomeEats'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.support_agent_rounded,
              size: 60,
            ),
            const SizedBox(height: 16),

            const Text(
              'How can we help?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Send a message to the HomeEats team and we will review your request.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            DropdownButtonFormField<String>(
              initialValue: _selectedIssue,
              decoration: const InputDecoration(
                labelText: 'Issue type',
                border: OutlineInputBorder(),
              ),
              items: _issueTypes.map((issue) {
                return DropdownMenuItem<String>(
                  value: issue,
                  child: Text(issue),
                );
              }).toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _selectedIssue = value;
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
                labelText: 'Tell us what you need help with',
                hintText: 'Please provide details.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _isSubmitting
                      ? 'Sending...'
                      : 'Send to HomeEats',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}