import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trophy_model.dart';

/// Repository para gerenciar operações de Troféus no Firestore
class TrophyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referência para a coleção de troféus do usuário
  CollectionReference _trophiesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('trophies');
  }

  /// Cria um novo troféu
  Future<String> createTrophy(TrophyModel trophy) async {
    try {
      final docRef = await _trophiesCollection(trophy.userId).add(trophy.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar troféu: $e');
    }
  }

  /// Busca todos os troféus do usuário
  Future<List<TrophyModel>> getAllTrophies(String userId) async {
    try {
      final snapshot = await _trophiesCollection(userId)
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return TrophyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar troféus: $e');
    }
  }

  /// Stream de todos os troféus
  Stream<List<TrophyModel>> watchTrophies(String userId) {
    return _trophiesCollection(userId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TrophyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Busca troféus marcados para exibir no dashboard (máx 3)
  Future<List<TrophyModel>> getDashboardTrophies(String userId) async {
    try {
      final snapshot = await _trophiesCollection(userId)
          .where('displayOnDashboard', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .limit(3)
          .get();

      return snapshot.docs.map((doc) {
        return TrophyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar troféus do dashboard: $e');
    }
  }

  /// Stream de troféus do dashboard
  Stream<List<TrophyModel>> watchDashboardTrophies(String userId) {
    return _trophiesCollection(userId)
        .where('displayOnDashboard', isEqualTo: true)
        .orderBy('completedAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TrophyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Atualiza um troféu existente
  Future<void> updateTrophy(String userId, TrophyModel trophy) async {
    try {
      await _trophiesCollection(userId).doc(trophy.id).update(trophy.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar troféu: $e');
    }
  }

  /// Marca troféu para exibir no dashboard
  Future<void> setDisplayOnDashboard(String userId, String trophyId, bool display) async {
    try {
      await _trophiesCollection(userId).doc(trophyId).update({
        'displayOnDashboard': display,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar exibição do troféu: $e');
    }
  }

  /// Conta quantos troféus estão marcados para dashboard
  Future<int> countDashboardTrophies(String userId) async {
    try {
      final snapshot = await _trophiesCollection(userId)
          .where('displayOnDashboard', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Erro ao contar troféus do dashboard: $e');
    }
  }

  /// Deleta um troféu
  Future<void> deleteTrophy(String userId, String trophyId) async {
    try {
      await _trophiesCollection(userId).doc(trophyId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar troféu: $e');
    }
  }

  /// Verifica se já existe troféu para um objetivo específico
  Future<bool> trophyExistsForObjective(String userId, String objectiveId) async {
    try {
      final snapshot = await _trophiesCollection(userId)
          .where('objectiveId', isEqualTo: objectiveId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar existência de troféu: $e');
    }
  }
}
