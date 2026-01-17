import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/penalty_state_model.dart';

/// Repository para gerenciar estado da Penalty Zone no Firestore
class PenaltyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca o estado da penalty zone do usuário
  Future<PenaltyStateModel> getPenaltyState(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('penalty_state')
          .doc('current')
          .get();

      if (!doc.exists) {
        // Cria estado inicial se não existir
        final initialState = PenaltyStateModel.initial(userId);
        await updatePenaltyState(userId, initialState);
        return initialState;
      }

      return PenaltyStateModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erro ao buscar penalty state: $e');
    }
  }

  /// Stream do estado da penalty zone
  Stream<PenaltyStateModel> getPenaltyStateStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('penalty_state')
        .doc('current')
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return PenaltyStateModel.initial(userId);
      }
      return PenaltyStateModel.fromFirestore(doc);
    });
  }

  /// Atualiza o estado da penalty zone
  Future<void> updatePenaltyState(String userId, PenaltyStateModel state) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('penalty_state')
          .doc('current')
          .set(state.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao atualizar penalty state: $e');
    }
  }

  /// Reseta o estado da penalty zone (sair)
  Future<void> resetPenaltyState(String userId) async {
    try {
      final initialState = PenaltyStateModel.initial(userId);
      await updatePenaltyState(userId, initialState);
    } catch (e) {
      throw Exception('Erro ao resetar penalty state: $e');
    }
  }
}
