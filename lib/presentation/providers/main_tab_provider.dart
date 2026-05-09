import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the active tab in [MainShell].
///
/// Writing to this provider from anywhere switches the active tab. To
/// jump to a tab AND clear screens stacked above the shell, do both:
/// ```dart
/// ref.read(mainTabProvider.notifier).state = 0;
/// Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
/// ```
final mainTabProvider = StateProvider<int>((ref) => 0);
