import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../core/utils/constants.dart';
import '../services/sync_service.dart';

/// Repository para gerenciar Tarefas no Firestore
class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca todas as tarefas do usuário - OFFLINE-FIRST
  /// Lê PRIMEIRO do Isar, depois sincroniza do Firestore se online
  Future<List<TaskModel>> getTasks(String userId) async {
    final syncService = SyncService();
    
    // PASSO 1: Lê PRIMEIRO do Isar (fonte primária - retorna imediatamente)
    try {
      final localTasks = await syncService.getTasksFromLocal();
      print('[TASK REPO] ✅ ${localTasks.length} tarefas encontradas localmente');
      
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
              .collection('tasks')
              .orderBy('createdAt', descending: true)
              .get()
              .timeout(const Duration(seconds: 5));

          final firestoreTasks = snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
          
          // Atualiza Isar em background (não bloqueia retorno)
          for (final task in firestoreTasks) {
            syncService.saveTaskLocally(task).catchError((e) {
              print('[TASK REPO] Erro ao salvar localmente: $e');
            });
          }
        } catch (e) {
          print('[TASK REPO] ⚠️ Erro ao sincronizar do Firestore (usando dados locais): $e');
        }
      }
      
      // Retorna dados locais (já estão atualizados ou serão atualizados em background)
      return localTasks;
    } catch (e) {
      print('[TASK REPO] ⚠️ Erro ao buscar localmente: $e');
      // Fallback para Firestore se local falhar
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .orderBy('createdAt', descending: true)
            .get()
            .timeout(const Duration(seconds: 5));

        return snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList();
      } catch (firestoreError) {
        throw Exception('Erro ao buscar tarefas: $firestoreError');
      }
    }
  }

  /// Stream de todas as tarefas - OFFLINE-FIRST
  /// Lê PRIMEIRO do Isar (retorna imediatamente)
  /// Sincroniza do Firestore em background quando online
  Stream<List<TaskModel>> getTasksStream(String userId) async* {
    final syncService = SyncService();
    
    // PASSO 1: Lê PRIMEIRO do Isar (fonte primária - retorna imediatamente)
    try {
      final localTasks = await syncService.getTasksFromLocal();
      print('[TASK REPO] ✅ ${localTasks.length} tarefas encontradas localmente (exibindo imediatamente)');
      yield localTasks; // Emite dados locais imediatamente
    } catch (e) {
      print('[TASK REPO] ⚠️ Erro ao buscar localmente: $e');
      yield <TaskModel>[];
      return; // Para se falhar ao buscar localmente
    }
    
    // PASSO 2: Se online, sincroniza do Firestore em background
    final isOnline = await syncService.isOnline().timeout(
      const Duration(milliseconds: 500),
      onTimeout: () => false,
    );
    
    if (!isOnline) {
      print('[TASK REPO] Offline - usando apenas dados locais (stream finalizado)');
      return; // Offline - finaliza stream imediatamente
    }
    
    // Online: Sincroniza em background
    try {
      await for (final snapshot in _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .timeout(const Duration(seconds: 10), onTimeout: (sink) {
            print('[TASK REPO] ⚠️ Timeout no stream Firestore (mantendo dados locais)');
            sink.close();
          })) {
        try {
          final tasks = snapshot.docs
              .map((doc) {
                try {
                  return TaskModel.fromFirestore(doc);
                } catch (e) {
                  print('[TASK REPO] Erro ao converter tarefa ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<TaskModel>()
              .toList();
          
          // Ordena manualmente (garantia)
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Atualiza Isar em background (não bloqueia)
          for (final task in tasks) {
            syncService.saveTaskLocally(task).catchError((e) {
              print('[TASK REPO] Erro ao salvar localmente: $e');
            });
          }
          
          yield tasks; // Emite atualização quando sincronização completar
        } catch (e) {
          print('[TASK REPO] ⚠️ Erro ao processar snapshot: $e');
          // Não emite novamente - mantém dados locais já emitidos
        }
      }
    } catch (error, stackTrace) {
      print('[TASK REPO] ⚠️ Erro no stream Firestore (mantendo dados locais): $error');
      print('[TASK REPO] Stack trace: $stackTrace');
      // Não emite novamente - já emitiu dados locais acima
      return; // Finaliza o stream para evitar loops
    }
  }

  /// Busca tarefas por rank
  Future<List<TaskModel>> getTasksByRank(String userId, TaskRank rank) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('rank', isEqualTo: rank.name)
          .where('isCompleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar tarefas por rank: $e');
    }
  }

  /// Busca tarefas vinculadas a um objetivo
  Future<List<TaskModel>> getTasksByObjective(String userId, String objectiveId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('linkedObjectiveId', isEqualTo: objectiveId)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar tarefas por objetivo: $e');
    }
  }

  /// Cria uma nova tarefa
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(task.userId)
          .collection('tasks')
          .add(task.toFirestore());

      return task.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erro ao criar tarefa: $e');
    }
  }

  /// Atualiza uma tarefa
  Future<void> updateTask(TaskModel task) async {
    try {
      await _firestore
          .collection('users')
          .doc(task.userId)
          .collection('tasks')
          .doc(task.id)
          .update(task.toFirestore());
    } catch (e) {
      throw Exception('Erro ao atualizar tarefa: $e');
    }
  }

  /// Completa uma tarefa
  Future<void> completeTask(TaskModel task) async {
    try {
      await _firestore
          .collection('users')
          .doc(task.userId)
          .collection('tasks')
          .doc(task.id)
          .update({
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erro ao completar tarefa: $e');
    }
  }

  /// Deleta uma tarefa
  Future<void> deleteTask(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar tarefa: $e');
    }
  }

  /// Deleta todas as tarefas linkadas a um objetivo/hábito
  Future<void> deleteTasksByObjectiveId(String userId, String objectiveId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('linkedObjectiveId', isEqualTo: objectiveId)
          .get();

      // Deleta em batch para melhor performance
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao deletar tarefas do objetivo: $e');
    }
  }

  /// Conta quantas tarefas não completadas existem para um objetivo
  Future<int> countPendingTasksByObjectiveId(String userId, String objectiveId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('linkedObjectiveId', isEqualTo: objectiveId)
          .where('isCompleted', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Erro ao contar tarefas pendentes: $e');
    }
  }
}
