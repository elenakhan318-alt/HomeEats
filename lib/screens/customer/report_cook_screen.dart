import 'package:flutter/material.dart';

class ReportCookScreen extends StatelessWidget {
  const ReportCookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Cook'),
      ),
      body: const Center(
        child: Text(
          'Complaint form coming soon.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}