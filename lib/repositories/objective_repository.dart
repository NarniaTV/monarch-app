import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/objective_model.dart';
import '../core/utils/constants.dart';
import '../services/sync_service.dart';

/// Repository para gerenciar Objetivos S no Firestore
class ObjectiveRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca objetivos ativos por rank
  Future<List<ObjectiveModel>> getActiveObjectivesByRank(
    String userId,
    ObjectiveRank rank,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('objectives')
          .where('rank', isEqualTo: rank.name)
          .where('progress', isLessThan: 100)
          .orderBy('progress')
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => ObjectiveModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar objetivos: $e');
    }
  }

  /// Stream de objetivos ativos por rank
  Stream<List<ObjectiveModel>> getActiveObjectivesStreamByRank(
    String userId,
    ObjectiveRank rank,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('objectives')
        .where('rank', isEqualTo: rank.name)
        .where('progress', isLessThan: 100)
        .orderBy('progress')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ObjectiveModel.fromFirestore(doc))
            .toList());
  }

  /// Busca todos os objetivos ativos (todos os ranks) - OFFLINE-FIRST
  /// Lê PRIMEIRO do Isar, depois sincroniza do Firestore se online
  Future<List<ObjectiveModel>> getActiveObjectives(String userId) async {
    final syncService = SyncService();
    
    // PASSO 1: Lê PRIMEIRO do Isar (fonte primária - retorna imediatamente)
    try {
      final localObjectives = await syncService.getObjectivesFromLocal();
      final activeLocal = localObjectives.where((o) => o.progress < 100).toList();
      print('[OBJ REPO] ✅ ${activeLocal.length} objetivos ativos encontrados localmente');
      
      // PASSO 2: Se online, sincroniza do Firestore em background (não bloqueia retorno)
      final isOnline = await syncService.isOnline().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => false,
      );
      
      if (isOnline) {
        try {
          final snapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('objectives')
              .where('progress', isLessThan: 100)
              .orderBy('progress')
              .orderBy('createdAt')
              .get()
              .timeout(const Duration(seconds: 5));

          final firestoreObjectives = snapshot.docs
              .map((doc) => ObjectiveModel.fromFirestore(doc))
              .toList();
          
          // Atualiza Isar em background (não bloqueia retorno)
          for (final obj in firestoreObjectives) {
            syncService.saveObjectiveLocally(obj).catchError((e) {
              print('[OBJ REPO] Erro ao salvar localmente: $e');
            });
          }
        } catch (e) {
          print('[OBJ REPO] ⚠️ Erro ao sincronizar do Firestore (usando dados locais): $e');
        }
      }
      
      // Retorna dados locais (já estão atualizados ou serão atualizados em background)
      return activeLocal;
    } catch (e) {
      print('[OBJ REPO] ⚠️ Erro ao buscar localmente: $e');
      // Fallback para Firestore se local falhar
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('objectives')
            .where('progress', isLessThan: 100)
            .orderBy('progress')
            .orderBy('createdAt')
            .get()
            .timeout(const Duration(seconds: 5));

        return snapshot.docs
            .map((doc) => ObjectiveModel.fromFirestore(doc))
            .toList();
      } catch (firestoreError) {
        throw Exception('Erro ao buscar objetivos: $firestoreError');
      }
    }
  }

  /// Stream de todos os objetivos ativos
  Stream<List<ObjectiveModel>> getActiveObjectivesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('objectives')
        .where('progress', isLessThan: 100)
        .orderBy('progress')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ObjectiveModel.fromFirestore(doc))
            .toList());
  }

  /// Cria um novo objetivo
  Future<ObjectiveModel> createObjective(ObjectiveModel objective) async {
    try {
      // Verifica limite apenas para Rank S (máximo 3)
      if (objective.rank == ObjectiveRank.s) {
        final activeObjectivesS = await getActiveObjectivesByRank(
          objective.userId,
          ObjectiveRank.s,
        );
        if (activeObjectivesS.length >= SystemLimits.maxObjectivesS) {
          throw Exception('Máximo de ${SystemLimits.maxObjectivesS} objetivos S ativos atingido');
        }
      }
      // Ranks A e B não têm limite

      final docRef = await _firestore
          .collection('users')
          .doc(objective.userId)
          .collection('objectives')
          .add(objective.toFirestore());

      return objective.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erro ao criar objetivo: $e');
    }
  }

  /// Atualiza um objetivo
  Future<void> updateObjective(ObjectiveModel objective) async {
    try {
      await _firestore
          .collection('users')
          .doc(objective.userId)
          .collection('objectives')
          .doc(objective.id)
          .update(objective.toFirestore());
    } catch (e) {
      throw Exception('Erro ao atualizar objetivo: $e');
    }
  }

  /// Completa um objetivo (marca progresso como 100%)
  Future<void> completeObjective(ObjectiveModel objective) async {
    try {
      await _firestore
          .collection('users')
          .doc(objective.userId)
          .collection('objectives')
          .doc(objective.id)
          .update({
        'progress': 100,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erro ao completar objetivo: $e');
    }
  }

  /// Deleta um objetivo
  Future<void> deleteObjective(String userId, String objectiveId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('objectives')
          .doc(objectiveId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar objetivo: $e');
    }
  }
}
