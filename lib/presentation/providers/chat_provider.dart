import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/chat_repository.dart';

final conversationsStreamProvider =
    StreamProvider<List<ConversationModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).conversationsStream(uid);
});

final messagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).messagesStream(chatId);
});

final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return ref.watch(chatRepositoryProvider).usersStream(uid);
});
