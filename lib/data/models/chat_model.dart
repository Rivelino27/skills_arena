import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final Map<String, DateTime?> lastReadAt;
  final bool isGroup;
  final String? groupName;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.lastReadAt = const {},
    this.isGroup = false,
    this.groupName,
  });

  /// True if there is a newer message than the user's last-read timestamp
  /// AND the latest message was not sent by the user themself.
  bool hasUnreadFor(String myUid) {
    if (lastMessageAt == null) return false;
    if (lastSenderId == myUid) return false;
    final read = lastReadAt[myUid];
    if (read == null) return true;
    return lastMessageAt!.isAfter(read);
  }

  String otherUid(String myUid) =>
      participants.firstWhere((id) => id != myUid, orElse: () => myUid);

  String otherName(String myUid) =>
      participantNames[otherUid(myUid)] ?? 'Usuário';

  String? otherPhoto(String myUid) => participantPhotos[otherUid(myUid)];

  /// Title shown for the conversation in lists/detail header.
  String displayTitle(String myUid) {
    if (isGroup) {
      if (groupName != null && groupName!.trim().isNotEmpty) return groupName!;
      // Fallback: comma-separated names of other participants.
      final others = participants
          .where((id) => id != myUid)
          .map((id) => participantNames[id] ?? 'Usuário')
          .join(', ');
      return others.isEmpty ? 'Grupo' : others;
    }
    return otherName(myUid);
  }

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(d['participants'] as List),
      participantNames:
          Map<String, String>.from(d['participantNames'] as Map? ?? {}),
      participantPhotos:
          Map<String, String?>.from(d['participantPhotos'] as Map? ?? {}),
      lastMessage: d['lastMessage'] as String?,
      lastMessageAt: d['lastMessageAt'] != null
          ? (d['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastSenderId: d['lastSenderId'] as String?,
      lastReadAt: () {
        final raw = d['lastReadAt'] as Map<String, dynamic>? ?? {};
        return raw.map<String, DateTime?>(
          (k, v) =>
              MapEntry(k, v is Timestamp ? v.toDate() : null),
        );
      }(),
      isGroup: d['isGroup'] as bool? ?? false,
      groupName: d['groupName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'participants': participants,
        'participantNames': participantNames,
        'participantPhotos': participantPhotos,
        'lastMessage': lastMessage,
        'lastMessageAt':
            lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
        'lastSenderId': lastSenderId,
        'lastReadAt': lastReadAt.map(
          (k, v) =>
              MapEntry(k, v != null ? Timestamp.fromDate(v) : null),
        ),
        'isGroup': isGroup,
        'groupName': groupName,
      };
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: d['senderId'] as String,
      senderName: d['senderName'] as String,
      text: d['text'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
