import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_edit_meal_screen.dart';

class AdminMealsScreen extends StatelessWidget {
  const AdminMealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Meals'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('meals')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final meals = snapshot.data?.docs ?? [];

          if (meals.isEmpty) {
            return const Center(
              child: Text('No meals found'),
            );
          }

          return ListView.separated(
            itemCount: meals.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final mealDocument = meals[index];
              final meal = mealDocument.data();

              final name =
                  meal['mealName']?.toString() ??
                      'Unnamed meal';

              final priceValue = meal['price'];
              final price = priceValue is num
                  ? priceValue.toDouble()
                  : double.tryParse(
                        priceValue?.toString() ?? '',
                      ) ??
                      0;

              final cookId =
                  meal['cookId']?.toString() ?? '';

              final ingredients =
                  meal['ingredients']?.toString() ??
                      'Not provided';

              final allergens =
                  meal['allergens']?.toString() ??
                      'None';

              final portions =
                  meal['remainingPortions'] ??
                      meal['portions'] ??
                      0;

              final readyTime =
                  meal['readyTimeLabel']?.toString() ??
                      'Not provided';

              final cutOffTime =
                  meal['cutOffTimeLabel']?.toString() ??
                      'Not provided';

              final status =
                  meal['status']?.toString() ??
                      'Unknown';

              final isActive =
                  meal['active'] != false;

              return FutureBuilder<
                  DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(cookId)
                    .get(),
                builder: (context, cookSnapshot) {
                  String cookName = 'Unknown cook';

                  final cookData =
                      cookSnapshot.data?.data();

                  if (cookData != null) {
                    cookName =
                        cookData['fullName']?.toString() ??
                            cookData['email']?.toString() ??
                            'Unknown cook';
                  }

                  return ListTile(
                    leading: Icon(
                      isActive
                          ? Icons.restaurant_menu
                          : Icons.visibility_off_rounded,
                      color: isActive
                          ? Colors.green
                          : Colors.grey,
                    ),
                    title: Text(name),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '£${price.toStringAsFixed(2)} • $cookName',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isActive
                              ? 'Visible'
                              : 'Hidden',
                          style: TextStyle(
                            color: isActive
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit meal',
                          icon: const Icon(
                            Icons.edit_outlined,
                          ),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminEditMealScreen(
                                  mealId:
                                      mealDocument.id,
                                  mealData: meal,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: isActive
                              ? 'Hide meal'
                              : 'Show meal',
                          icon: Icon(
                            isActive
                                ? Icons
                                    .visibility_off_rounded
                                : Icons
                                    .visibility_rounded,
                          ),
                          onPressed: () async {
                            await mealDocument.reference
                                .update({
                              'active': !isActive,
                              'updatedAt':
                                  FieldValue
                                      .serverTimestamp(),
                            });
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete meal',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final shouldDelete =
                                await showDialog<bool>(
                              context: context,
                              builder: (
                                dialogContext,
                              ) {
                                return AlertDialog(
                                  title: const Text(
                                    'Delete meal',
                                  ),
                                  content: Text(
                                    'Are you sure you want to permanently delete "$name"?\n\nThis action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(
                                          dialogContext,
                                          false,
                                        );
                                      },
                                      child:
                                          const Text(
                                        'Cancel',
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(
                                          dialogContext,
                                          true,
                                        );
                                      },
                                      child:
                                          const Text(
                                        'Delete',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (shouldDelete == true) {
                              try {
                                await mealDocument.reference
                                    .delete();

                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$name deleted',
                                    ),
                                  ),
                                );
                              } catch (error) {
                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Meal could not be deleted: $error',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (
                          dialogContext,
                        ) {
                          return AlertDialog(
                            title: Text(name),
                            content:
                                SingleChildScrollView(
                              child: Column(
                                mainAxisSize:
                                    MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    'Price: £${price.toStringAsFixed(2)}',
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Cook: $cookName',
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Visibility: ${isActive ? 'Visible' : 'Hidden'}',
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Ingredients: $ingredients',
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Allergens: $allergens',
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Remaining portions: $portions',
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Ready time: $readyTime',
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Cut-off time: $cutOffTime',
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Status: $status',
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton.icon(
                                onPressed: () async {
                                  await mealDocument
                                      .reference
                                      .update({
                                    'active':
                                        !isActive,
                                    'updatedAt':
                                        FieldValue
                                            .serverTimestamp(),
                                  });

                                  if (dialogContext
                                      .mounted) {
                                    Navigator.pop(
                                      dialogContext,
                                    );
                                  }
                                },
                                icon: Icon(
                                  isActive
                                      ? Icons
                                          .visibility_off_rounded
                                      : Icons
                                          .visibility_rounded,
                                ),
                                label: Text(
                                  isActive
                                      ? 'Hide Meal'
                                      : 'Show Meal',
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(
                                    dialogContext,
                                  );
                                },
                                child:
                                    const Text('Close'),
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