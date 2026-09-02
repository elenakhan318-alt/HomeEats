import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class EditTodayMealScreen extends StatefulWidget {
  const EditTodayMealScreen({
    super.key,
    required this.mealId,
    required this.mealData,
  });

  final String mealId;
  final Map<String, dynamic> mealData;

  @override
  State<EditTodayMealScreen> createState() =>
      _EditTodayMealScreenState();
}

class _EditTodayMealScreenState extends State<EditTodayMealScreen> {
  final _formKey = GlobalKey<FormState>();

  final _mealNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _portionsController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _allergensController = TextEditingController();

  TimeOfDay? _readyTime;
  TimeOfDay? _cutOffTime;

  bool _deliveryAvailable = true;
  bool _collectionAvailable = true;
  bool _isSaving = false;

  String _selectedCuisine = 'Pakistani';

  final List<String> _cuisines = const [
    'Pakistani',
    'Caribbean',
    'Mediterranean',
    'Indian',
    'Italian',
    'Chinese',
    'African',
    'British',
  ];

  @override
  void initState() {
    super.initState();
    _loadMealDetails();
  }

  void _loadMealDetails() {
    final data = widget.mealData;

    _mealNameController.text =
        (data['mealName'] ?? '').toString();

    final price = data['price'];
    _priceController.text = price == null
        ? ''
        : price.toString();

    final portions = data['portions'];
    _portionsController.text = portions == null
        ? ''
        : portions.toString();

    _ingredientsController.text =
        (data['ingredients'] ?? '').toString();

    _allergensController.text =
        (data['allergens'] ?? '').toString();

    final savedCuisine =
        (data['cuisine'] ?? 'Pakistani').toString();

    if (_cuisines.contains(savedCuisine)) {
      _selectedCuisine = savedCuisine;
    }

    _deliveryAvailable =
        data['deliveryAvailable'] as bool? ?? true;

    _collectionAvailable =
        data['collectionAvailable'] as bool? ?? true;

    _readyTime = _timeFromFirestore(data['readyTime']);
    _cutOffTime = _timeFromFirestore(data['cutOffTime']);
  }

  TimeOfDay? _timeFromFirestore(dynamic value) {
    if (value is! Map) {
      return null;
    }

    final hourValue = value['hour'];
    final minuteValue = value['minute'];

    final hour = hourValue is int
        ? hourValue
        : int.tryParse(hourValue?.toString() ?? '');

    final minute = minuteValue is int
        ? minuteValue
        : int.tryParse(minuteValue?.toString() ?? '');

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _priceController.dispose();
    _portionsController.dispose();
    _ingredientsController.dispose();
    _allergensController.dispose();
    super.dispose();
  }

  Future<void> _selectReadyTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _readyTime ?? TimeOfDay.now(),
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _readyTime = selectedTime;
    });
  }

  Future<void> _selectCutOffTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _cutOffTime ?? TimeOfDay.now(),
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _cutOffTime = selectedTime;
    });
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    final formIsValid =
        _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all required fields.',
          ),
        ),
      );
      return;
    }

    if (_readyTime == null || _cutOffTime == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Please choose both the Ready from time and Orders close time.',
      ),
    ),
  );
  return;
}

final readyMinutes =
    (_readyTime!.hour * 60) + _readyTime!.minute;

final closeMinutes =
    (_cutOffTime!.hour * 60) + _cutOffTime!.minute;

if (closeMinutes <= readyMinutes) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Orders close must be later than the Ready from time.',
      ),
    ),
  );
  return;
}

    if (!_deliveryAvailable && !_collectionAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose delivery, collection, or both.',
          ),
        ),
      );
      return;
    }

    final price =
        double.tryParse(_priceController.text.trim());

    final newTotalPortions =
        int.tryParse(_portionsController.text.trim());

    if (price == null || newTotalPortions == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid price and number of portions.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final previousTotal =
          _readInt(widget.mealData['portions']);

      final previousRemaining =
          _readInt(widget.mealData['remainingPortions']);

      final soldPortions = math.max(
        0,
        previousTotal - previousRemaining,
      );

      final newRemainingPortions = math.max(
        0,
        newTotalPortions - soldPortions,
      );
final mealDateValue = widget.mealData['mealDate'];

if (mealDateValue is! Timestamp) {
  if (!mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'The meal date could not be found.',
      ),
    ),
  );
  return;
}

final mealDate = mealDateValue.toDate();

final readyAt = DateTime(
  mealDate.year,
  mealDate.month,
  mealDate.day,
  _readyTime!.hour,
  _readyTime!.minute,
);

