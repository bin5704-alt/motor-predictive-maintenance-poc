import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/components/app_text.dart';
import '../../theme/app_theme.dart';
import '../../data/models/maintenance_log.dart';
import '../../data/services/asset_service.dart';
import '../../core/components/app_notification.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final int diagnosisId;
  final MaintenanceLog? logToEdit;

  const MaintenanceFormScreen({
    super.key,
    required this.diagnosisId,
    this.logToEdit,
  });

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actionController = TextEditingController();
  final _partsController = TextEditingController();
  final _costController = TextEditingController();
  final _technicianController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.logToEdit != null) {
      final log = widget.logToEdit!;
      _actionController.text = log.actionTaken;
      _partsController.text = log.partsReplaced ?? '';
      _costController.text = log.cost.toString();
      _technicianController.text = log.technician ?? '';
    }
  }

  @override
  void dispose() {
    _actionController.dispose();
    _partsController.dispose();
    _costController.dispose();
    _technicianController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = AssetService(Supabase.instance.client);

      if (widget.logToEdit != null) {
        // Update existing log
        await service.updateMaintenanceLog(widget.logToEdit!.id, {
          'action_taken': _actionController.text,
          'parts_replaced': _partsController.text.isEmpty
              ? null
              : _partsController.text,
          'cost': double.tryParse(_costController.text) ?? 0.0,
          'technician': _technicianController.text.isEmpty
              ? null
              : _technicianController.text,
        });

        if (mounted) {
          showAppNotification(
            context,
            'Maintenance log updated',
            type: NotificationType.success,
          );
        }
      } else {
        // Create new log
        final log = MaintenanceLog(
          id: 0, // Ignored by DB logic
          diagnosisId: widget.diagnosisId,
          actionTaken: _actionController.text,
          partsReplaced: _partsController.text.isEmpty
              ? null
              : _partsController.text,
          cost: double.tryParse(_costController.text) ?? 0.0,
          technician: _technicianController.text.isEmpty
              ? null
              : _technicianController.text,
          createdAt: DateTime.now(),
        );

        await service.logMaintenance(log);

        if (mounted) {
          showAppNotification(
            context,
            'Maintenance logged successfully',
            type: NotificationType.success,
          );
        }
      }

      // Invalidate providers to refresh UI
      // ignore: use_build_context_synchronously
      if (mounted) {
        // We can't easily access 'ref' here unless we convert to ConsumerStatefulWidget or pass ref.
        // But we are in a StatefulWidget. Let's assume we change it to ConsumerStatefulWidget in the next step
        // OR we return 'true' and the caller refreshes.
        // The user asked to "automatically refresh".

        Navigator.pop(context, true); // Return success so caller can refresh
      }
    } catch (e) {
      if (mounted) {
        showAppNotification(context, 'Error: $e', type: NotificationType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const AppText(
          'Log Maintenance',
          size: AppTextSize.lg,
          weight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Action Taken'),
              _buildTextField(
                controller: _actionController,
                hint: 'Describe the repair or maintenance activity...',
                maxLines: 3,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Parts Replaced (Optional)'),
              _buildTextField(
                controller: _partsController,
                hint: 'e.g., Bearing SKU-123, O-Ring...',
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Cost (\$)'),
                        _buildTextField(
                          controller: _costController,
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Technician'),
                        _buildTextField(
                          controller: _technicianController,
                          hint: 'Name',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentNeonBlue,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'SAVE RECORD',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: AppText(title, size: AppTextSize.sm, isMuted: true),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
