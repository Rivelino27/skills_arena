import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Stream do documento do usuário no Firestore — atualiza em tempo real.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});

/// Atalho conveniente para saber se o usuário logado tem plano premium.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.isPremium ?? false;
});
