import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../core/utils/constants.dart';
import '../local/isar_service.dart';
import '../local/isar_models.dart';

/// Repository para gerenciar Tarefas - OFFLINE-FIRST
/// Sempre salva no Isar primeiro, sincroniza Firestore em background
class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- MÉTODOS DE LEITURA (OFFLINE-FIRST) ---

  /// Busca todas as tarefas do usuário
  /// Lê do Isar primeiro, depois sincroniza do Firestore se online
  Future<List<TaskModel>> getTasks(String userId) async {
    // 1. Lê do Isar (Rápido)
    final isar = await IsarService.instance;
    final isarTasks = await isar.isarTasks
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    
    // Se tiver dados locais, retorna eles
    if (isarTasks.isNotEmpty) {
      return isarTasks.map((t) => t.toTaskModel()).toList();
    }

    // Se Isar vazio (primeiro uso), tenta Firestore
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 5));
      
      final tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      
      // Salva no Isar para próximas leituras
      for (final task in tasks) {
        _saveLocalOnly(task).catchError((e) => print('[TASK REPO] Erro ao salvar: $e'));
      }
      
      return tasks;
    } catch (e) {
      print('[TASK REPO] ⚠️ Erro ao buscar do Firestore: $e');
      return [];
    }
  }

  /// Stream de todas as tarefas - OFFLINE-FIRST com REATIVIDADE AUTOMÁTICA
  /// Usa Isar.watch() para atualização instantânea quando dados mudam
  /// Sincroniza do Firestore em background quando online
  Stream<List<TaskModel>> getTasksStream(String userId) {
    // Sincroniza do Firestore em background (não interfere no watch)
    _syncFromFirestoreInBackground(userId).catchError((e) {
      print('[TASK REPO] ⚠️ Erro na sincronização background: $e');
    });
    
    // Retorna o stream do Isar watch (reatividade automática)
    // Isar.watch() dispara eventos sempre que há put/delete no banco
    return IsarService.instance.then((isar) {
      return isar.isarTasks
          .filter()
          .userIdEqualTo(userId)
          .watch(fireImmediately: true)
          .map((isarTasks) {
            final tasks = isarTasks.map((t) => t.toTaskModel()).toList();
            // Ordena por createdAt descendente
            tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            print('[TASK REPO] ✅ ${tasks.length} tarefas encontradas (reativo)');
            return tasks;
          });
    }).asStream().asyncExpand((stream) => stream).handleError((error) {
      print('[TASK REPO] ⚠️ Erro no watch Isar: $error');
      return <TaskModel>[];
    });
  }

  /// Sincroniza do Firestore em background (não bloqueia o watch do Isar)
  Future<void> _syncFromFirestoreInBackground(String userId) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.every((result) => result == ConnectivityResult.none)) {
      print('[TASK REPO] Offline - usando apenas dados locais (watch Isar ativo)');
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 5));

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

      // Atualiza Isar em background (isso dispara o watch automaticamente)
      for (final task in tasks) {
        _saveLocalOnly(task).catchError((e) {
          print('[TASK REPO] Erro ao salvar localmente: $e');
        });
      }
      
      print('[TASK REPO] ☁️ Sincronização Firestore concluída (watch Isar atualizado)');
    } catch (e) {
      print('[TASK REPO] ⚠️ Erro ao sincronizar do Firestore: $e');
    }
  }

  /// Busca tarefas por rank - OFFLINE-FIRST
  Future<List<TaskModel>> getTasksByRank(String userId, TaskRank rank) async {
    // Implementação simplificada lendo do Isar
    final isar = await IsarService.instance;
    final tasks = await isar.isarTasks
        .filter()
        .userIdEqualTo(userId)
        .rankEqualTo(rank.name)
        .isCompletedEqualTo(false)
        .findAll();
    return tasks.map((t) => t.toTaskModel()).toList();
  }

  /// Busca tarefas vinculadas a um objetivo
  Future<List<TaskModel>> getTasksByObjective(String userId, String objectiveId) async {
    // Lê do Isar primeiro
    final isar = await IsarService.instance;
    final tasks = await isar.isarTasks
        .filter()
        .userIdEqualTo(userId)
        .linkedObjectiveIdEqualTo(objectiveId)
        .findAll();
    
    if (tasks.isNotEmpty) {
      return tasks.map((t) => t.toTaskModel()).toList();
    }
    
    // Fallback para Firestore se não encontrar no Isar
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('linkedObjectiveId', isEqualTo: objectiveId)
          .get()
          .timeout(const Duration(seconds: 5));

      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('[TASK REPO] ⚠️ Erro ao buscar tarefas por objetivo: $e');
      return [];
    }
  }

  // --- MÉTODOS DE ESCRITA (CORRIGIDOS - OFFLINE FIRST) ---

  /// Cria uma nova tarefa - OFFLINE-FIRST
  /// Salva no Isar PRIMEIRO, sincroniza Firestore em background
  /// Retorna a tarefa com o ID gerado (UUID)
  /// 
  /// Se a task não tiver ID, gera UUID v4 automaticamente
  Future<TaskModel> createTask(TaskModel task) async {
    // 1. Garante que a tarefa tem um ID único (UUID v4)
    final uuid = const Uuid();
    final taskWithId = task.id.isEmpty ? task.copyWith(id: uuid.v4()) : task;
    
    // 2. Salva no Isar IMEDIATAMENTE (Sem depender de internet ou SyncService)
    await _saveLocalOnly(taskWithId);

    // 3. Tenta enviar para nuvem em background (Fire and Forget)
    _trySyncToFirestore(taskWithId);
    
    // Retorna task com ID já existente (UUID gerado localmente)
    return taskWithId;
  }

  /// Atualiza uma tarefa - OFFLINE-FIRST (ATOMIC READ-MODIFY-WRITE)
  Future<void> updateTask(TaskModel task) async {
    final isar = await IsarService.instance;
    
    await isar.writeTxn(() async {
      // 1. Busca o objeto REAL do banco local usando o UUID
      final isarTask = await isar.isarTasks
          .filter()
          .taskIdEqualTo(task.id)
          .findFirst();
      
      if (isarTask == null) {
        // Se não existe, cria novo (caso edge)
        final newIsarTask = IsarTask.fromTaskModel(
          task,
          isSynced: false,
          needsSync: true,
        );
        await isar.isarTasks.put(newIsarTask);
        print('[TASK REPO] ✅ Tarefa criada (não existia): ${task.title}');
        return;
      }
      
      // 2. Modifica as propriedades no objeto recuperado (preserva id interno)
      isarTask.title = task.title;
      isarTask.description = task.description;
      isarTask.rank = task.rank.name;
      isarTask.statType = task.statType.name;
      isarTask.tags = List<String>.from(task.tags);
      isarTask.xpReward = task.xpReward;
      isarTask.isCompleted = task.isCompleted;
      isarTask.completedAt = task.completedAt;
      isarTask.linkedObjectiveId = task.linkedObjectiveId;
      isarTask.time = task.time;
      isarTask.calendarEventId = task.calendarEventId;
      
      // Marca para sincronização
      isarTask.isSynced = false;
      isarTask.needsSync = true;
      
      // 3. Salva o MESMO objeto (mantendo o id interno)
      await isar.isarTasks.put(isarTask);
      print('[TASK REPO] ✅ Tarefa atualizada localmente: ${task.title}');
    });
    
    // 4. Tenta sync em background (Fire and Forget)
    _trySyncToFirestore(task);
  }

  /// Completa uma tarefa - OFFLINE-FIRST (ATOMIC READ-MODIFY-WRITE)
  Future<void> completeTask(TaskModel task) async {
    final isar = await IsarService.instance;
    
    await isar.writeTxn(() async {
      // 1. Busca o objeto REAL do banco local usando o UUID
      final isarTask = await isar.isarTasks
          .filter()
          .taskIdEqualTo(task.id)
          .findFirst();
      
      if (isarTask == null) {
        print('[TASK REPO] ⚠️ Tarefa não encontrada para completar: ${task.id}');
        return;
      }
      
      // 2. Modifica as propriedades no objeto recuperado
      isarTask.isCompleted = true;
      isarTask.completedAt = DateTime.now();
      isarTask.isSynced = false; // Marca para sync
      isarTask.needsSync = true;
      
      // 3. Salva o MESMO objeto (mantendo o id interno)
      await isar.isarTasks.put(isarTask);
      print('[TASK REPO] ✅ Tarefa completada localmente: ${task.title}');
    });
    
    // 4. Tenta sync em background (Fire and Forget)
    final completedTask = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    _trySyncToFirestore(completedTask);
  }

  /// Deleta uma tarefa - OFFLINE-FIRST
  Future<void> deleteTask(String userId, String taskId) async {
    // 1. Deleta do Isar
    final isar = await IsarService.instance;
    final existing = await isar.isarTasks
        .filter()
        .taskIdEqualTo(taskId)
        .findFirst();
    
    if (existing != null) {
      await isar.writeTxn(() async {
        await isar.isarTasks.delete(existing.id);
      });
    }

    // 2. Deleta do Firestore (silenciosamente em background)
    _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete()
        .catchError((e) => print('[TASK REPO] Erro ao deletar no Firestore (será sincronizado depois): $e'));
  }

  // --- MÉTODOS AUXILIARES PRIVADOS ---

  /// Salva no Isar marcando como 'needsSync = true' (Pessimista)
  Future<void> _saveLocalOnly(TaskModel task) async {
    final isar = await IsarService.instance;
    
    // Converte para modelo do Isar
    // Assumimos 'needsSync = true' por padrão. Se a net funcionar depois, mudamos pra false.
    final isarTask = IsarTask.fromTaskModel(
      task, 
      isSynced: false, 
      needsSync: true,
    );

    // Precisamos manter o ID interno do Isar se já existir
    final existing = await isar.isarTasks.filter().taskIdEqualTo(task.id).findFirst();
    if (existing != null) {
      isarTask.id = existing.id;
    }

    await isar.writeTxn(() async {
      await isar.isarTasks.put(isarTask);
    });
    
    print('[TASK REPO] ✅ Tarefa salva localmente: ${task.title}');
  }

  /// Tenta enviar pro Firestore sem travar a UI
  Future<void> _trySyncToFirestore(TaskModel task) async {
    // Verifica conexão rapidinho
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.every((result) => result == ConnectivityResult.none)) {
      print('[TASK REPO] Offline - tarefa será sincronizada depois: ${task.title}');
      return; // Sem net, deixa quieto (já tá salvo no Isar com needsSync=true)
    }

    try {
      await _firestore
          .collection('users')
          .doc(task.userId)
          .collection('tasks')
          .doc(task.id)
          .set(task.toFirestore(), SetOptions(merge: true));

      // Se chegou aqui, salvou na nuvem! Atualiza o Isar para needsSync = false
      final isar = await IsarService.instance;
      final existing = await isar.isarTasks.filter().taskIdEqualTo(task.id).findFirst();
      
      if (existing != null) {
        existing.isSynced = true;
        existing.needsSync = false;
        existing.lastSyncedAt = DateTime.now();
        await isar.writeTxn(() async {
          await isar.isarTasks.put(existing);
        });
        print('[TASK REPO] ☁️ Sincronizado com sucesso: ${task.title}');
      }
    } catch (e) {
      print('[TASK REPO] ⚠️ Falha no upload (SyncService pegará depois): $e');
    }
  }

  /// Deleta todas as tarefas linkadas a um objetivo/hábito
  Future<void> deleteTasksByObjectiveId(String userId, String objectiveId) async {
    // Deleta do Isar primeiro
    final isar = await IsarService.instance;
    final tasksToDelete = await isar.isarTasks
        .filter()
        .userIdEqualTo(userId)
        .linkedObjectiveIdEqualTo(objectiveId)
        .findAll();
    
    if (tasksToDelete.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final task in tasksToDelete) {
          await isar.isarTasks.delete(task.id);
        }
      });
    }

    // Deleta do Firestore em background (não bloqueia)
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('linkedObjectiveId', isEqualTo: objectiveId)
          .get()
          .timeout(const Duration(seconds: 5));

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('[TASK REPO] ⚠️ Erro ao deletar tarefas do objetivo no Firestore (já deletado localmente): $e');
    }
  }

  /// Conta quantas tarefas não completadas existem para um objetivo
  Future<int> countPendingTasksByObjectiveId(String userId, String objectiveId) async {
    // Lê do Isar primeiro
    final isar = await IsarService.instance;
    final tasks = await isar.isarTasks
        .filter()
        .userIdEqualTo(userId)
        .linkedObjectiveIdEqualTo(objectiveId)
        .isCompletedEqualTo(false)
        .findAll();
    
    return tasks.length;
  }
}
