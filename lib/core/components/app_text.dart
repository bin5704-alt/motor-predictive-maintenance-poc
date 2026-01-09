import 'package:flutter/material.dart';

enum AppTextSize {
  xs, // 11px
  sm, // 13px
  md, // 15px (default)
  lg, // 18px
  xl, // 24px
  xxl, // 30px
}

class AppText extends StatelessWidget {
  final String data;
  final AppTextSize size;
  final FontWeight? weight;
  final Color? color;
  final bool isMuted;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.data, {
    super.key,
    this.size = AppTextSize.md,
    this.weight,
    this.color,
    this.isMuted = false,
    this.align,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = _getStyle(context);
    final theme = Theme.of(context);
    final effectiveColor = isMuted
        ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)
        : (color ?? theme.textTheme.bodyLarge?.color);

    return Text(
      data,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: baseStyle.copyWith(fontWeight: weight, color: effectiveColor),
    );
  }

  TextStyle _getStyle(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    switch (size) {
      case AppTextSize.xs:
        return theme.labelSmall!.copyWith(fontSize: 11);
      case AppTextSize.sm:
        return theme.bodySmall!.copyWith(fontSize: 13);
      case AppTextSize.md:
        return theme.bodyMedium!.copyWith(fontSize: 15);
      case AppTextSize.lg:
        return theme.titleMedium!.copyWith(fontSize: 18);
      case AppTextSize.xl:
        return theme.titleLarge!.copyWith(fontSize: 24);
      case AppTextSize.xxl:
        return theme.headlineMedium!.copyWith(fontSize: 30);
    }
  }
}
