import 'package:flutter/material.dart';

Future<T?> navigateWithAnimationApple<T>(
  BuildContext context,
  Widget page, {
  bool replace = false,
  bool withBar = true,
}) {
  final route = PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
  final navigator = Navigator.of(context, rootNavigator: !withBar);
  if (replace) return navigator.pushReplacement(route);
  return navigator.push(route);
}

Future<T?> navigateWithAnimationFade<T>(
  BuildContext context,
  Widget page, {
  bool replace = false,
  bool withBar = true,
}) {
  final route = PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeInOut;
      final fade =
          Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
      final scale =
          Tween<double>(begin: 0.8, end: 1.0).chain(CurveTween(curve: curve));
      return FadeTransition(
        opacity: animation.drive(fade),
        child: ScaleTransition(scale: animation.drive(scale), child: child),
      );
    },
  );
  final navigator = Navigator.of(context, rootNavigator: !withBar);
  if (replace) return navigator.pushReplacement(route);
  return navigator.push(route);
}
