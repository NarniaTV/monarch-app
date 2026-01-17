import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';

/// Repository para gerenciar dados do usuário no Firestore
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca perfil do usuário
  Future<UserProfileModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfileModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar usuário: $e');
    }
  }

  /// Stream do perfil do usuário (atualizações em tempo real)
  Stream<UserProfileModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfileModel.fromFirestore(doc) : null);
  }

  /// Atualiza perfil do usuário
  Future<void> updateUser(UserProfileModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.userId)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  /// Atualiza stats do usuário
  Future<void> updateStats({
    required String userId,
    int? level,
    int? currentXp,
    int? power,
    int? mind,
    int? spirit,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (level != null) updates['level'] = level;
      if (currentXp != null) updates['currentXp'] = currentXp;
      if (power != null) updates['power'] = power;
      if (mind != null) updates['mind'] = mind;
      if (spirit != null) updates['spirit'] = spirit;

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Erro ao atualizar stats: $e');
    }
  }

  /// Atualiza mensagem da Penalty Zone
  Future<void> updatePenaltyMessage({
    required String userId,
    required String penaltyMessage,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'penaltyMessage': penaltyMessage,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar mensagem: $e');
    }
  }

  /// Marca onboarding como completo
  Future<void> markOnboardingComplete(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'hasCompletedOnboarding': true,
      });
    } catch (e) {
      throw Exception('Erro ao marcar onboarding: $e');
    }
  }
}
