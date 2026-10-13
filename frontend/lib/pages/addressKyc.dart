import 'package:flutter/material.dart';

import '../models/veriadd_kyc_request.dart';
import '../services/veriadd_kyc_service.dart';

class AddressKycScreen extends StatefulWidget {
  const AddressKycScreen({super.key});

  @override
  State<AddressKycScreen> createState() => _AddressKycScreenState();
}

class _AddressKycScreenState extends State<AddressKycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postcodeController = TextEditingController(text: 'LA-11-W06-TC-10');
  final _stateController = TextEditingController(text: 'LAGOS');
  final _bvnController = TextEditingController(text: '22233344455');
  final _phoneController = TextEditingController(text: '08031234567');
  final _levelController = TextEditingController(text: '3');

  bool _isSubmitting = false;
  String? _resultMessage;
  Color _resultColor = Colors.black;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _resultMessage = null;
    });

    try {
      final request = VeriaddKycRequest(
        postcode: _postcodeController.text.trim(),
        state: _stateController.text.trim(),
        bvn: _bvnController.text.trim(),
        phone: _phoneController.text.trim(),
        level: int.tryParse(_levelController.text.trim()) ?? 3,
      );

      final result = await VeriaddKycService().verifyAddress(request);
      setState(() {
        _resultMessage =
            'Status: ${result.status} | Confidence: ${result.confidence} | Verified: ${result.verified}';
        _resultColor = result.verified ? Colors.green : Colors.orange;
      });
    } catch (error) {
      setState(() {
        _resultMessage = 'Verification failed: $error';
        _resultColor = Colors.red;
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Address KYC'),
        backgroundColor: const Color(0xFF4ECDC4),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Verify a customer address and identity through the backend.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildField('Postcode', _postcodeController, validator: _nonEmptyValidator),
                const SizedBox(height: 12),
                _buildField('State', _stateController, validator: _nonEmptyValidator),
                const SizedBox(height: 12),
                _buildField('BVN', _bvnController, validator: _bvnValidator),
                const SizedBox(height: 12),
                _buildField('Phone', _phoneController, validator: _phoneValidator),
                const SizedBox(height: 12),
                _buildField('Level', _levelController, validator: _levelValidator),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify address'),
                ),
                if (_resultMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _resultColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _resultMessage!,
                      style: TextStyle(
                        color: _resultColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String? _nonEmptyValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _bvnValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'BVN is required';
    }
    if (!RegExp(r'^\d{11}$').hasMatch(value.trim())) {
      return 'BVN must be exactly 11 digits';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone is required';
    }
    if (!RegExp(r'^(\+?\d{8,15})$').hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _levelValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Level is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1 || parsed > 5) {
      return 'Level must be between 1 and 5';
    }
    return null;
  }

  @override
  void dispose() {
    _postcodeController.dispose();
    _stateController.dispose();
    _bvnController.dispose();
    _phoneController.dispose();
    _levelController.dispose();
    super.dispose();
  }
}
