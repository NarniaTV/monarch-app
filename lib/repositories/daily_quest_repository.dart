import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_quest_model.dart';

/// Repository para gerenciar Daily Quests no Firestore
class DailyQuestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca todas as daily quests do usuário
  Future<List<DailyQuestModel>> getDailyQuests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_quests')
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => DailyQuestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar daily quests: $e');
    }
  }

  /// Stream de daily quests
  Stream<List<DailyQuestModel>> getDailyQuestsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_quests')
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyQuestModel.fromFirestore(doc))
            .toList());
  }

  /// Cria uma nova daily quest
  Future<DailyQuestModel> createDailyQuest(DailyQuestModel quest) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(quest.userId)
          .collection('daily_quests')
          .add(quest.toFirestore());

      final doc = await docRef.get();
      return DailyQuestModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erro ao criar daily quest: $e');
    }
  }

  /// Atualiza uma daily quest
  Future<void> updateDailyQuest(String userId, DailyQuestModel quest) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_quests')
          .doc(quest.id)
          .update(quest.toFirestore());
    } catch (e) {
      throw Exception('Erro ao atualizar daily quest: $e');
    }
  }

  /// Deleta uma daily quest
  Future<void> deleteDailyQuest(String userId, String questId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_quests')
          .doc(questId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar daily quest: $e');
    }
  }

  /// Reseta todas as daily quests (marca como não completadas)
  Future<void> resetAllDailyQuests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_quests')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isCompleted': false,
          'lastResetDate': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao resetar daily quests: $e');
    }
  }
}
