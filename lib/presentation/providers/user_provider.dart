import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/social_repository.dart';

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

/// Stream de usuários que optaram por aparecer no mapa (`visibleOnMap = true`).
/// Usado pelo `MapScreen` para desenhar markers de pessoas na região.
final visibleUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(socialRepositoryProvider).visibleUsersStream();
});

/// Top usuários por número de seguidores. Alimenta a tela de ranking
/// geral (separada do ranking por quadra).
final topUsersByFollowersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(socialRepositoryProvider).topUsersByFollowersStream();
});
