import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../local/isar_service.dart';
import '../local/isar_models.dart';
import '../repositories/task_repository.dart';
import '../repositories/objective_repository.dart';
import '../repositories/shadow_repository.dart';
import '../repositories/trophy_repository.dart';
import '../models/task_model.dart';
import '../models/objective_model.dart';
import '../models/shadow_model.dart';
import '../models/trophy_model.dart';

/// Serviço para sincronização bidirecional entre Firestore e Isar (local)
class SyncService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Connectivity _connectivity = Connectivity();
  final TaskRepository _taskRepository = TaskRepository();
  final ObjectiveRepository _objectiveRepository = ObjectiveRepository();
  final ShadowRepository _shadowRepository = ShadowRepository();
  final TrophyRepository _trophyRepository = TrophyRepository();

  /// Verifica se há conectividade
  /// Usa connectivity_plus que é mais rápido e confiável no Android
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity()
          .timeout(const Duration(seconds: 2));
      final hasConnection = result.any((connectivity) => 
        connectivity != ConnectivityResult.none
      );
      
      if (!hasConnection) {
        print('[SYNC] ❌ Sem conexão de rede detectada (OFFLINE)');
      } else {
        print('[SYNC] ✅ Conexão de rede detectada (ONLINE)');
      }
      
      return hasConnection;
    } catch (e) {
      print('[SYNC] ❌ Erro ao verificar conectividade (assumindo OFFLINE): $e');
      // Em caso de erro/timeout, assume offline por segurança
      return false;
    }
  }

  /// Sincroniza todas as tarefas (Firestore → Isar e Isar → Firestore)
  Future<void> syncTasks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isar = await IsarService.instance;
    final online = await isOnline();

    if (online) {
      // Sincronização bidirecional quando online
      await _syncTasksOnline(user.uid, isar);
    } else {
      // Quando offline, apenas carrega do Isar (já deve estar atualizado)
      print('[SYNC] Offline - usando dados locais do Isar');
    }
  }

  /// Sincronização online bidirecional de tarefas
  Future<void> _syncTasksOnline(String userId, Isar isar) async {
    try {
      // 1. Baixar tarefas do Firestore e salvar no Isar
      final firestoreTasks = await _taskRepository.getTasks(userId);
      
      // Salvar/criar no Isar
      final isarTasksToSave = <IsarTask>[];
      for (final task in firestoreTasks) {
        final existing = await isar.isarTasks
            .filter()
            .taskIdEqualTo(task.id)
            .findFirst();
        if (existing != null) {
          // Atualiza existente
          final isarTask = IsarTask.fromTaskModel(task, isSynced: true);
          isarTask.id = existing.id; // Mantém ID do Isar
          isarTasksToSave.add(isarTask);
        } else {
          // Cria novo
          isarTasksToSave.add(IsarTask.fromTaskModel(task, isSynced: true));
        }
      }

      await isar.writeTxn(() async {
        for (final task in isarTasksToSave) {
          await isar.isarTasks.put(task);
        }
      });

      print('[SYNC] ✅ ${isarTasksToSave.length} tarefas sincronizadas do Firestore');
      
      // 2. Enviar tarefas criadas/atualizadas offline para Firestore
      await _uploadPendingTasksToFirestore(userId, isar);

    } catch (e) {
      print('[SYNC] ❌ Erro na sincronização de tarefas: $e');
    }
  }

  /// Envia tarefas do Isar que não estão no Firestore (criadas offline)
  Future<void> _uploadPendingTasksToFirestore(String userId, Isar isar) async {
    try {
      // Busca tarefas que precisam sincronizar (criadas offline)
      final pendingTasks = await isar.isarTasks
          .filter()
          .userIdEqualTo(userId)
          .needsSyncEqualTo(true)
          .findAll();
      
      if (pendingTasks.isEmpty) {
        return; // Nada para sincronizar
      }
      
      print('[SYNC] 📤 Enviando ${pendingTasks.length} tarefas pendentes para Firestore...');
      
      for (final isarTask in pendingTasks) {
        try {
          final task = isarTask.toTaskModel();
          
          // Verifica se já existe no Firestore
          final firestoreTasks = await _taskRepository.getTasks(userId).timeout(
            const Duration(seconds: 5),
            onTimeout: () => <TaskModel>[],
          );
          final exists = firestoreTasks.any((t) => t.id == task.id);
          
          if (!exists) {
            // Cria no Firestore
            await _taskRepository.createTask(task);
            print('[SYNC] ✅ Tarefa criada no Firestore: ${task.title}');
          } else {
            // Atualiza no Firestore
            await _taskRepository.updateTask(task);
            print('[SYNC] ✅ Tarefa atualizada no Firestore: ${task.title}');
          }
          
          // Marca como sincronizada
          isarTask.isSynced = true;
          isarTask.needsSync = false;
          isarTask.lastSyncedAt = DateTime.now();
          await isar.writeTxn(() async {
            await isar.isarTasks.put(isarTask);
          });
        } catch (e) {
          print('[SYNC] ❌ Erro ao enviar tarefa ${isarTask.taskId}: $e');
          // Mantém needsSync = true para tentar novamente depois
        }
      }
      
      print('[SYNC] ✅ Upload de tarefas pendentes concluído');
    } catch (e) {
      print('[SYNC] ❌ Erro no upload de tarefas pendentes: $e');
    }
  }

  /// Salva tarefa localmente no Isar - OFFLINE-FIRST
  /// Marca needsSync=true quando offline para sincronizar depois
  Future<void> saveTaskLocally(TaskModel task) async {
    final isar = await IsarService.instance;
    final isOnlineCheck = await isOnline().timeout(
      const Duration(milliseconds: 300),
      onTimeout: () => false,
    );
    
    final isarTask = IsarTask.fromTaskModel(
      task,
      isSynced: isOnlineCheck, // ✅ Só marca como sincronizada se estiver online
      needsSync: !isOnlineCheck, // ✅ Marca como precisa sincronizar se estiver offline
    );

    await isar.writeTxn(() async {
      await isar.isarTasks.put(isarTask);
    });

    if (isOnlineCheck) {
      print('[SYNC] ✅ Tarefa salva localmente (sincronizada): ${task.title}');
    } else {
      print('[SYNC] 📱 Tarefa salva localmente (offline - será sincronizada depois): ${task.title}');
    }
  }

  /// Busca tarefas do Isar (modo offline)
  Future<List<TaskModel>> getTasksFromLocal() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final isar = await IsarService.instance;
    final isarTasks = await isar.isarTasks
        .filter()
        .userIdEqualTo(user.uid)
        .findAll();

    return isarTasks.map((t) => t.toTaskModel()).toList();
  }

  /// Busca uma tarefa específica do Isar (modo offline)
  Future<TaskModel?> getTaskFromLocal(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final isar = await IsarService.instance;
    final isarTask = await isar.isarTasks
        .filter()
        .taskIdEqualTo(taskId)
        .userIdEqualTo(user.uid)
        .findFirst();

    return isarTask?.toTaskModel();
  }

  /// Deleta tarefa localmente do Isar (modo offline)
  Future<void> deleteTaskLocally(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isar = await IsarService.instance;
    final isarTask = await isar.isarTasks
        .filter()
        .taskIdEqualTo(taskId)
        .userIdEqualTo(user.uid)
        .findFirst();

    if (isarTask != null) {
      await isar.writeTxn(() async {
        await isar.isarTasks.delete(isarTask.id);
      });
      print('[SYNC] 📱 Tarefa deletada localmente: $taskId');
    }
  }

  /// Salva objetivo localmente no Isar - OFFLINE-FIRST
  /// Marca needsSync=true quando offline para sincronizar depois
  Future<void> saveObjectiveLocally(ObjectiveModel objective) async {
    final isar = await IsarService.instance;
    final isOnlineCheck = await isOnline().timeout(
      const Duration(milliseconds: 300),
      onTimeout: () => false,
    );
    
    final isarObjective = IsarObjective.fromObjectiveModel(
      objective,
      isSynced: isOnlineCheck, // ✅ Só marca como sincronizada se estiver online
      needsSync: !isOnlineCheck, // ✅ Marca como precisa sincronizar se estiver offline
    );

    await isar.writeTxn(() async {
      await isar.isarObjectives.put(isarObjective);
    });

    if (isOnlineCheck) {
      print('[SYNC] ✅ Objetivo salvo localmente (sincronizado): ${objective.title}');
    } else {
      print('[SYNC] 📱 Objetivo salvo localmente (offline - será sincronizado depois): ${objective.title}');
    }
  }

  /// Busca objetivos do Isar (modo offline)
  Future<List<ObjectiveModel>> getObjectivesFromLocal() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final isar = await IsarService.instance;
    final isarObjectives = await isar.isarObjectives
        .filter()
        .userIdEqualTo(user.uid)
        .findAll();

    return isarObjectives.map((o) => o.toObjectiveModel()).toList();
  }

  /// Salva sombra localmente no Isar
  /// SEMPRE marca como sincronizada (sem fila de sincronização)
  Future<void> saveShadowLocally(ShadowModel shadow) async {
    final isar = await IsarService.instance;
    
    // SEMPRE marca como sincronizada - sem fila de sincronização
    final isarShadow = IsarShadow.fromShadowModel(
      shadow,
      isSynced: true, // Sempre sincronizada (Isar é fonte primária)
      needsSync: false, // Sem fila de sincronização
    );

    await isar.writeTxn(() async {
      await isar.isarShadows.put(isarShadow);
    });

    print('[SYNC] ✅ Sombra salva localmente: ${shadow.name}');
  }

  /// Salva troféu localmente no Isar
  /// SEMPRE marca como sincronizada (sem fila de sincronização)
  Future<void> saveTrophyLocally(TrophyModel trophy) async {
    final isar = await IsarService.instance;
    
    // SEMPRE marca como sincronizada - sem fila de sincronização
    final isarTrophy = IsarTrophy.fromTrophyModel(
      trophy,
      isSynced: true, // Sempre sincronizada (Isar é fonte primária)
      needsSync: false, // Sem fila de sincronização
    );

    await isar.writeTxn(() async {
      await isar.isarTrophys.put(isarTrophy);
    });

    print('[SYNC] ✅ Troféu salvo localmente: ${trophy.title}');
  }

  /// Sincroniza objetivos (similar a tarefas)
  /// Baixa do Firestore → Isar
  /// Envia objetivos criados offline → Firestore
  Future<void> syncObjectives() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isar = await IsarService.instance;
    final online = await isOnline();

    if (online) {
      try {
        // FASE 1: Baixa objetivos do Firestore e salva no Isar
        final firestoreObjectives = await _objectiveRepository.getActiveObjectives(user.uid);
        
        final isarObjectivesToSave = <IsarObjective>[];
        for (final obj in firestoreObjectives) {
          final existing = await isar.isarObjectives
              .filter()
              .objectiveIdEqualTo(obj.id)
              .findFirst();
          if (existing != null) {
            // Atualiza existente
            final isarObj = IsarObjective.fromObjectiveModel(obj, isSynced: true);
            isarObj.id = existing.id;
            isarObjectivesToSave.add(isarObj);
          } else {
            // Cria novo
            isarObjectivesToSave.add(IsarObjective.fromObjectiveModel(obj, isSynced: true));
          }
        }

        await isar.writeTxn(() async {
          for (final obj in isarObjectivesToSave) {
            await isar.isarObjectives.put(obj);
          }
        });

        print('[SYNC] ✅ ${isarObjectivesToSave.length} objetivos sincronizados do Firestore');
        
        // 2. Enviar objetivos criados/atualizados offline para Firestore
        await _uploadPendingObjectivesToFirestore(user.uid, isar);
      } catch (e) {
        print('[SYNC] ❌ Erro ao sincronizar objetivos: $e');
      }
    }
  }

  /// Sincronização completa (todas as entidades) - BIDIRECIONAL
  /// FASE 1: Baixa Firestore → Isar
  /// FASE 2: Envia Isar → Firestore (dados criados offline)
  Future<void> syncAll() async {
    print('[SYNC] Iniciando sincronização completa bidirecional...');
    
    final isOnlineCheck = await isOnline().timeout(
      const Duration(milliseconds: 500),
      onTimeout: () => false,
    );
    
    if (!isOnlineCheck) {
      print('[SYNC] Offline - não é possível sincronizar');
      return;
    }
    
    // FASE 1: Baixa Firestore → Isar
    await syncTasks();
    await syncObjectives();
    
    // FASE 2: Envia Isar → Firestore (dados criados offline)
    final user = _auth.currentUser;
    if (user != null) {
      final isar = await IsarService.instance;
      await _uploadPendingTasksToFirestore(user.uid, isar);
      await _uploadPendingObjectivesToFirestore(user.uid, isar);
    }
    
    // TODO: Adicionar Shadows e Trophies quando necessário
    print('[SYNC] ✅ Sincronização completa bidirecional finalizada');
  }
  
  /// Envia objetivos do Isar que não estão no Firestore (criados offline)
  Future<void> _uploadPendingObjectivesToFirestore(String userId, Isar isar) async {
    try {
      // Busca objetivos que precisam sincronizar (criados offline)
      final pendingObjectives = await isar.isarObjectives
          .filter()
          .userIdEqualTo(userId)
          .needsSyncEqualTo(true)
          .findAll();
      
      if (pendingObjectives.isEmpty) {
        return; // Nada para sincronizar
      }
      
      print('[SYNC] 📤 Enviando ${pendingObjectives.length} objetivos pendentes para Firestore...');
      
      for (final isarObj in pendingObjectives) {
        try {
          final obj = isarObj.toObjectiveModel();
          
          // Verifica se já existe no Firestore
          final firestoreObjectives = await _objectiveRepository.getActiveObjectives(userId).timeout(
            const Duration(seconds: 5),
            onTimeout: () => <ObjectiveModel>[],
          );
          final exists = firestoreObjectives.any((o) => o.id == obj.id);
          
          if (!exists) {
            // Cria no Firestore
            await _objectiveRepository.createObjective(obj);
            print('[SYNC] ✅ Objetivo criado no Firestore: ${obj.title}');
          } else {
            // Atualiza no Firestore
            await _objectiveRepository.updateObjective(obj);
            print('[SYNC] ✅ Objetivo atualizado no Firestore: ${obj.title}');
          }
          
          // Marca como sincronizado
          isarObj.isSynced = true;
          isarObj.needsSync = false;
          isarObj.lastSyncedAt = DateTime.now();
          await isar.writeTxn(() async {
            await isar.isarObjectives.put(isarObj);
          });
        } catch (e) {
          print('[SYNC] ❌ Erro ao enviar objetivo ${isarObj.objectiveId}: $e');
          // Mantém needsSync = true para tentar novamente depois
        }
      }
      
      print('[SYNC] ✅ Upload de objetivos pendentes concluído');
    } catch (e) {
      print('[SYNC] ❌ Erro no upload de objetivos pendentes: $e');
    }
  }
}
