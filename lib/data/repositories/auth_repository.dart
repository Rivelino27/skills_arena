import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/app_failure.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(),
  );
});

/// Stream do usuário autenticado — usado pelo GoRouter para redirect
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  User? get currentUser => _auth.currentUser;

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  Future<Either<AppFailure, UserModel>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Left(AuthFailure(message: 'Login cancelado pelo usuário.'));
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return _upsertUser(result.user!);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _errorMessage(e.code), code: e.code));
    } on PlatformException catch (e) {
      // google_sign_in lança PlatformException quando o login falha no Android.
      // Causa mais comum: SHA-1 do debug keystore não cadastrado no Firebase Console.
      if (e.code == 'sign_in_failed') {
        return const Left(AuthFailure(
          message:
              'Falha no login com Google. Certifique-se de que o SHA-1 do '
              'debug keystore está cadastrado no Firebase Console e que há '
              'uma conta Google configurada no dispositivo.',
          code: 'sign_in_failed',
        ));
      }
      return Left(AuthFailure(message: 'Erro no login com Google: ${e.message}', code: e.code));
    } catch (e) {
      return const Left(UnknownFailure(message: 'Erro ao entrar com Google.'));
    }
  }

  // ─── E-mail + Senha ───────────────────────────────────────────────────────

  Future<Either<AppFailure, UserModel>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final doc = await _userDoc(credential.user!.uid).get();
      return Right(UserModel.fromFirestore(doc));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _errorMessage(e.code), code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<Either<AppFailure, UserModel>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      return _upsertUser(user, name: name.trim());
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _errorMessage(e.code), code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Reset de senha ───────────────────────────────────────────────────────

  Future<Either<AppFailure, Unit>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _errorMessage(e.code), code: e.code));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────

  Future<Either<AppFailure, Unit>> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      return const Right(unit);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<Either<AppFailure, UserModel>> _upsertUser(
    User user, {
    String? name,
  }) async {
    final ref = _userDoc(user.uid);
    final doc = await ref.get();
    final now = DateTime.now();

    if (!doc.exists) {
      final model = UserModel(
        id: user.uid,
        email: user.email!,
        name: name ?? user.displayName,
        photoUrl: user.photoURL,
        isPremium: false,
        createdAt: now,
        updatedAt: now,
      );
      await ref.set(model.toMap());
      return Right(model);
    }

    return Right(UserModel.fromFirestore(doc));
  }

  String _errorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha fraca. Use ao menos 6 caracteres.';
      case 'user-disabled':
        return 'Conta desativada. Contate o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro de autenticação. Tente novamente.';
    }
  }
}
