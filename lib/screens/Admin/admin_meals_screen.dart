import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminMealsScreen extends StatelessWidget {
  const AdminMealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Meals'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('meals')
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

          final meals = snapshot.data!.docs;

          if (meals.isEmpty) {
            return const Center(
              child: Text('No meals found'),
            );
          }

          return ListView.separated(
            itemCount: meals.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final meal =
                  meals[index].data() as Map<String, dynamic>;

              final name = meal['mealName'] ?? 'Unnamed meal';
              final price = meal['price'] ?? 0;
              final cookId = meal['cookId'] ?? '';

              final ingredients =
                  meal['ingredients'] ?? 'Not provided';

              final allergens =
                  meal['allergens'] ?? 'None';

              final portions =
                  meal['remainingPortions'] ??
                  meal['portions'] ??
                  0;

              final readyTime =
                  meal['readyTimeLabel'] ??
                  'Not provided';

              final cutOffTime =
                  meal['cutOffTimeLabel'] ??
                  'Not provided';

              final status =
                  meal['status'] ?? 'Unknown';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(cookId)
                    .get(),
                builder: (context, cookSnapshot) {
                  String cookName = 'Unknown cook';

                  if (cookSnapshot.hasData) {
                    final cookData =
                        cookSnapshot.data!.data()
                            as Map<String, dynamic>?;

                    cookName =
                        cookData?['fullName'] ??
                        cookData?['email'] ??
                        'Unknown cook';
                  }

                  return ListTile(
                    leading: const Icon(
                      Icons.restaurant_menu,
                    ),
                    title: Text(name),
                    subtitle: Text(
                      '£$price • $cookName',
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: Text(name),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize:
                                    MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Price: £$price'),
                                  const SizedBox(height: 8),
                                  Text('Cook: $cookName'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ingredients: $ingredients',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Allergens: $allergens',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Remaining portions: $portions',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ready time: $readyTime',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cut-off time: $cutOffTime',
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Status: $status'),
                                ],
                              ),
                            ),
                          actions: [
  TextButton(
    onPressed: () async {
      final isActive = meal['active'] ?? true;

      await meals[index].reference.update({
        'active': !isActive,
      });

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
    },
    child: Text(
      (meal['active'] ?? true)
          ? 'Hide Meal'
          : 'Unhide Meal',
    ),
  ),
  TextButton(
    onPressed: () {
      Navigator.pop(dialogContext);
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
          );
        },
      ),
    );
  }
}