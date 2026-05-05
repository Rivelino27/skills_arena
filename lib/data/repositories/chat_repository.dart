import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../models/user_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(firestore: FirebaseFirestore.instance);
});

class ChatRepository {
  final FirebaseFirestore _db;

  ChatRepository({required FirebaseFirestore firestore}) : _db = firestore;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  /// Deterministic chat ID — always the same regardless of who initiates
  static String buildChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<List<ConversationModel>> conversationsStream(String uid) => _chats
      .where('participants', arrayContains: uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ConversationModel.fromFirestore).toList());

  Stream<List<MessageModel>> messagesStream(String chatId) => _chats
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((s) => s.docs.map(MessageModel.fromFirestore).toList());

  Future<ConversationModel> getOrCreateConversation({
    required String otherUid,
    required String otherName,
    String? otherPhoto,
  }) async {
    final me = FirebaseAuth.instance.currentUser!;
    final id = buildChatId(me.uid, otherUid);
    final ref = _chats.doc(id);
    final doc = await ref.get();
    if (!doc.exists) {
      final conv = ConversationModel(
        id: id,
        participants: [me.uid, otherUid],
        participantNames: {
          me.uid: me.displayName ?? 'Eu',
          otherUid: otherName,
        },
        participantPhotos: {me.uid: me.photoURL, otherUid: otherPhoto},
      );
      await ref.set(conv.toMap());
      return conv;
    }
    return ConversationModel.fromFirestore(doc);
  }

  Future<void> sendMessage(String chatId, String text) async {
    final user = FirebaseAuth.instance.currentUser!;
    final now = DateTime.now();
    final msg = MessageModel(
      id: '',
      senderId: user.uid,
      senderName: user.displayName ?? 'Eu',
      text: text.trim(),
      createdAt: now,
    );
    final batch = _db.batch();
    final msgRef = _chats.doc(chatId).collection('messages').doc();
    batch.set(msgRef, msg.toMap());
    batch.update(_chats.doc(chatId), {
      'lastMessage': text.trim(),
      'lastMessageAt': Timestamp.fromDate(now),
    });
    await batch.commit();
  }

  Stream<List<UserModel>> usersStream(String excludeUid) => _db
      .collection('users')
      .limit(50)
      .snapshots()
      .map((s) => s.docs
          .map(UserModel.fromFirestore)
          .where((u) => u.id != excludeUid)
          .toList());
}
