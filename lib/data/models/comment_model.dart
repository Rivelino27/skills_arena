import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final DateTime createdAt;
  final String? replyToId;
  final String? replyToName;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    required this.createdAt,
    this.replyToId,
    this.replyToName,
  });

  bool get isReply => replyToId != null;

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      userId: d['userId'] as String,
      userName: d['userName'] as String,
      userPhotoUrl: d['userPhotoUrl'] as String?,
      text: d['text'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      replyToId: d['replyToId'] as String?,
      replyToName: d['replyToName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        if (replyToId != null) 'replyToId': replyToId,
        if (replyToName != null) 'replyToName': replyToName,
      };
}
