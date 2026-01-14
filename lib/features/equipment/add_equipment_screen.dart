import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/components/app_card.dart';
import '../../core/components/app_text.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_notification.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ignore: unused_field
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // TODO: Implement submission logic
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        showAppNotification(
          context,
          'Equipment registered successfully',
          type: NotificationType.success,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Equipment'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppText(
              'Register New Equipment',
              size: AppTextSize.xl,
              weight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            const AppText(
              'Enter the details of the machine including specifications.',
              isMuted: true,
            ),
            const SizedBox(height: 32),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Details',
                    size: AppTextSize.lg,
                    weight: FontWeight.w600,
                  ),
                  const SizedBox(height: 24),

                  // Photo Upload Placeholder
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.image_plus,
                          size: 32,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        AppText('Upload Machine Image', isMuted: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Equipment Name',
                      hintText: 'e.g. Eulji Motor A-1',
                      prefixIcon: Icon(LucideIcons.box),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: 'Model / Type',
                      hintText: 'e.g. Induction Motor 3-Phase',
                      prefixIcon: Icon(LucideIcons.tag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description / Specs',
                      hintText: 'Enter technical specifications...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Register Equipment',
              onPressed: _handleSubmit,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
