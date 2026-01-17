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
      // PASSO 1: Repository é a fonte única de verdade - completa no Isar PRIMEIRO (ATOMIC)
      // Isso garante que a tarefa seja marcada como completa instantaneamente
      await _taskRepository.completeTask(task);
      print('[TASK SERVICE] ✅ Tarefa completada no Isar: ${task.title}');
      
      final updatedTask = task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      
      // PASSO 2: Verifica status online RÁPIDO (não bloqueia - timeout curto)
      final isOnline = await _syncService.isOnline().timeout(
        const Duration(milliseconds: 200),
        onTimeout: () {
          print('[TASK SERVICE] Timeout ao verificar online (assumindo OFFLINE)');
          return false;
        },
      ).catchError((e) {
        print('[TASK SERVICE] Erro ao verificar online (assumindo OFFLINE): $e');
        return false;
      });
      
      // PASSO 3: Atualiza stats e XP em background (não bloqueia quando offline)
      LevelUpInfo? levelUpInfo;
      if (isOnline) {
        // Só tenta atualizar stats se online (evita bloqueios offline)
        try {
          final profile = await _userRepository.getUser(user.uid).timeout(
            const Duration(seconds: 1),
            onTimeout: () => null,
          ).catchError((e) => null);
          
          final isPenaltyZone = profile?.penaltyMessage != null;
          
          levelUpInfo = await _statsService.updateStatsOnTaskComplete(
            statType: task.statType,
            taskRank: task.rank,
            isPenaltyZoneActive: isPenaltyZone,
          ).timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              print('[TASK SERVICE] ⚠️ Timeout ao atualizar stats (continuando)');
              return null;
            },
          ).catchError((e) {
            print('[TASK SERVICE] ⚠️ Erro ao atualizar stats (continuando): $e');
            return null;
          });
        } catch (e) {
          print('[TASK SERVICE] ⚠️ Erro ao atualizar stats (continuando): $e');
        }
      } else {
        print('[TASK SERVICE] Offline - pulando atualização de stats (será feito depois)');
      }

      // PASSO 4: Operações em background (não bloqueiam)
      // Se tarefa linkada a objetivo, atualiza progresso (em background)
      if (task.linkedObjectiveId != null) {
        _updateObjectiveProgress(user.uid, task.linkedObjectiveId!).catchError((e) {
          print('[TASK SERVICE] ⚠️ Erro ao atualizar objetivo (continuando): $e');
        });
      }
      
      // Cancela notificação se existir (funciona offline, não bloqueia)
      _notificationService.cancelNotification(task.id).catchError((e) {
        print('[TASK SERVICE] ⚠️ Erro ao cancelar notificação: $e');
      });
      
      // Deleta evento do Google Calendar (só se online e habilitado, em background)
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

      // Extrai sombra se tarefa for Rank C ou superior (só se online, em background)
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
      print('[TASK SERVICE] ❌ Erro ao completar tarefa: $e');
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

    // PASSO 1: Garante que a tarefa tem um ID único (UUID)
    final uuid = const Uuid();
    final taskWithId = task.id.isEmpty ? task.copyWith(id: uuid.v4()) : task;
    
    // PASSO 2: Repository é a fonte única de verdade - salva no Isar e sincroniza Firestore
    // TaskRepository.createTask() já salva no Isar PRIMEIRO e sincroniza Firestore em background
    await _taskRepository.createTask(taskWithId);
    
    // FASE 1: Agendar notificação se tarefa tiver data/hora (funciona offline)
    if (taskWithId.time != null) {
      await _notificationService.scheduleTaskNotification(taskWithId);
    }
    
    // FASE 2: Sincronizar com Google Calendar se usuário autorizou (em background)
    _calendarService.isCalendarEnabled().then((enabled) {
      if (enabled && taskWithId.time != null) {
        _calendarService.syncTaskToCalendar(taskWithId).then((eventId) {
          if (eventId != null) {
            final updatedTask = taskWithId.copyWith(calendarEventId: eventId);
            _taskRepository.updateTask(updatedTask).catchError((e) {
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
    
    print('[TASK SERVICE] ✅ Tarefa criada e salva instantaneamente: ${taskWithId.title}');
  }

  /// Atualiza uma tarefa existente
  Future<void> updateTask(TaskModel task) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Repository é a fonte única de verdade - atualiza no Isar PRIMEIRO (ATOMIC)
      await _taskRepository.updateTask(task);
      
      // FASE 1: Reagendar notificação se tarefa tiver data/hora e não estiver completa (em background)
      if (task.time != null && !task.isCompleted) {
        // Cancela notificação antiga (se existir) e agenda nova (não bloqueia)
        _notificationService.cancelNotification(task.id).then((_) {
          _notificationService.scheduleTaskNotification(task).catchError((e) {
            print('[TASK SERVICE] ⚠️ Erro ao agendar notificação: $e');
          });
        }).catchError((e) {
          print('[TASK SERVICE] ⚠️ Erro ao cancelar notificação: $e');
        });
      } else {
        // Cancela se não tiver mais horário ou estiver completa (não bloqueia)
        _notificationService.cancelNotification(task.id).catchError((e) {
          print('[TASK SERVICE] ⚠️ Erro ao cancelar notificação: $e');
        });
      }
      
      // FASE 2: Sincronizar com Google Calendar se usuário autorizou (em background, não bloqueia)
      _calendarService.isCalendarEnabled().then((enabled) {
        if (enabled && !task.isCompleted) {
          _calendarService.syncTaskToCalendar(task).then((eventId) {
            if (eventId != null && eventId != task.calendarEventId) {
              // Atualiza tarefa com novo calendarEventId se mudou (em background)
              final updatedTask = task.copyWith(calendarEventId: eventId);
              _taskRepository.updateTask(updatedTask).catchError((e) {
                print('[TASK SERVICE] ⚠️ Erro ao atualizar calendarEventId: $e');
              });
            }
          }).catchError((e) {
            print('[TASK SERVICE] ⚠️ Erro ao sincronizar Calendar: $e');
          });
        } else if (task.calendarEventId != null) {
          // Se desabilitou calendar ou tarefa está completa, deleta evento (em background)
          _calendarService.deleteCalendarEvent(task.calendarEventId!).catchError((e) {
            print('[TASK SERVICE] ⚠️ Erro ao deletar evento do Calendar: $e');
          });
        }
      }).catchError((e) {
        print('[TASK SERVICE] ⚠️ Erro ao verificar Calendar: $e');
      });
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

    // Verifica online rapidamente (não bloqueia)
    final isOnline = await _syncService.isOnline().timeout(
      const Duration(milliseconds: 200),
      onTimeout: () => false,
    ).catchError((e) => false);

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
      
      // FASE 2: Deleta evento do Google Calendar se existir (apenas se online, em background)
      if (task != null && task.calendarEventId != null && isOnline) {
        _calendarService.isCalendarEnabled().then((enabled) {
          if (enabled) {
            _calendarService.deleteCalendarEvent(task!.calendarEventId!).catchError((e) {
              print('[TASK DELETE] ⚠️ Erro ao deletar evento do Calendar: $e');
            });
          }
        }).catchError((e) {
          print('[TASK DELETE] ⚠️ Erro ao verificar Calendar: $e');
        });
      }
      
      
      // Repository é a fonte única de verdade - deleta do Isar PRIMEIRO
      await _taskRepository.deleteTask(user.uid, taskId);
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

  /// Busca todas as tarefas ativas (não completadas) - OFFLINE-FIRST REATIVO
  /// Usa o stream do repositório (que usa Isar.watch()) para atualização automática
  Stream<List<TaskModel>> getActiveTasks() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // Usa o stream do repositório que já usa Isar.watch() para reatividade automática
    // Filtra apenas tarefas não completadas
    return _taskRepository.getTasksStream(user.uid).map((tasks) {
      return tasks.where((t) => !t.isCompleted).toList();
    }).handleError((error) {
      print('[TASK SERVICE] ⚠️ Erro no stream de tarefas ativas: $error');
      return <TaskModel>[];
    });
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
