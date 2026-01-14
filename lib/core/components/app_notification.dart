import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum NotificationType { success, warning, error }

void showAppNotification(
  BuildContext context,
  String message, {
  NotificationType type = NotificationType.success,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlayState = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) =>
        _TopNotification(message: message, type: type, duration: duration),
  );

  overlayState.insert(overlayEntry);

  // Auto remove handles inside the widget or by timer here?
  // Widget handles animation, but we need to remove entry.
  // We'll pass a callback to the widget to remove itself or handle it here with delay.
  // Better: Let the widget handle the 'closing' animation, then remove entry.
  // To do that, we need to give the widget access to the entry removal.

  // Wait for duration + animation reverse time
  Future.delayed(duration + const Duration(milliseconds: 300), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

class _TopNotification extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;

  const _TopNotification({
    required this.message,
    required this.type,
    required this.duration,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    // Start entrance animation
    _controller.forward();

    // Schedule exit
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF10B981); // Emerald Green
      case NotificationType.warning:
        return const Color(0xFFF59E0B); // Amber
      case NotificationType.error:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) {
              // The OverlayEntry will be removed by the parent Future.delayed regardless,
              // but visually dismissing feels good.
              _controller.reverse();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark, // Dark background
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: _getBackgroundColor(), width: 4),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getBackgroundColor().withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(),
                      color: _getBackgroundColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
