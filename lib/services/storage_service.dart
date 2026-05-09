import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(storage: FirebaseStorage.instance);
});

class StorageService {
  final FirebaseStorage _storage;

  StorageService({required FirebaseStorage storage}) : _storage = storage;

  Future<Either<AppFailure, String>> uploadFile({
    required File file,
    required String path,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return Right(downloadUrl);
    } on FirebaseException catch (e) {
      return Left(StorageFailure(
          message: e.message ?? 'Erro ao fazer upload', code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Either<AppFailure, Unit>> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(StorageFailure(
          message: e.message ?? 'Erro ao deletar arquivo', code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Either<AppFailure, String>> uploadAvatar({
    required File file,
    required String userId,
    void Function(double progress)? onProgress,
  }) {
    final ext = file.path.split('.').last;
    return uploadFile(
      file: file,
      path: 'avatars/$userId.$ext',
      onProgress: onProgress,
    );
  }
}
