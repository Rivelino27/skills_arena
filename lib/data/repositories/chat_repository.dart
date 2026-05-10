import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../models/user_model.dart';
import 'social_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    social: ref.watch(socialRepositoryProvider),
  );
});

class ChatRepository {
  final FirebaseFirestore _db;
  final SocialRepository _social;

  ChatRepository({
    required FirebaseFirestore firestore,
    required SocialRepository social,
  })  : _db = firestore,
        _social = social;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  /// Deterministic chat ID for 1-1 — always the same regardless of who initiates
  static String buildChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Deterministic chat ID for a venue + day + hour slot.
  /// New day = new chat ID, so messages reset naturally each day.
  static String buildVenueSlotChatId(String venueId, DateTime startAt) {
    final date = '${startAt.year}'
        '${startAt.month.toString().padLeft(2, '0')}'
        '${startAt.day.toString().padLeft(2, '0')}';
    final hour = startAt.hour.toString().padLeft(2, '0');
    return 'venue_${venueId}_${date}_$hour';
  }

  /// Deterministic chat ID for a venue's whole-day group chat.
  /// Same shape as the slot ID but without the hour suffix, so a new day
  /// = a fresh chat (no message buildup).
  static String buildVenueDayChatId(String venueId, DateTime day) {
    final date = '${day.year}'
        '${day.month.toString().padLeft(2, '0')}'
        '${day.day.toString().padLeft(2, '0')}';
    return 'venue_${venueId}_${date}_day';
  }

  /// Whole-day venue chat. Anyone signed in can join. Messages reset
  /// daily because the chat ID rolls over at midnight.
  Future<ConversationModel> getOrCreateVenueDayChat({
    required String venueId,
    required String venueName,
    required DateTime day,
  }) async {
    final me = FirebaseAuth.instance.currentUser!;
    final id = buildVenueDayChatId(venueId, day);
    final ref = _chats.doc(id);
    final doc = await ref.get();

    final dd = day.day.toString().padLeft(2, '0');
    final mm = day.month.toString().padLeft(2, '0');
    final groupName = '$venueName • $dd/$mm (dia)';

    if (!doc.exists) {
      await ref.set({
        'participants': [me.uid],
        'participantNames': {me.uid: me.displayName ?? 'Eu'},
        'participantPhotos': {me.uid: me.photoURL},
        'lastMessage': null,
        'lastMessageAt': Timestamp.now(),
        'isGroup': true,
        // Reuse the same Firestore-rule branch as slot groups so any
        // signed-in user can join.
        'isVenueSlotGroup': true,
        'venueId': venueId,
        'groupName': groupName,
      });
    } else {
      final data = doc.data()!;
      final participants =
          List<String>.from(data['participants'] as List? ?? []);
      if (!participants.contains(me.uid)) {
        await ref.update({
          'participants': FieldValue.arrayUnion([me.uid]),
          'participantNames.${me.uid}': me.displayName ?? 'Eu',
          'participantPhotos.${me.uid}': me.photoURL,
        });
      }
    }
    final fresh = await ref.get();
    return ConversationModel.fromFirestore(fresh);
  }

  /// Gets or joins the venue-slot group chat. Creates with current user
  /// if it doesn't exist; otherwise adds current user to participants.
  /// Anyone signed-in can join (Firestore rules permit isVenueSlotGroup chats).
  Future<ConversationModel> getOrCreateVenueSlotChat({
    required String venueId,
    required String venueName,
    required DateTime startAt,
  }) async {
    final me = FirebaseAuth.instance.currentUser!;
    final id = buildVenueSlotChatId(venueId, startAt);
    final ref = _chats.doc(id);
    final doc = await ref.get();

    final hh = startAt.hour.toString().padLeft(2, '0');
    final dd = startAt.day.toString().padLeft(2, '0');
    final mm = startAt.month.toString().padLeft(2, '0');
    final groupName = '$venueName • $dd/$mm ${hh}h';

    if (!doc.exists) {
      await ref.set({
        'participants': [me.uid],
        'participantNames': {me.uid: me.displayName ?? 'Eu'},
        'participantPhotos': {me.uid: me.photoURL},
        'lastMessage': null,
        'lastMessageAt': Timestamp.now(),
        'isGroup': true,
        'isVenueSlotGroup': true,
        'venueId': venueId,
        'groupName': groupName,
      });
    } else {
      final data = doc.data()!;
      final participants =
          List<String>.from(data['participants'] as List? ?? []);
      if (!participants.contains(me.uid)) {
        await ref.update({
          'participants': FieldValue.arrayUnion([me.uid]),
          'participantNames.${me.uid}': me.displayName ?? 'Eu',
          'participantPhotos.${me.uid}': me.photoURL,
        });
      }
    }
    final fresh = await ref.get();
    return ConversationModel.fromFirestore(fresh);
  }

