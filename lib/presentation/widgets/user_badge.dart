import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';

/// Small role badge: admin (shield) > premium (star) > nothing.
/// Use inline next to the user's name.
class UserBadge extends StatelessWidget {
  final UserModel user;
  final double size;
  const UserBadge({super.key, required this.user, this.size = 16});

  @override
  Widget build(BuildContext context) {
    if (user.isAdmin) {
      return Tooltip(
        message: 'Admin',
        child: Icon(Icons.verified_user_rounded,
            size: size, color: Colors.amber.shade700),
      );
    }
    if (user.isPremium) {
      return Tooltip(
        message: 'Premium',
        child: Icon(Icons.workspace_premium_rounded,
            size: size, color: Colors.amber.shade600),
      );
    }
    if (user.isVerified) {
      return Tooltip(
        message: 'Verificado',
        child: Icon(Icons.verified_rounded,
            size: size, color: Colors.blue.shade400),
      );
    }
    return const SizedBox.shrink();
  }
}
