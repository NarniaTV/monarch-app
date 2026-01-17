import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/constants.dart';
import '../models/task_model.dart';
import '../models/shadow_model.dart';
import '../repositories/task_repository.dart';
import '../repositories/objective_repository.dart';
import '../repositories/user_repository.dart';
import 'stats_service.dart';
import 'shadow_service.dart';
import 'trophy_service.dart';
import 'notification_service.dart';
import 'calendar_service.dart';
import 'sync_service.dart';
import 'package:uuid/uuid.dart';

/// Resultado da conclusão de uma tarefa
class TaskCompletionResult {
  final LevelUpInfo? levelUpInfo;
  final ShadowModel? extractedShadow;

  TaskCompletionResult({
    this.levelUpInfo,
    this.extractedShadow,
  });
}

/// Service para gerenciar lógica de negócio de tarefas
class TaskService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TaskRepository _taskRepository = TaskRepository();
  final ObjectiveRepository _objectiveRepository = ObjectiveRepository();
  final UserRepository _userRepository = UserRepository();
  final StatsService _statsService = StatsService();
  final ShadowService _shadowService = ShadowService();
  final TrophyService _trophyService = TrophyService();
  final NotificationService _notificationService = NotificationService();
  final CalendarService _calendarService = CalendarService();
  final SyncService _syncService = SyncService();

  /// Completa uma tarefa e atualiza stats/XP
  /// 
  /// Retorna [TaskCompletionResult] com level up e sombra extraída (se houver)
  Future<TaskCompletionResult> completeTask(TaskModel task) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // PASSO 1: Marca tarefa como completa PRIMEIRO (sempre funciona offline)
      final updatedTask = task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      
      // OFFLINE-FIRST: SEMPRE salva no Isar PRIMEIRO (fonte primária - funciona offline)
      print('[TASK SERVICE] ✅ Salvando tarefa completada PRIMEIRO no Isar: ${updatedTask.title}');
      await _syncService.saveTaskLocally(updatedTask);
      
      // PASSO 2: Atualiza stats e XP (funciona offline - salva localmente)
      final levelUpInfo = await _statsService.updateStatsOnTaskComplete(
        statType: task.statType,
        taskRank: task.rank,
        isPenaltyZoneActive: false, // Simplificado para funcionar offline
      ).catchError((e) {
        print('[TASK SERVICE] ⚠️ Erro ao atualizar stats (continuando): $e');
        return null; // Retorna null se falhar
      });

      // PASSO 3: Se online, tenta operações que dependem de Firestore (não bloqueia se falhar)
      final isOnline = await _syncService.isOnline().timeout(
        const Duration(milliseconds: 300),
        onTimeout: () => false,
      );
      
      if (isOnline) {
        // Verifica Penalty Zone (só se online)
        _userRepository.getUser(user.uid).then((profile) {
          // Recalcula stats se necessário (opcional)
        }).catchError((e) {
          print('[TASK SERVICE] ⚠️ Erro ao buscar perfil: $e');
        });
        
        // Atualiza no Firestore em background (não bloqueia)
        _taskRepository.updateTask(updatedTask).catchError((e) {
          print('[TASK SERVICE] ⚠️ Erro ao atualizar no Firestore (já salvo localmente): $e');
        });
      }

      // PASSO 4: Se tarefa linkada a objetivo e online, atualiza progresso (em background)
      if (task.linkedObjectiveId != null && isOnline) {
        _updateObjectiveProgress(user.uid, task.linkedObjectiveId!).catchError((e) {
          print('[TASK SERVICE] ⚠️ Erro ao atualizar objetivo (continuando): $e');
        });
      }
      
      // FASE 1: Cancela notificação se existir (funciona offline)
      await _notificationService.cancelNotification(task.id).catchError((e) {
        print('[TASK SERVICE] ⚠️ Erro ao cancelar notificação: $e');
      });
      
      // FASE 2: Deleta evento do Google Calendar (só se online e habilitado)
      if (isOnline && task.calendarEventId != null) {
        _calendarService.isCalendarEnabled().then((enabled) {
          if (enabled) {
            _calendarService.deleteCalendarEvent(task.calendarEventId!).catchError((e) {
              print('[TASK COMPLETE] ⚠️ Erro ao deletar evento do Calendar: $e');
            });
          }
        }).catchError((e) {
          print('[TASK COMPLETE] ⚠️ Erro ao verificar Calendar: $e');
        });
      }

      // FASE 7: Extrai sombra se tarefa for Rank C ou superior (só se online)
      ShadowModel? extractedShadow;
      if (isOnline && (task.rank == TaskRank.a || task.rank == TaskRank.c || task.rank == TaskRank.d)) {
        _shadowService.extractShadowFromTask(updatedTask).then((shadow) {
          extractedShadow = shadow;
        }).catchError((e) {
          print('[TASK SERVICE] ⚠️ Erro ao extrair sombra: $e');
        });
      }

      // Retorna resultado com level up e sombra extraída
      return TaskCompletionResult(
        levelUpInfo: levelUpInfo,
        extractedShadow: extractedShadow,
      );
    } catch (e) {
      throw Exception('Erro ao completar tarefa: $e');
    }
  }

  /// Atualiza progresso de um objetivo S quando uma tarefa linkada é concluída
  /// Retorna true se o objetivo foi completado (100%)
  Future<bool> _updateObjectiveProgress(
      String userId, String objectiveId) async {
    try {
      // Busca todos os objetivos ativos do usuário
      final objectives = await _objectiveRepository.getActiveObjectives(userId);
      final objective = objectives.where((o) => o.id == objectiveId).firstOrNull;
      
      if (objective == null) return false;

      // Incrementa progresso
      final newProgress = (objective.progress + 1).clamp(0, 100);
      final updatedObjective = objective.copyWith(
        progress: newProgress,
        completedAt: newProgress >= 100 ? DateTime.now() : null,
      );

      await _objectiveRepository.updateObjective(updatedObjective);

      // FASE 7: Se objetivo S foi completado (100%), cria troféu e extrai sombra
      if (newProgress >= 100 && objective.rank == ObjectiveRank.s) {
        try {
          // Cria troféu
          await _trophyService.createTrophyFromObjective(updatedObjective);
          
          // Extrai sombra dourada
          await _shadowService.extractShadowFromObjective(updatedObjective);
        } catch (e) {
          // Log erro mas não interrompe o fluxo
          print('Erro ao criar troféu/sombra do objetivo S: $e');
        }
      }

      return newProgress >= 100;
    } catch (e) {
      throw Exception('Erro ao atualizar progresso do objetivo: $e');
    }
  }

  /// Descompleta uma tarefa (desfazer)
  Future<void> uncompleteTask(TaskModel task) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Marca tarefa como não completa
      final updatedTask = task.copyWith(
        isCompleted: false,
        completedAt: null,
      );
      await _taskRepository.updateTask(updatedTask);

      // TODO: Reverter stats/XP? (pode ser complexo, deixar para depois)
    } catch (e) {
      throw Exception('Erro ao descompletar tarefa: $e');
    }
  }

  /// Cria uma nova tarefa - OFFLINE-FIRST
  /// SEMPRE salva PRIMEIRO no Isar (retorna sucesso imediatamente)
  /// Se online, sincroniza com Firestore em background
  Future<void> createTask(TaskModel task) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // PASSO 1: SEMPRE salvar no Isar PRIMEIRO (fonte primária - funciona offline e online)
    final uuid = const Uuid();
    final taskWithId = task.id.isEmpty ? task.copyWith(id: uuid.v4()) : task;
    
    print('[TASK SERVICE] ✅ Salvando tarefa PRIMEIRO no Isar: ${taskWithId.title}');
    await _syncService.saveTaskLocally(taskWithId); // ✅ SALVA PRIMEIRO AQUI
    
    // FASE 1: Agendar notificação se tarefa tiver data/hora (funciona offline)
    if (taskWithId.time != null) {
      await _notificationService.scheduleTaskNotification(taskWithId);
    }
    
    // PASSO 2: Se online, sincroniza com Firestore em background (não bloqueia retorno)
    final isOnline = await _syncService.isOnline().timeout(
      const Duration(milliseconds: 500),
      onTimeout: () => false,
    );
    
    if (isOnline) {
      // Sincroniza em background sem esperar
      _taskRepository.createTask(taskWithId).then((createdTask) {
        // Atualiza Isar com ID do Firestore se diferente
        if (createdTask.id != taskWithId.id) {
          _syncService.saveTaskLocally(createdTask).catchError((e) {
            print('[TASK SERVICE] ⚠️ Erro ao atualizar Isar: $e');
          });
        }
        
        // FASE 2: Sincronizar com Google Calendar se usuário autorizou
        _calendarService.isCalendarEnabled().then((enabled) {
          if (enabled && taskWithId.time != null) {
            _calendarService.syncTaskToCalendar(createdTask).then((eventId) {
              if (eventId != null) {
                final updatedTask = createdTask.copyWith(calendarEventId: eventId);
                _taskRepository.updateTask(updatedTask).then((_) {
                  _syncService.saveTaskLocally(updatedTask).catchError((e) {
                    print('[TASK SERVICE] ⚠️ Erro ao salvar calendarEventId: $e');
                  });
                }).catchError((e) {
                  print('[TASK SERVICE] ⚠️ Erro ao atualizar calendarEventId: $e');
                });
              }
            }).catchError((e) {
              print('[TASK SERVICE] ⚠️ Erro ao sincronizar Calendar: $e');
            });
          }
        }).catchError((e) {
          print('[TASK SERVICE] ⚠️ Erro ao verificar Calendar: $e');
        });
        
        print('[TASK SERVICE] ✅ Tarefa sincronizada com Firestore: ${taskWithId.title}');
      }).catchError((e) {
        print('[TASK SERVICE] ⚠️ Erro ao criar no Firestore (já salvo localmente): $e');
        // Não interrompe - já foi salva no Isar
      });
    }
    
    print('[TASK SERVICE] ✅ Tarefa criada e salva instantaneamente: ${taskWithId.title}');
  }

  /// Atualiza uma tarefa existente
  Future<void> updateTask(TaskModel task) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // OFFLINE-FIRST: SEMPRE salva no Isar PRIMEIRO (fonte primária)
      await _syncService.saveTaskLocally(task);
      
      // Se online, atualiza no Firestore também (em background)
      final isOnline = await _syncService.isOnline();
      if (isOnline) {
        _taskRepository.updateTask(task).catchError((e) {
          print('[TASK SERVICE] ⚠️ Erro ao atualizar no Firestore (já salvo localmente): $e');
        });
      }
      
      // FASE 1: Reagendar notificação se tarefa tiver data/hora e não estiver completa
      if (task.time != null && !task.isCompleted) {
        // Cancela notificação antiga (se existir)
        await _notificationService.cancelNotification(task.id);
        
        // Agenda nova notificação
        await _notificationService.scheduleTaskNotification(task);
      } else {
        // Cancela se não tiver mais horário ou estiver completa
        await _notificationService.cancelNotification(task.id);
      }
      
      // FASE 2: Sincronizar com Google Calendar se usuário autorizou
      if (await _calendarService.isCalendarEnabled() && !task.isCompleted) {
        final eventId = await _calendarService.syncTaskToCalendar(task);
        if (eventId != null && eventId != task.calendarEventId) {
          // Atualiza tarefa com novo calendarEventId se mudou
          final updatedTask = task.copyWith(calendarEventId: eventId);
          await _taskRepository.updateTask(updatedTask);
        }
      } else if (task.calendarEventId != null) {
        // Se desabilitou calendar ou tarefa está completa, deleta evento
        await _calendarService.deleteCalendarEvent(task.calendarEventId!);
      }
    } catch (e) {
      throw Exception('Erro ao atualizar tarefa: $e');
    }
  }

  /// Deleta uma tarefa
  Future<void> deleteTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final isOnline = await _syncService.isOnline();

    try {
      // Busca tarefa do Isar PRIMEIRO (fonte primária)
      TaskModel? task = await _syncService.getTaskFromLocal(taskId);
      
      // Se não encontrar no Isar e estiver online, tenta buscar do Firestore
      if (task == null && isOnline) {
        try {
          final tasks = await _taskRepository.getTasks(user.uid);
          task = tasks.firstWhere((t) => t.id == taskId, orElse: () => throw Exception('Tarefa não encontrada'));
        } catch (e) {
          print('[TASK SERVICE] ⚠️ Tarefa não encontrada: $taskId');
        }
      }
      
      // FASE 2: Deleta evento do Google Calendar se existir (apenas se online)
      if (task != null && task.calendarEventId != null && await _calendarService.isCalendarEnabled() && isOnline) {
        try {
          await _calendarService.deleteCalendarEvent(task.calendarEventId!);
        } catch (e) {
          print('[TASK SERVICE] ⚠️ Erro ao deletar evento do Calendar: $e');
        }
      }
      
      // SEMPRE deleta do Isar PRIMEIRO (fonte primária)
      await _syncService.deleteTaskLocally(taskId);
      
      // Se online, também deleta do Firestore
      if (isOnline) {
        try {
          await _taskRepository.deleteTask(user.uid, taskId);
        } catch (e) {
          print('[TASK SERVICE] ⚠️ Erro ao deletar do Firestore (já deletado localmente): $e');
        }
      }
    } catch (e) {
      print('[TASK SERVICE] ❌ Erro ao deletar tarefa: $e');
      throw Exception('Erro ao deletar tarefa: $e');
    }
  }

  /// Busca tarefas por rank (retorna Stream de Future)
  Stream<List<TaskModel>> getTasksByRank(TaskRank rank) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // Cria stream que atualiza a cada 1 segundo (polling simplificado)
    // Em produção, usar Firestore snapshots no repository
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return _taskRepository.getTasksByRank(user.uid, rank);
    }).asyncMap((future) => future);
  }

  /// Busca todas as tarefas ativas (não completadas) - OFFLINE-FIRST
  /// SEMPRE lê PRIMEIRO do Isar (retorna imediatamente)
  /// Sincroniza do Firestore em background quando online
  Stream<List<TaskModel>> getActiveTasks() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    // VERIFICA STATUS ONLINE PRIMEIRO (rápido, sem esperar timeout)
    // Isso evita tentar conectar ao Firestore quando offline
    final isOnlineCheck = await _syncService.isOnline().timeout(
      const Duration(milliseconds: 500),
      onTimeout: () {
        print('[TASK SERVICE] Timeout ao verificar conectividade (assumindo OFFLINE)');
        return false;
      },
    );

    // OFFLINE-FIRST: Lê PRIMEIRO do Isar (fonte primária - retorna imediatamente)
    try {
      final localTasks = await _syncService.getTasksFromLocal();
      final activeLocalTasks = localTasks.where((t) => !t.isCompleted).toList();
      print('[TASK SERVICE] ✅ ${activeLocalTasks.length} tarefas ativas encontradas localmente (exibindo imediatamente)');
      
      // Emite dados locais imediatamente
      yield activeLocalTasks;
    } catch (e) {
      print('[TASK SERVICE] ⚠️ Erro ao buscar tarefas locais: $e');
      yield [];
      return; // Para o stream se houver erro ao buscar localmente
    }

    // Se offline, NÃO tenta conectar ao Firestore - finaliza stream imediatamente
    if (!isOnlineCheck) {
      print('[TASK SERVICE] Offline - usando apenas dados locais do Isar (stream finalizado)');
      return; // Finaliza stream imediatamente - não bloqueia UI
    }

    // Online: Usa stream do Repository (que já lê do Isar primeiro e sincroniza em background)
    // getTasksStream() já implementa offline-first (lê Isar primeiro)
    try {
      await for (final tasks in _taskRepository.getTasksStream(user.uid)) {
        try {
          final activeTasks = tasks.where((t) => !t.isCompleted).toList();
          
          // Emite atualização quando sincronização completar
          yield activeTasks;
        } catch (e) {
          print('[TASK SERVICE] ⚠️ Erro ao processar tarefas do stream: $e');
          // Não emite novamente - mantém dados locais já emitidos
        }
      }
    } catch (error, stackTrace) {
      print('[TASK SERVICE] ⚠️ Erro no stream (mantendo dados locais): $error');
      print('[TASK SERVICE] Stack trace: $stackTrace');
      // Não emite novamente - já emitiu dados locais acima
      return; // Finaliza o stream para evitar loops
    }
  }

  /// Busca tarefas completadas
  Stream<List<TaskModel>> getCompletedTasks() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // Usa stream do repository com tratamento de erro
    return _taskRepository.getTasksStream(user.uid).map((tasks) {
      try {
        return tasks.where((t) => t.isCompleted).toList();
      } catch (e) {
        print('Erro ao filtrar tarefas completadas: $e');
        return <TaskModel>[];
      }
    }).handleError((error, stackTrace) {
      print('Erro no stream de tarefas completadas: $error');
      print('Stack trace: $stackTrace');
    });
  }

  /// Sincroniza todas as tarefas existentes com Google Calendar
  /// Usado quando o usuário conecta o Google Calendar pela primeira vez
  Future<int> syncAllExistingTasksToCalendar() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('[SYNC CALENDAR] Usuário não autenticado');
      return 0;
    }

    // Verifica se calendar está habilitado
    final isEnabled = await _calendarService.isCalendarEnabled();
    print('[SYNC CALENDAR] Calendar habilitado: $isEnabled');
    
    if (!isEnabled) {
      print('[SYNC CALENDAR] Calendar não habilitado, abortando sincronização');
      return 0;
    }

    // Verifica se está autenticado
    if (!_calendarService.isAuthenticated) {
      print('[SYNC CALENDAR] Calendar não autenticado, abortando sincronização');
      return 0;
    }

    try {
      // Busca todas as tarefas ativas que não têm calendarEventId e têm horário
      final allTasks = await _taskRepository.getTasks(user.uid);
      print('[SYNC CALENDAR] Total de tarefas encontradas: ${allTasks.length}');
      
      final tasksToSync = allTasks.where((task) {
        final shouldSync = !task.isCompleted && 
               task.time != null && 
               task.calendarEventId == null;
        if (shouldSync) {
          print('[SYNC CALENDAR] Tarefa a sincronizar: ${task.title} (time: ${task.time}, completed: ${task.isCompleted}, eventId: ${task.calendarEventId})');
        }
        return shouldSync;
      }).toList();

      print('[SYNC CALENDAR] Tarefas a sincronizar: ${tasksToSync.length}');
      
      if (tasksToSync.isEmpty) {
        print('[SYNC CALENDAR] Nenhuma tarefa para sincronizar');
        return 0;
      }

      int syncedCount = 0;
      int errorCount = 0;
      
      // Sincroniza cada tarefa
      for (final task in tasksToSync) {
        try {
          print('[SYNC CALENDAR] Sincronizando tarefa: ${task.title}');
          final eventId = await _calendarService.syncTaskToCalendar(task);
          if (eventId != null) {
            print('[SYNC CALENDAR] Evento criado com ID: $eventId');
            // Atualiza tarefa com calendarEventId
            final updatedTask = task.copyWith(calendarEventId: eventId);
            await _taskRepository.updateTask(updatedTask);
            syncedCount++;
            print('[SYNC CALENDAR] Tarefa ${task.title} sincronizada com sucesso');
          } else {
            print('[SYNC CALENDAR] Erro: syncTaskToCalendar retornou null para ${task.title}');
            errorCount++;
          }
        } catch (e, stackTrace) {
          print('[SYNC CALENDAR] Erro ao sincronizar tarefa ${task.id} (${task.title}): $e');
          print('[SYNC CALENDAR] Stack trace: $stackTrace');
          errorCount++;
          // Continua sincronizando outras tarefas mesmo se uma falhar
        }
      }

      print('[SYNC CALENDAR] Sincronização concluída: $syncedCount sucesso, $errorCount erros');
      return syncedCount;
    } catch (e, stackTrace) {
      print('[SYNC CALENDAR] Erro geral ao sincronizar tarefas existentes: $e');
      print('[SYNC CALENDAR] Stack trace: $stackTrace');
      return 0;
    }
  }
}
