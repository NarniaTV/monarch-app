import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';

/// Service para gerenciar autenticação e criação de perfil
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream do usuário atual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuário atual
  User? get currentUser => _auth.currentUser;

  /// Faz login com email e senha
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Verifica se o nickname já está em uso
  Future<bool> isNicknameTaken(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname.trim().toLowerCase())
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw 'Erro ao verificar nickname: $e';
    }
  }

  /// Registra novo usuário com email e senha
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    required String nickname,
  }) async {
    try {
      // Verifica se o nickname já está em uso
      final nicknameTaken = await isNicknameTaken(nickname);
      if (nicknameTaken) {
        throw 'Este nickname já está em uso. Escolha outro.';
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Atualizar display name se fornecido
      if (displayName != null && displayName.isNotEmpty && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      // Criar perfil no Firestore
      if (credential.user != null) {
        await _createUserProfile(
          userId: credential.user!.uid,
          email: email.trim(),
          displayName: displayName,
          nickname: nickname.trim(),
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Re-throw erros customizados (como nickname duplicado)
      rethrow;
    }
  }

  /// Faz logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Cria perfil do usuário no Firestore
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    required String nickname,
  }) async {
    final userProfile = UserProfileModel.create(
      userId: userId,
      email: email,
      displayName: displayName,
      nickname: nickname,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .set(userProfile.toFirestore());
  }

  /// Busca perfil do usuário no Firestore
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfileModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Atualiza perfil do usuário no Firestore
  Future<void> updateUserProfile(UserProfileModel profile) async {
    await _firestore
        .collection('users')
        .doc(profile.userId)
        .update(profile.toFirestore());
  }

  /// Trata exceções do Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'email-already-in-use':
        return 'Este email já está em uso.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      default:
        return 'Erro ao autenticar: ${e.message}';
    }
  }
}
