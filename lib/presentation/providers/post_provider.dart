import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/comment_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

final postsStreamProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(postRepositoryProvider).postsStream();
});

final commentsStreamProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(postRepositoryProvider).commentsStream(postId);
});

final userPostsStreamProvider =
    StreamProvider.family<List<PostModel>, String>((ref, userId) {
  return ref.watch(postRepositoryProvider).userPostsStream(userId);
});

final venuePostsStreamProvider =
    StreamProvider.family<List<PostModel>, String>((ref, venueId) {
  return ref.watch(postRepositoryProvider).postsStream(venueId: venueId);
});
