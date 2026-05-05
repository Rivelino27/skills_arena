import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { text, youtube, link }

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final PostType type;
  final String content;
  final String? caption;
  final int likesCount;
  final List<String> likedBy;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.content,
    this.caption,
    this.likesCount = 0,
    this.likedBy = const [],
    required this.createdAt,
  });

  bool isLikedBy(String uid) => likedBy.contains(uid);

  String? get youtubeVideoId {
    if (type != PostType.youtube) return null;
    try {
      final uri = Uri.parse(content);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
      return uri.queryParameters['v'];
    } catch (_) {
      return null;
    }
  }

  String? get youtubeThumbnailUrl {
    final id = youtubeVideoId;
    return id != null ? 'https://img.youtube.com/vi/$id/hqdefault.jpg' : null;
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: d['userId'] as String,
      userName: d['userName'] as String,
      userPhotoUrl: d['userPhotoUrl'] as String?,
      type: PostType.values.firstWhere(
        (e) => e.name == (d['type'] as String? ?? 'text'),
        orElse: () => PostType.text,
      ),
      content: d['content'] as String,
      caption: d['caption'] as String?,
      likesCount: (d['likesCount'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(d['likedBy'] as List? ?? []),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'type': type.name,
        'content': content,
        'caption': caption,
        'likesCount': likesCount,
        'likedBy': likedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
