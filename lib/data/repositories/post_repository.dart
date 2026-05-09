import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/errors/app_failure.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(firestore: FirebaseFirestore.instance);
});

class PostRepository {
  final FirebaseFirestore _db;

  PostRepository({required FirebaseFirestore firestore}) : _db = firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  // ─── Feed ─────────────────────────────────────────────────────────────────

  Stream<List<PostModel>> postsStream({String? venueId}) {
    var q = _posts.orderBy('createdAt', descending: true).limit(50);
    if (venueId != null) {
      q = _posts
          .where('venueId', isEqualTo: venueId)
          .orderBy('createdAt', descending: true)
          .limit(50);
    }
    return q.snapshots().map((s) => s.docs.map(PostModel.fromFirestore).toList());
  }

  Future<Either<AppFailure, Unit>> addPost({
    required PostType type,
    required String content,
    String? caption,
    String? venueId,
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
        venueId: venueId,
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

  // ─── Posts por usuário ────────────────────────────────────────────────────

  Stream<List<PostModel>> userPostsStream(String userId) => _posts
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs.map(PostModel.fromFirestore).toList());

  // ─── Comentários ──────────────────────────────────────────────────────────

  Stream<List<CommentModel>> commentsStream(String postId) => _posts
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((s) => s.docs.map(CommentModel.fromFirestore).toList());

  Future<Either<AppFailure, Unit>> addComment({
    required String postId,
    required String text,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      final comment = CommentModel(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? 'Usuário',
        userPhotoUrl: user.photoURL,
        text: text.trim(),
        createdAt: DateTime.now(),
      );
      final batch = _db.batch();
      batch.set(
          _posts.doc(postId).collection('comments').doc(), comment.toMap());
      batch.update(_posts.doc(postId), {
        'commentsCount': FieldValue.increment(1),
      });
      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure(message: 'Erro ao comentar.'));
    }
  }

  Future<Either<AppFailure, Unit>> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'Não autenticado.'));
      }
      final batch = _db.batch();
      batch.delete(
          _posts.doc(postId).collection('comments').doc(commentId));
      batch.update(_posts.doc(postId), {
        'commentsCount': FieldValue.increment(-1),
      });
      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return const Left(
          ServerFailure(message: 'Erro ao apagar comentário.'));
    }
  }

  // ─── Compartilhar ─────────────────────────────────────────────────────────

  Future<void> sharePost(PostModel post) async {
    final StringBuffer buf = StringBuffer();
    buf.writeln('📌 Skills Arena — publicação de ${post.userName}');
    buf.writeln();
    switch (post.type) {
      case PostType.text:
        buf.writeln(post.content);
      case PostType.youtube:
        buf.writeln('🎬 Vídeo YouTube: ${post.content}');
        if (post.caption != null) buf.writeln(post.caption);
      case PostType.tiktok:
        buf.writeln('🎵 TikTok: ${post.content}');
        if (post.caption != null) buf.writeln(post.caption);
      case PostType.link:
        buf.writeln('🔗 ${post.content}');
        if (post.caption != null) buf.writeln(post.caption);
    }
    await Share.share(buf.toString().trim());
  }
}
