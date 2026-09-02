import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminEditMealScreen extends StatefulWidget {
  const AdminEditMealScreen({
    super.key,
    required this.mealId,
    required this.mealData,
  });

  final String mealId;
  final Map<String, dynamic> mealData;

  @override
  State<AdminEditMealScreen> createState() =>
      _AdminEditMealScreenState();
}

class _AdminEditMealScreenState
    extends State<AdminEditMealScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _mealNameController;
  late final TextEditingController _priceController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _allergensController;
  late final TextEditingController _portionsController;
  late final TextEditingController _readyTimeController;
  late final TextEditingController _cutOffTimeController;

  bool _deliveryAvailable = false;
  bool _collectionAvailable = false;
  bool _isSaving = false;
  XFile? _selectedImage;
String? _existingImageUrl;
bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();

    final data = widget.mealData;

    _mealNameController = TextEditingController(
      text: data['mealName']?.toString() ?? '',
    );

    _priceController = TextEditingController(
      text: data['price']?.toString() ?? '',
    );

    _ingredientsController = TextEditingController(
      text: data['ingredients']?.toString() ?? '',
    );

    _allergensController = TextEditingController(
      text: data['allergens']?.toString() ?? '',
    );

    _portionsController = TextEditingController(
      text: (
        data['remainingPortions'] ??
        data['portions'] ??
        ''
      ).toString(),
    );

    _readyTimeController = TextEditingController(
      text: data['readyTimeLabel']?.toString() ?? '',
    );

    _cutOffTimeController = TextEditingController(
      text: data['cutOffTimeLabel']?.toString() ?? '',
    );

    _deliveryAvailable =
        data['deliveryAvailable'] == true;

    _collectionAvailable =
        data['collectionAvailable'] == true;
        _existingImageUrl =
    data['imageUrl']?.toString();
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _priceController.dispose();
    _ingredientsController.dispose();
    _allergensController.dispose();
    _portionsController.dispose();
    _readyTimeController.dispose();
    _cutOffTimeController.dispose();
    super.dispose();
  }
Future<void> _pickMealImage() async {
  final ImagePicker picker = ImagePicker();

  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );

  if (image == null) {
    return;
  }

  setState(() {
    _selectedImage = image;
  });
}
Future<String?> _uploadSelectedImage() async {
  if (_selectedImage == null) {
    return _existingImageUrl;
  }

  setState(() {
    _isUploadingImage = true;
  });

  try {
    final bytes = await _selectedImage!.readAsBytes();

    final String safeFileName = _selectedImage!.name.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );

    final Reference imageReference =
        FirebaseStorage.instance
            .ref()
            .child(
              'meal_images/${widget.mealId}/${DateTime.now().millisecondsSinceEpoch}_$safeFileName',
            );

    await imageReference.putData(bytes);

    return await imageReference.getDownloadURL();
  } finally {
    if (mounted) {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }
}
  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = double.tryParse(
      _priceController.text.trim(),
    );

    final portions = int.tryParse(
      _portionsController.text.trim(),
    );

    if (price == null || portions == null) {
      return;
    }

    if (!_deliveryAvailable &&
        !_collectionAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select delivery, collection, or both.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String? imageUrl =
    await _uploadSelectedImage();
      await FirebaseFirestore.instance
          .collection('meals')
          .doc(widget.mealId)
          .update({
        'mealName':
            _mealNameController.text.trim(),
        'price': price,
        'ingredients':
            _ingredientsController.text.trim(),
        'allergens':
            _allergensController.text.trim(),
        'remainingPortions': portions,
        'portions': portions,
        'readyTimeLabel':
            _readyTimeController.text.trim(),
        'cutOffTimeLabel':
            _cutOffTimeController.text.trim(),
        'deliveryAvailable':
            _deliveryAvailable,
        'collectionAvailable':
            _collectionAvailable,
            'imageUrl': imageUrl,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal updated successfully'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meal could not be updated: $error',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Meal'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
  'Meal photo',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  ),
),
const SizedBox(height: 12),

if (_existingImageUrl != null &&
    _existingImageUrl!.isNotEmpty &&
    _selectedImage == null)
  ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      _existingImageUrl!,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  ),

if (_selectedImage != null)
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      'New photo selected: ${_selectedImage!.name}',
      style: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

const SizedBox(height: 12),

OutlinedButton.icon(
  onPressed: _isUploadingImage || _isSaving
      ? null
      : _pickMealImage,
  icon: const Icon(Icons.photo_library_outlined),
  label: Text(
    _existingImageUrl != null &&
            _existingImageUrl!.isNotEmpty
        ? 'Change meal photo'
        : 'Choose meal photo',
  ),
),

const SizedBox(height: 24),
              TextFormField(
                controller: _mealNameController,
                decoration: const InputDecoration(
                  labelText: 'Meal name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter a meal name';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '£',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final price = double.tryParse(
                    value?.trim() ?? '',
                  );

                  if (price == null || price <= 0) {
                    return 'Enter a valid price';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Portions',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final portions = int.tryParse(
                    value?.trim() ?? '',
                  );

                  if (portions == null ||
                      portions < 0) {
                    return 'Enter a valid number of portions';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ingredientsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ingredients',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _allergensController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Allergens',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _readyTimeController,
                decoration: const InputDecoration(
                  labelText: 'Ready time',
                  hintText: 'For example, 7:00 PM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cutOffTimeController,
                decoration: const InputDecoration(
                  labelText: 'Cut-off time',
                  hintText: 'For example, 10:00 PM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _deliveryAvailable,
                onChanged: (value) {
                  setState(() {
                    _deliveryAvailable = value;
                  });
                },
                title: const Text(
                  'Delivery available',
                ),
              ),
              SwitchListTile(
                value: _collectionAvailable,
                onChanged: (value) {
                  setState(() {
                    _collectionAvailable = value;
                  });
                },
                title: const Text(
                  'Collection available',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed:
                    _isSaving ? null : _saveMeal,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save_rounded,
                      ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Save Changes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}