final orderCloseAt = DateTime(
  mealDate.year,
  mealDate.month,
  mealDate.day,
  _cutOffTime!.hour,
  _cutOffTime!.minute,
);
      await FirebaseFirestore.instance
          .collection('meals')
          .doc(widget.mealId)
          .update({
        'mealName': _mealNameController.text.trim(),
        'cuisine': _selectedCuisine,
        'price': price,
        'portions': newTotalPortions,
        'remainingPortions': newRemainingPortions,
        'ingredients':
            _ingredientsController.text.trim(),
        'allergens':
            _allergensController.text.trim(),
        'readyTime': {
          'hour': _readyTime!.hour,
          'minute': _readyTime!.minute,
        },
        'cutOffTime': {
          'hour': _cutOffTime!.hour,
          'minute': _cutOffTime!.minute,
        },
        'readyTimeLabel': _formatTime(_readyTime),
        'cutOffTimeLabel': _formatTime(_cutOffTime),
        'readyAt': Timestamp.fromDate(readyAt),
'orderOpenAt': Timestamp.fromDate(readyAt),
'orderCloseAt': Timestamp.fromDate(orderCloseAt),
        'deliveryAvailable': _deliveryAvailable,
        'collectionAvailable': _collectionAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_mealNameController.text.trim()} has been updated.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'The meal could not be updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The meal could not be updated: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return 'Choose time';
    }

    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Meal'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.regular,
              AppSpacing.page,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoSection(),
                const SizedBox(height: AppSpacing.large),
                _buildTextField(
                  controller: _mealNameController,
                  label: 'Meal name',
                  hint: 'Example: Chicken Biryani',
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter a meal name.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.regular),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCuisine,
                  decoration: InputDecoration(
                    labelText: 'Cuisine',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppRadius.medium,
                      ),
                    ),
                  ),
                  items: _cuisines.map((cuisine) {
                    return DropdownMenuItem<String>(
                      value: cuisine,
                      child: Text(cuisine),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedCuisine = value;
                          });
                        },
                ),
                const SizedBox(height: AppSpacing.regular),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _priceController,
                        label: 'Price per portion',
                        hint: '9.95',
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        prefixText: '£',
                        validator: (value) {
                          final price = double.tryParse(
                            value?.trim() ?? '',
                          );

                          if (price == null || price <= 0) {
                            return 'Enter a valid price.';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(
                      width: AppSpacing.regular,
                    ),
                    Expanded(
                      child: _buildTextField(
                        controller: _portionsController,
                        label: 'Portions available',
                        hint: '10',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final portions = int.tryParse(
                            value?.trim() ?? '',
                          );

                          if (portions == null ||
                              portions <= 0) {
                            return 'Enter portions.';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.large),
                _buildTimeCard(
                  title: 'Ready from',
                  value: _formatTime(_readyTime),
                  icon: Icons.schedule_rounded,
                  onTap: _selectReadyTime,
                ),
                const SizedBox(height: AppSpacing.regular),
                _buildTimeCard(
                  title: 'Orders close',
                  value: _formatTime(_cutOffTime),
                  icon: Icons.timer_outlined,
                  onTap: _selectCutOffTime,
                ),
                const SizedBox(height: AppSpacing.large),
                _buildFulfilmentSection(),
                const SizedBox(height: AppSpacing.large),
                _buildTextField(
                  controller: _ingredientsController,
                  label: 'Ingredients',
                  hint:
                      'Rice, chicken, onions, spices...',
                  maxLines: 4,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter the ingredients.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.regular),
                _buildTextField(
                  controller: _allergensController,
                  label: 'Allergens',
                  hint:
                      'Example: Milk, nuts, gluten, or none',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter allergen information.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.large),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed:
                        _isSaving ? null : _saveChanges,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
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

  Widget _buildPhotoSection() {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color:
              AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(AppRadius.card),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Photo editing will be connected next.',
              ),
            ),
          );
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_outlined,
              size: 44,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacing.small),
            Text(
              'Change meal photo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Meal photo upload will be added next',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      enabled: !_isSaving,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: _isSaving ? null : onTap,
        borderRadius:
            BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding:
              const EdgeInsets.all(AppSpacing.regular),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(
                width: AppSpacing.regular,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFulfilmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AppSpacing.regular,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How can customers receive this meal?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _deliveryAvailable,
            title: const Text('Delivery'),
            subtitle: const Text(
              'You can deliver this meal',
            ),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _deliveryAvailable =
                          value ?? false;
                    });
                  },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _collectionAvailable,
            title: const Text('Collection'),
            subtitle: const Text(
              'Customer can collect from you',
            ),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _collectionAvailable =
                          value ?? false;
                    });
                  },
          ),
        ],
      ),
    );
  }
}