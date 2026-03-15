import 'dart:async';
import 'package:flutter/material.dart';

enum SnackbarType { success, error, warning }

class _PendingSnackbar {
  final String message;
  final SnackbarType type;
  const _PendingSnackbar({required this.message, required this.type});
}

class TopSnackbar {
  static OverlayEntry? _currentEntry;
  static _PendingSnackbar? _pending;

  TopSnackbar._();

  static void schedulePending({
    required String message,
    SnackbarType type = SnackbarType.success,
  }) {
    _pending = _PendingSnackbar(message: message, type: type);
  }

  static void showPendingIfAny(BuildContext context) {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        show(context, message: pending.message, type: pending.type);
      }
    });
  }

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    _removeCurrent();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _TopSnackbarWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _removeCurrent() {
    final entry = _currentEntry;
    _currentEntry = null;
    entry?.remove();
  }
}

class _TopSnackbarWidget extends StatefulWidget {
  final String message;
  final SnackbarType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopSnackbarWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopSnackbarWidget> createState() => _TopSnackbarWidgetState();
}

class _TopSnackbarWidgetState extends State<_TopSnackbarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _autoCloseTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);

    _animCtrl.forward();
    _autoCloseTimer = Timer(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _autoCloseTimer?.cancel();
    _animCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    final Color bg;
    final Color textColor;
    final Color iconColor;
    final IconData icon;
    BoxBorder? border;

    switch (widget.type) {
      case SnackbarType.success:
        bg = Theme.of(context).primaryColor;
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.check_circle_outline;
      case SnackbarType.error:
        bg = const Color(0xDD000000);
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.error_outline;
      case SnackbarType.warning:
        bg = Colors.white;
        textColor = Colors.black87;
        iconColor = Colors.black87;
        icon = Icons.warning_amber_outlined;
        border = Border.all(color: Theme.of(context).primaryColor, width: 1.5);
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: EdgeInsets.only(
                  top: topPadding + 12,
                  bottom: 14,
                  left: 20,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  border: border,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close,
                      color: iconColor.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
