import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminBusinessSettingsScreen extends StatefulWidget {
  const AdminBusinessSettingsScreen({super.key});

  @override
  State<AdminBusinessSettingsScreen> createState() =>
      _AdminBusinessSettingsScreenState();
}

class _AdminBusinessSettingsScreenState
    extends State<AdminBusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _setupFeeController = TextEditingController();
  final _goLiveFeeController = TextEditingController();
  final _commissionController = TextEditingController();

  bool _platformOpen = true;
  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>> get _settingsReference =>
      FirebaseFirestore.instance
          .collection('settings')
          .doc('business');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _setupFeeController.dispose();
    _goLiveFeeController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final snapshot = await _settingsReference.get();
      final data = snapshot.data() ?? <String, dynamic>{};

      final setupFeePence =
          (data['setupFeePence'] as num?)?.toInt() ?? 10000;

      final goLiveFeePence =
          (data['goLiveFeePence'] as num?)?.toInt() ?? 10000;

      final commissionPercent =
          (data['commissionPercent'] as num?)?.toDouble() ?? 10;

      _setupFeeController.text =
          (setupFeePence / 100).toStringAsFixed(2);

      _goLiveFeeController.text =
          (goLiveFeePence / 100).toStringAsFixed(2);

      _commissionController.text =
          commissionPercent.toStringAsFixed(
        commissionPercent % 1 == 0 ? 0 : 2,
      );

      _platformOpen =
          data['platformStatus']?.toString() != 'closed';
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Business settings could not be loaded: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final setupFee =
        double.tryParse(_setupFeeController.text.trim()) ?? 0;

    final goLiveFee =
        double.tryParse(_goLiveFeeController.text.trim()) ?? 0;

    final commissionPercent =
        double.tryParse(_commissionController.text.trim()) ?? 0;

    setState(() {
      _saving = true;
    });

    try {
      await _settingsReference.set(
        {
          'setupFeePence': (setupFee * 100).round(),
          'goLiveFeePence': (goLiveFee * 100).round(),
          'commissionPercent': commissionPercent,
          'currency': 'gbp',
          'platformStatus':
              _platformOpen ? 'open' : 'closed',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business settings saved.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Business settings could not be saved: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String? _validateMoney(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');

    if (amount == null || amount < 0) {
      return 'Enter a valid amount';
    }

    return null;
  }

  String? _validateCommission(String? value) {
    final percentage = double.tryParse(value?.trim() ?? '');

    if (percentage == null ||
        percentage < 0 ||
        percentage > 100) {
      return 'Enter a percentage between 0 and 100';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Cook fees',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
TextFormField(
  controller: _setupFeeController,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
  ),
  decoration: const InputDecoration(
    labelText: 'Setup fee',
    prefixIcon: Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
      ),
      child: Text(
        '£',
        style: TextStyle(
          fontSize: 16,
        ),
      ),
    ),
    prefixIconConstraints: BoxConstraints(
      minWidth: 0,
      minHeight: 0,
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(),
  ),
  validator: _validateMoney,
),

const SizedBox(height: 16),
                 TextFormField(
  controller: _goLiveFeeController,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
  ),
  decoration: const InputDecoration(
    labelText: 'Go-live fee',
  prefixIcon: Padding(
  padding: EdgeInsets.only(
    left: 16,
    right: 8,
  ),
  child: Text(
    '£',
    style: TextStyle(
      fontSize: 16,
    ),
  ),
),
prefixIconConstraints: BoxConstraints(
  minWidth: 0,
  minHeight: 0,
),
contentPadding: EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 16,
),
border: OutlineInputBorder(),
  ),
  validator: _validateMoney,
),
           const SizedBox(height: 24),
const Text(
  'Order commission',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
  ),
),
const SizedBox(height: 16),

TextFormField(
  controller: _commissionController,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
  ),
  decoration: const InputDecoration(
    labelText: 'Commission percentage',
    suffixText: '%',
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(),
  ),
  validator: _validateCommission,
),

const SizedBox(height: 24),

SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text(
    'Platform open',
    style: TextStyle(
      fontWeight: FontWeight.w800,
    ),
  ),
  subtitle: Text(
    _platformOpen
        ? 'Customers can place orders.'
        : 'Ordering is temporarily closed.',
  ),
  value: _platformOpen,
  onChanged: (value) {
    setState(() {
      _platformOpen = value;
    });
  },
),

const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _saving ? null : _saveSettings,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _saving
                            ? 'Saving...'
                            : 'Save Settings',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}