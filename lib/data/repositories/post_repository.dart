import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../models/post_model.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(firestore: FirebaseFirestore.instance);
});

class PostRepository {
  final FirebaseFirestore _db;

  PostRepository({required FirebaseFirestore firestore}) : _db = firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  Stream<List<PostModel>> postsStream() => _posts
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(PostModel.fromFirestore).toList());

  Future<Either<AppFailure, Unit>> addPost({
    required PostType type,
    required String content,
    String? caption,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      final post = PostModel(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? 'Usuário',
        userPhotoUrl: user.photoURL,
        type: type,
        content: content.trim(),
        caption: (caption?.trim().isEmpty ?? true) ? null : caption!.trim(),
        createdAt: DateTime.now(),
      );
      await _posts.add(post.toMap());
      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure(message: 'Erro ao publicar.'));
    }
  }

  Future<void> toggleLike(String postId, String uid) async {
    final ref = _posts.doc(postId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;
      final likedBy =
          List<String>.from(doc.data()!['likedBy'] as List? ?? []);
      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
      } else {
        likedBy.add(uid);
      }
      tx.update(ref, {'likedBy': likedBy, 'likesCount': likedBy.length});
    });
  }
}
