import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service para resetar completamente o app do usuário (apenas para testes)
class ResetService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reseta completamente o usuário para o estado inicial
  /// 
  /// ATENÇÃO: Esta ação é IRREVERSÍVEL e deleta TODOS os dados:
  /// - Level volta para 1
  /// - XP volta para 0
  /// - Stats (Power, Mind, Spirit) voltam para 0
  /// - Todos os objetivos são deletados
  /// - Todas as tarefas são deletadas
  /// - Todos os daily quests são deletados
  /// - Penalty state é resetado
  Future<void> resetUserCompletely() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final userId = user.uid;

      // 1. Reseta dados do perfil
      await _firestore.collection('users').doc(userId).update({
        'level': 1,
        'currentXp': 0,
        'power': 0,
        'mind': 0,
        'spirit': 0,
      });

      // 2. Deleta todos os objetivos
      final objectivesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('objectives')
          .get();
      
      final objectivesBatch = _firestore.batch();
      for (final doc in objectivesSnapshot.docs) {
        objectivesBatch.delete(doc.reference);
      }
      await objectivesBatch.commit();

      // 3. Deleta todas as tarefas
      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .get();
      
      final tasksBatch = _firestore.batch();
      for (final doc in tasksSnapshot.docs) {
        tasksBatch.delete(doc.reference);
      }
      await tasksBatch.commit();

      // 4. Deleta todos os daily quests
      final questsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_quests')
          .get();
      
      final questsBatch = _firestore.batch();
      for (final doc in questsSnapshot.docs) {
        questsBatch.delete(doc.reference);
      }
      await questsBatch.commit();

      // 5. Reseta penalty state
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('penalty_state')
          .doc('current')
          .delete();

      print('✅ Reset completo realizado para o usuário $userId');
    } catch (e) {
      throw Exception('Erro ao resetar usuário: $e');
    }
  }

  /// Força recálculo do level baseado no XP atual
  /// Útil quando o level não atualiza automaticamente
  Future<void> recalculateLevel() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('Perfil não encontrado');
      }

      final data = userDoc.data()!;
      final currentXp = data['currentXp'] as int? ?? 0;

      // Recalcula level baseado no XP
      int level = 1;
      while (_xpForLevel(level + 1) <= currentXp) {
        level++;
      }

      // Atualiza apenas o level
      await _firestore.collection('users').doc(user.uid).update({
        'level': level,
      });

      print('✅ Level recalculado: $level (XP: $currentXp)');
    } catch (e) {
      throw Exception('Erro ao recalcular level: $e');
    }
  }

  /// Calcula XP necessário para um level específico
  int _xpForLevel(int level) {
    if (level <= 1) return 0;
    return (100 * math.pow(level.toDouble(), 1.5)).round();
  }
}
