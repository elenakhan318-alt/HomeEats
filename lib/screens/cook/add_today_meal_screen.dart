import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class AddTodayMealScreen extends StatefulWidget {
  const AddTodayMealScreen({super.key});

  @override
  State<AddTodayMealScreen> createState() =>
      _AddTodayMealScreenState();
}

class _AddTodayMealScreenState
    extends State<AddTodayMealScreen> {
  final _formKey = GlobalKey<FormState>();

  final _mealNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _portionsController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _allergensController = TextEditingController();

  DateTime _mealDate = DateTime.now();

  TimeOfDay? _cutOffTime;
  TimeOfDay? _readyTime;

  bool _deliveryAvailable = true;
  bool _collectionAvailable = true;
  bool _isPublishing = false;
  bool _repeatMeal = false;

final Set<int> _selectedRepeatDays = {};

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
  void dispose() {
    _mealNameController.dispose();
    _priceController.dispose();
    _portionsController.dispose();
    _ingredientsController.dispose();
    _allergensController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  DateTime get _lastAvailableDate {
    return _today.add(
      const Duration(days: 6),
    );
  }

  Future<void> _selectMealDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _mealDate,
      firstDate: _today,
      lastDate: _lastAvailableDate,
      helpText: 'Choose meal date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _mealDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
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

  DateTime _combineDateAndTime(
    DateTime date,
    TimeOfDay time,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

    Future<void> _publishMeal() async {
    FocusScope.of(context).unfocus();

    final formIsValid =
        _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all required fields before publishing.',
          ),
        ),
      );
      return;
    }

    if (_readyTime == null || _cutOffTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose the Ready from time and Orders close time.',
          ),
        ),
      );
      return;
    }

    if (_repeatMeal && _selectedRepeatDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose at least one day for the repeat menu.',
          ),
        ),
      );
      return;
    }

    if (!_deliveryAvailable &&
        !_collectionAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose delivery, collection, or both.',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be signed in before publishing a meal.',
          ),
        ),
      );
      return;
    }

    final price = double.tryParse(
      _priceController.text.trim(),
    );

    final portions = int.tryParse(
      _portionsController.text.trim(),
    );

    if (price == null ||
        portions == null ||
        price <= 0 ||
        portions <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid price and number of portions.',
          ),
        ),
      );
      return;
    }

    final readyMinutes =
        (_readyTime!.hour * 60) +
        _readyTime!.minute;

    final closeMinutes =
        (_cutOffTime!.hour * 60) +
        _cutOffTime!.minute;

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

    final List<DateTime> mealDates = [];

    if (_repeatMeal) {
      for (var i = 0; i < 7; i++) {
        final date = _today.add(
          Duration(days: i),
        );

        if (_selectedRepeatDays.contains(
          date.weekday,
        )) {
          mealDates.add(date);
        }
      }
    } else {
      mealDates.add(
        DateTime(
          _mealDate.year,
          _mealDate.month,
          _mealDate.day,
        ),
      );
    }

    if (mealDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No matching meal days were found in the next 7 days.',
          ),
        ),
      );
      return;
    }

    for (final mealDate in mealDates) {
      final orderCloseAt =
          _combineDateAndTime(
        mealDate,
        _cutOffTime!,
      );

      if (_isSameDay(mealDate, _today) &&
          !orderCloseAt.isAfter(
            DateTime.now(),
          )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The Orders close time for today must still be in the future.',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final batch =
          FirebaseFirestore.instance.batch();

      final repeatGroupId = _repeatMeal
          ? FirebaseFirestore.instance
              .collection('mealRepeatGroups')
              .doc()
              .id
          : null;

      for (final mealDate in mealDates) {
        final readyAt =
            _combineDateAndTime(
          mealDate,
          _readyTime!,
        );

        final orderCloseAt =
            _combineDateAndTime(
          mealDate,
          _cutOffTime!,
        );

        final orderOpenAt = readyAt;

        final mealReference =
            FirebaseFirestore.instance
                .collection('meals')
                .doc();

        batch.set(
          mealReference,
          {
            'cookId': user.uid,
            'mealName':
                _mealNameController.text.trim(),
            'cuisine': _selectedCuisine,
            'price': price,
            'portions': portions,
            'remainingPortions': portions,
            'ingredients':
                _ingredientsController.text.trim(),
            'allergens':
                _allergensController.text.trim(),

            'mealDate': Timestamp.fromDate(
              DateTime(
                mealDate.year,
                mealDate.month,
                mealDate.day,
              ),
            ),

            'orderOpenAt':
                Timestamp.fromDate(orderOpenAt),
            'orderCloseAt':
                Timestamp.fromDate(orderCloseAt),
            'readyAt':
                Timestamp.fromDate(readyAt),

            'previewVisible': true,
            'sameDayOrderingOnly': true,

            'readyTime': {
              'hour': _readyTime!.hour,
              'minute': _readyTime!.minute,
            },

            'cutOffTime': {
              'hour': _cutOffTime!.hour,
              'minute': _cutOffTime!.minute,
            },

            'readyTimeLabel':
                _formatTime(_readyTime),
            'cutOffTimeLabel':
                _formatTime(_cutOffTime),
            'mealDateLabel':
                _formatMealDate(mealDate),

            'deliveryAvailable':
                _deliveryAvailable,
            'collectionAvailable':
                _collectionAvailable,

            'isRepeating': _repeatMeal,
            'repeatGroupId': repeatGroupId,
                        'status': 'available',
            'active': true,

            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (!mounted) {
        return;
      }

      final message = _repeatMeal
          ? '${_mealNameController.text.trim()} has been added for ${mealDates.length} selected day${mealDates.length == 1 ? '' : 's'}.'
          : '${_mealNameController.text.trim()} has been added to the menu for ${_formatMealDate(mealDates.first)}.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
                'Firebase could not save the meal. Error: ${error.code}',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Publishing error: $error');
      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The meal could not be published: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }
  bool _isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return 'Choose time';
    }

    return time.format(context);
  }

  String _formatMealDate(DateTime date) {
    if (_isSameDay(date, _today)) {
      return 'Today';
    }

    final tomorrow =
        _today.add(const Duration(days: 1));

    if (_isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    }

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Meal to Menu'),
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
                    if (value == null || value.trim().isEmpty) {
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
                  onChanged: _isPublishing
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
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _priceController,
                        label: 'Price per portion',
                        hint: '9.95',
                        keyboardType:
                            const TextInputType.numberWithOptions(
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

                    const SizedBox(width: AppSpacing.regular),

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

                          if (portions == null || portions <= 0) {
                            return 'Enter portions.';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                                const SizedBox(height: AppSpacing.large),

                const Text(
                  'Menu schedule',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'You can show customers what you may be cooking up to '
                  '7 days ahead. Future meals are for viewing only and '
                  'cannot be reserved or paid for. On the meal day, '
                  'customers can order from the Ready from time until '
                  'Orders close, while portions remain available.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: AppSpacing.regular),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                    AppSpacing.regular,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppRadius.card,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How long is this meal available?',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isPublishing
                                  ? null
                                  : () {
                                      setState(() {
                                        _repeatMeal = false;
                                        _selectedRepeatDays.clear();
                                      });
                                    },
                              child: const Text(
                                'One day',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isPublishing
                                  ? null
                                  : () {
                                      setState(() {
                                        _repeatMeal = true;
                                      });
                                    },
                              child: const Text(
                                'Repeat menu',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      if (_repeatMeal) ...[
                        const SizedBox(height: 8),

                        const Text(
                          'Choose days',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildRepeatDayChip(
                              day: DateTime.monday,
                              label: 'Mon',
                            ),
                            _buildRepeatDayChip(
                              day: DateTime.tuesday,
                              label: 'Tue',
                            ),
                            _buildRepeatDayChip(
                              day: DateTime.wednesday,
                              label: 'Wed',
                            ),
                            _buildRepeatDayChip(
                              day: DateTime.thursday,
                              label: 'Thu',
                            ),
                            _buildRepeatDayChip(
                              day: DateTime.friday,
                              label: 'Fri',
                            ),
                            _buildRepeatDayChip(
                              day: DateTime.saturday,
                              label: 'Sat',
                            ),
                            _buildRepeatDayChip(
                              day: DateTime.sunday,
                              label: 'Sun',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.regular,
                ),
                _buildScheduleCard(
                  title: 'Meal date',
                  value: _formatMealDate(_mealDate),
                  icon: Icons.calendar_month_rounded,
                  onTap: _selectMealDate,
                ),

                const SizedBox(height: AppSpacing.regular),

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
                  hint: 'Rice, chicken, onions, spices...',
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the ingredients.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.regular),

                _buildTextField(
                  controller: _allergensController,
                  label: 'Allergens',
                  hint: 'Example: Milk, nuts, gluten, or none',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
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
                        _isPublishing ? null : _publishMeal,
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.publish_rounded),
                    label: Text(
                      _isPublishing
                          ? 'Publishing...'
                          : 'Publish Meal',
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
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Photo upload will be connected next.',
              ),
            ),
          );
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 44,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacing.small),
            Text(
              'Add a meal photo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Use a clear photo of the food',
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.medium,
          ),
        ),
      ),
    );
  }
    Widget _buildScheduleCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        AppRadius.card,
      ),
      child: InkWell(
        onTap: _isPublishing ? null : onTap,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.regular,
          ),
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

  Widget _buildTimeCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _buildScheduleCard(
      title: title,
      value: value,
      icon: icon,
      onTap: onTap,
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
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
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
            onChanged: _isPublishing
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
            onChanged: _isPublishing
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
    Widget _buildRepeatDayChip({
    required int day,
    required String label,
  }) {
    final selected =
        _selectedRepeatDays.contains(day);

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: _isPublishing
          ? null
          : (isSelected) {
              setState(() {
                if (isSelected) {
                  _selectedRepeatDays.add(day);
                } else {
                  _selectedRepeatDays.remove(day);
                }
              });
            },
    );
  }
}