import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() =>
      _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  String _selectedFilter = 'All';

  Future<String> _getUserName(String userId) async {
    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final userData = userDocument.data();

    if (!userDocument.exists || userData == null) {
      return userId;
    }

    return (userData['fullName'] ??
            userData['name'] ??
            userData['email'] ??
            userId)
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            tooltip: 'Filter complaints',
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'All',
                  child: Text('All'),
                ),
                PopupMenuItem(
                  value: 'Open',
                  child: Text('Open'),
                ),
                PopupMenuItem(
                  value: 'Resolved',
                  child: Text('Resolved'),
                ),
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allComplaints = snapshot.data?.docs ?? [];

          final complaints = allComplaints.where((document) {
            final complaint =
                document.data() as Map<String, dynamic>;

            final status =
                (complaint['status'] ?? 'open')
                    .toString()
                    .toLowerCase();

            if (_selectedFilter == 'Open') {
              return status == 'open';
            }

            if (_selectedFilter == 'Resolved') {
              return status == 'resolved';
            }

            return true;
          }).toList();

          if (complaints.isEmpty) {
            return Center(
              child: Text(
                _selectedFilter == 'All'
                    ? 'No complaints found'
                    : 'No ${_selectedFilter.toLowerCase()} complaints',
              ),
            );
          }

          return ListView.separated(
            itemCount: complaints.length,
            separatorBuilder: (context, index) {
              return const Divider(height: 1);
            },
            itemBuilder: (context, index) {
              final complaintDocument = complaints[index];

              final complaint =
                  complaintDocument.data()
                      as Map<String, dynamic>;

              final subject =
                  (complaint['category'] ?? 'Complaint')
                      .toString();

              final message =
                  (complaint['description'] ??
                          'No details provided')
                      .toString();

              final submittedByRole =
                  (complaint['submittedByRole'] ??
                          'Unknown role')
                      .toString();

              final submittedByUserId =
                  (complaint['submittedByUserId'] ??
                          'Unknown user')
                      .toString();

              final status =
                  (complaint['status'] ?? 'open')
                      .toString()
                      .toLowerCase();

              final createdAt =
                  complaint['createdAt'] as Timestamp?;

              final submittedAt = createdAt == null
                  ? 'No date recorded'
                  : DateFormat(
                      'dd MMM yyyy • HH:mm',
                    ).format(createdAt.toDate());

              final userNameFuture =
                  _getUserName(submittedByUserId);

              return ListTile(
                leading: Icon(
                  status == 'resolved'
                      ? Icons.check_circle
                      : Icons.report_problem,
                  color: status == 'resolved'
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text(subject),
                subtitle: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: userNameFuture,
                      builder: (context, userSnapshot) {
                        final userName =
                            userSnapshot.data ??
                            submittedByUserId;

                        return Text(
                          '$submittedByRole • $userName',
                        );
                      },
                    ),
                    Text(
                      '$status • $submittedAt',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: Text(subject),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Submitted by role: '
                                '$submittedByRole',
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<String>(
                                future: userNameFuture,
                                builder:
                                    (context, userSnapshot) {
                                  final userName =
                                      userSnapshot.data ??
                                      submittedByUserId;

                                  return Text(
                                    'Submitted by: $userName',
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Text('Status: $status'),
                              const SizedBox(height: 8),
                              Text(
                                'Submitted: $submittedAt',
                              ),
                              const SizedBox(height: 16),
                              Text(message),
                            ],
                          ),
                        ),
                        actions: [
                          if (status != 'resolved')
                            TextButton(
                              onPressed: () async {
                                await complaintDocument
                                    .reference
                                    .update({
                                  'status': 'resolved',
                                  'resolvedAt':
                                      FieldValue
                                          .serverTimestamp(),
                                  'updatedAt':
                                      FieldValue
                                          .serverTimestamp(),
                                });

                                if (dialogContext.mounted) {
                                  Navigator.pop(
                                    dialogContext,
                                  );
                                }
                              },
                              child: const Text(
                                'Mark Resolved',
                              ),
                            ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}