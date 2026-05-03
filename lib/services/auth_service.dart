import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login com Email/Senha
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _getUserFromFirestore(result.user!.uid);
    } catch (e) {
      rethrow;
    }
  }

  // Cadastro com Email/Senha
  Future<UserModel?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        uid: result.user!.uid,
        name: name,
        email: email,
      );

      await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());
      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  // Login com Google (corrigido)
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      // Verifica se usuário já existe no Firestore
      final doc = await _firestore.collection('users').doc(result.user!.uid).get();
      if (!doc.exists) {
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          name: result.user!.displayName ?? "Usuário Google",
          email: result.user!.email ?? "",
          photoUrl: result.user!.photoURL,
        );
        await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());
        return newUser;
      }
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Future<void> signOut() async => await _auth.signOut();
}