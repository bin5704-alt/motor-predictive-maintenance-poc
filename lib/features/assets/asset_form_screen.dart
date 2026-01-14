import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/components/app_text.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_notification.dart';
import '../../theme/app_theme.dart';
import '../../data/models/asset.dart';
import '../../data/repositories/asset_repository.dart';

class AssetFormScreen extends ConsumerStatefulWidget {
  final Asset? asset; // Optional asset for editing

  const AssetFormScreen({super.key, this.asset});

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _rpmController;
  late TextEditingController _voltageController;
  late TextEditingController _bearingDEController;
  late TextEditingController _bearingNDEController;

  bool _isSubmitting = false;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    _nameController = TextEditingController(text: asset?.name ?? '');
    _rpmController = TextEditingController(
      text: asset?.specifications?['rpm']?.toString() ?? '1780',
    );
    _voltageController = TextEditingController(
      text: asset?.specifications?['voltage']?.toString() ?? '380.0',
    );

    // Safety check for bearings map
    final bearings =
        asset?.specifications?['bearings'] as Map<String, dynamic>?;
    _bearingDEController = TextEditingController(text: bearings?['de'] ?? '');
    _bearingNDEController = TextEditingController(text: bearings?['nde'] ?? '');

    _selectedType = asset?.type ?? 'Induction Motor';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rpmController.dispose();
    _voltageController.dispose();
    _bearingDEController.dispose();
    _bearingNDEController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final specifications = {
        'rpm': int.tryParse(_rpmController.text) ?? 1780,
        'voltage': double.tryParse(_voltageController.text) ?? 380.0,
        'bearings': {
          'de': _bearingDEController.text.trim(),
          'nde': _bearingNDEController.text.trim(),
        },
      };

      final repo = ref.read(assetRepositoryProvider);
      String successMessage;

      if (widget.asset != null) {
        // Update existing asset
        await repo.updateAsset(widget.asset!.id, {
          'name': _nameController.text.trim(),
          'type': _selectedType,
          'specifications': specifications,
        });
        successMessage = 'Asset Updated Successfully!';
      } else {
        // Create new asset
        final asset = Asset(
          id: 0,
          userId: user.id,
          name: _nameController.text.trim(),
          type: _selectedType,
          specifications: specifications,
          createdAt: DateTime.now(),
        );
        await repo.createAsset(asset);
        successMessage = 'Asset Registered Successfully!';
      }

      if (mounted) {
        showAppNotification(
          context,
          successMessage,
          type: NotificationType.success,
        );
        Navigator.pop(context, true); // Return success
      }

      // Refresh the asset list
      ref.invalidate(assetListProvider);
    } catch (e) {
      if (mounted) {
        showAppNotification(context, 'Error: $e', type: NotificationType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.asset != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: AppText(
          isEditing ? 'Edit Asset' : 'Register New Asset',
          size: AppTextSize.lg,
          weight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Info'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Asset Name',
                hint: 'e.g. Main Pump Motor A',
                controller: _nameController,
                validator: (v) =>
                    v?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown(),

              const SizedBox(height: 32),
              _buildSectionTitle('Specifications'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Rated RPM',
                      hint: '1780',
                      controller: _rpmController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Voltage (V)',
                      hint: '380',
                      controller: _voltageController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Bearing Model (Drive End)',
                hint: 'e.g. 6205-2RS',
                controller: _bearingDEController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Bearing Model (Non-Drive End)',
                hint: 'e.g. 6204-ZZ',
                controller: _bearingNDEController,
              ),

              const SizedBox(height: 48),
              const SizedBox(height: 48),
              AppButton(
                label: _isSubmitting
                    ? (widget.asset != null ? 'Updating...' : 'Registering...')
                    : (widget.asset != null
                          ? 'Update Asset'
                          : 'Register Asset'),
                onPressed: _isSubmitting ? null : _submit,
                variant: AppButtonVariant.primary,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return AppText(
      title,
      size: AppTextSize.md,
      color: AppTheme.accentNeonBlue,
      weight: FontWeight.bold,
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, size: AppTextSize.sm, isMuted: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText('Asset Type', size: AppTextSize.sm, isMuted: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              dropdownColor: AppTheme.surfaceDark,
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: [
                'Induction Motor',
                'Pump',
                'Fan',
                'Compressor',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
