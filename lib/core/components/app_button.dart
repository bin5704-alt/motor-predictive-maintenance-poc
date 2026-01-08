import 'package:flutter/material.dart';
import '../ui/m_design_system.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AppButtonVariant variant;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    // We can use different native button types or just style ElevatedButton
    // For M3, commonly FilledButton, OutlinedButton, TextButton match well.
    
    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton.icon(
          onPressed: onPressed,
          icon: icon ?? const SizedBox.shrink(),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        if (icon == null) {
            button = FilledButton(
             onPressed: onPressed,
             style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             ),
             child: Text(label),
            );
        }
        break;
      case AppButtonVariant.secondary:
        button = FilledButton.tonal(
          onPressed: onPressed,
          child: Text(label),
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton.icon(
           onPressed: onPressed,
           icon: icon ?? const SizedBox.shrink(),
           label: Text(label),
           style: OutlinedButton.styleFrom(
             foregroundColor: AppColors.primary,
             side: const BorderSide(color: AppColors.border),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           ),
        );
        if(icon == null) {
            button = OutlinedButton(
                onPressed: onPressed,
                 style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(label),
            );
        }
        break;
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: onPressed,
          child: Text(label),
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
