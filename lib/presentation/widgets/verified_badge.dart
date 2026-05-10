import 'package:flutter/material.dart';

/// Blue-checkmark style verified badge. Use inline next to a venue name
/// or user name when the entity has `isVerified: true`.
class VerifiedBadge extends StatelessWidget {
  final double size;
  final String tooltip;
  const VerifiedBadge({
    super.key,
    this.size = 16,
    this.tooltip = 'Verificado',
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Icon(
        Icons.verified_rounded,
        size: size,
        color: Colors.blue.shade400,
      ),
    );
  }
}