  Stream<List<ConversationModel>> conversationsStream(String uid,
          {int limit = 100}) =>
      _chats
          .where('participants', arrayContains: uid)
          .orderBy('lastMessageAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(ConversationModel.fromFirestore).toList());

  /// Last [limit] messages, in chronological order. Fetched newest-first
  /// then reversed so the newest stays at the bottom of the chat.
  Stream<List<MessageModel>> messagesStream(String chatId, {int limit = 200}) =>
      _chats
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.reversed
              .map(MessageModel.fromFirestore)
              .toList());

  /// Throws an exception when one of the users blocked the other.
  Future<ConversationModel> getOrCreateConversation({
    required String otherUid,
    required String otherName,
    String? otherPhoto,
  }) async {
    final me = FirebaseAuth.instance.currentUser!;
    final blocked = await _social.isBlockedEitherWay(
      myUid: me.uid,
      otherUid: otherUid,
    );
    if (blocked) {
      throw Exception(
          'Não é possível abrir conversa: usuário bloqueado.');
    }
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

  /// Creates a group chat with N participants. Filters out anyone the
  /// current user has blocked or is blocked by.
  Future<ConversationModel> createGroupChat({
    required List<UserModel> members,
    String? groupName,
  }) async {
    final me = FirebaseAuth.instance.currentUser!;

    // Filter out blocked-either-way users.
    final filtered = <UserModel>[];
    for (final u in members) {
      if (u.id == me.uid) continue;
      final blocked = await _social.isBlockedEitherWay(
        myUid: me.uid,
        otherUid: u.id,
      );
      if (!blocked) filtered.add(u);
    }
    if (filtered.isEmpty) {
      throw Exception('Selecione ao menos um usuário disponível.');
    }

    final allUids = [me.uid, ...filtered.map((u) => u.id)];
    final names = <String, String>{
      me.uid: me.displayName ?? 'Eu',
      for (final u in filtered) u.id: u.name ?? 'Usuário',
    };
    final photos = <String, String?>{
      me.uid: me.photoURL,
      for (final u in filtered) u.id: u.photoUrl,
    };

    final docRef = await _chats.add({
      'participants': allUids,
      'participantNames': names,
      'participantPhotos': photos,
      'lastMessage': null,
      'lastMessageAt': Timestamp.now(),
      'isGroup': true,
      'groupName': groupName,
    });
    final snap = await docRef.get();
    return ConversationModel.fromFirestore(snap);
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
      'lastSenderId': user.uid,
      'lastReadAt.${user.uid}': Timestamp.fromDate(now),
    });
    await batch.commit();
  }

  /// Sends a one-shot location message (lat/lng) into the conversation.
  Future<void> sendLocationMessage({
    required String chatId,
    required double lat,
    required double lng,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final now = DateTime.now();
    final msg = MessageModel(
      id: '',
      senderId: user.uid,
      senderName: user.displayName ?? 'Eu',
      text: '📍 Localização',
      type: MessageType.location,
      lat: lat,
      lng: lng,
      createdAt: now,
    );
    final batch = _db.batch();
    final msgRef = _chats.doc(chatId).collection('messages').doc();
    batch.set(msgRef, msg.toMap());
    batch.update(_chats.doc(chatId), {
      'lastMessage': '📍 Localização',
      'lastMessageAt': Timestamp.fromDate(now),
      'lastSenderId': user.uid,
      'lastReadAt.${user.uid}': Timestamp.fromDate(now),
    });
    await batch.commit();
  }

  /// Marks the conversation as read for the current user (now).
  Future<void> markAsRead(String chatId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _chats.doc(chatId).update({
      'lastReadAt.$uid': Timestamp.now(),
    });
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
