import 'package:flutter/material.dart';

/// Smooth slide-and-fade page route used across auth screens.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final AxisDirection direction;

  SlidePageRoute({required this.page, this.direction = AxisDirection.left})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetBegin = switch (direction) {
            AxisDirection.left => const Offset(1, 0),
            AxisDirection.right => const Offset(-1, 0),
            AxisDirection.up => const Offset(0, 1),
            AxisDirection.down => const Offset(0, -1),
          };
          final tween = Tween(
            begin: offsetBegin,
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          final fadeTween = Tween(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeIn));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
      );
}
