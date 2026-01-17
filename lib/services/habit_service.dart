import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/constants.dart';
import '../models/objective_model.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import 'notification_service.dart';
import 'calendar_service.dart';

/// Service para gerenciar hábitos e gerar tarefas recorrentes
class HabitService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TaskRepository _taskRepository = TaskRepository();
  final NotificationService _notificationService = NotificationService();
  final CalendarService _calendarService = CalendarService();

  /// Gera tarefas recorrentes para um hábito baseado na frequência
  Future<void> generateRecurringTasksForHabit(ObjectiveModel habit) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    if (habit.rank != ObjectiveRank.b) {
      throw Exception('Apenas hábitos (Rank B) geram tarefas recorrentes');
    }

    if (habit.frequencyType == null) {
      throw Exception('Hábito sem frequência definida');
    }

    try {
      final tasks = _generateTasksForFrequency(habit);
      
      for (final task in tasks) {
        await _taskRepository.createTask(task);
        
        // FASE 1: Agenda notificação para cada tarefa gerada (se tiver horário)
        if (task.time != null) {
          await _notificationService.scheduleTaskNotification(task);
        }
      }
      
      // FASE 1: Agenda notificação do hábito em si (no horário configurado)
      if (habit.time != null) {
        await _notificationService.scheduleHabitNotification(habit);
      }
      
      // FASE 1: Agenda notificação de streak em risco (23:59)
      await _notificationService.scheduleStreakRiskNotification(habit.id, habit.title);
      
      // FASE 2: Sincroniza hábito com Google Calendar (cria evento recorrente)
      if (await _calendarService.isCalendarEnabled() && habit.time != null) {
        final eventId = await _calendarService.syncHabitToCalendar(habit);
        // Nota: calendarEventId do hábito deve ser salvo no ObjectiveModel, não nas tarefas individuais
        // Isso pode ser feito quando o hábito é criado/atualizado, não aqui
      }
    } catch (e) {
      throw Exception('Erro ao gerar tarefas recorrentes: $e');
    }
  }

  /// Gera lista de tarefas baseado na frequência (quantidade limitada)
  List<TaskModel> _generateTasksForFrequency(ObjectiveModel habit, {int maxTasks = 20}) {
    final now = DateTime.now();
    final tasks = <TaskModel>[];
    int tasksGenerated = 0;

    switch (habit.frequencyType!) {
      case FrequencyType.daily:
        // Gera tarefas diárias até atingir o máximo
        for (int i = 0; tasksGenerated < maxTasks; i++) {
          final date = now.add(Duration(days: i));
          tasks.add(_createTaskForDate(habit, date));
          tasksGenerated++;
        }
        break;

      case FrequencyType.everyXDays:
        // Gera tarefas espaçadas por X dias até atingir o máximo
        final interval = habit.frequencyValue ?? 2;
        for (int i = 0; tasksGenerated < maxTasks; i += interval) {
          final date = now.add(Duration(days: i));
          tasks.add(_createTaskForDate(habit, date));
          tasksGenerated++;
        }
        break;

      case FrequencyType.weekly:
        // Gera tarefas semanais até atingir o máximo
        if (habit.weekDays == null || habit.weekDays!.isEmpty) {
          throw Exception('Dias da semana não definidos');
        }

        int week = 0;
        while (tasksGenerated < maxTasks) {
          for (final weekDay in habit.weekDays!) {
            if (tasksGenerated >= maxTasks) break;
            
            final daysUntil = _daysUntilWeekDay(now, weekDay, week);
            final date = now.add(Duration(days: daysUntil));
            tasks.add(_createTaskForDate(habit, date));
            tasksGenerated++;
          }
          week++;
        }
        break;
    }

    return tasks;
  }

  /// Gera tarefas adicionais para um hábito (incremento)
  Future<void> generateAdditionalTasksForHabit(ObjectiveModel habit, {int count = 5}) async {
    try {
      // Busca última tarefa criada para continuar a partir dela
      final lastTask = await _getLastGeneratedTask(habit.userId, habit.id);
      
      final tasks = <TaskModel>[];
      final startDate = lastTask != null 
          ? lastTask.createdAt.add(const Duration(days: 1))
          : DateTime.now();

      int tasksGenerated = 0;

      switch (habit.frequencyType!) {
        case FrequencyType.daily:
          for (int i = 0; tasksGenerated < count; i++) {
            final date = startDate.add(Duration(days: i));
            tasks.add(_createTaskForDate(habit, date));
            tasksGenerated++;
          }
          break;

        case FrequencyType.everyXDays:
          final interval = habit.frequencyValue ?? 2;
          for (int i = 0; tasksGenerated < count; i += interval) {
            final date = startDate.add(Duration(days: i));
            tasks.add(_createTaskForDate(habit, date));
            tasksGenerated++;
          }
          break;

        case FrequencyType.weekly:
          if (habit.weekDays == null || habit.weekDays!.isEmpty) {
            throw Exception('Dias da semana não definidos');
          }

          int week = 0;
          while (tasksGenerated < count) {
            for (final weekDay in habit.weekDays!) {
              if (tasksGenerated >= count) break;
              
              final daysUntil = _daysUntilWeekDay(startDate, weekDay, week);
              final date = startDate.add(Duration(days: daysUntil));
              tasks.add(_createTaskForDate(habit, date));
              tasksGenerated++;
            }
            week++;
          }
          break;
      }

      // Salva as novas tarefas
      for (final task in tasks) {
        await _taskRepository.createTask(task);
        
        // FASE 1: Agenda notificação para cada tarefa gerada (se tiver horário)
        if (task.time != null) {
          await _notificationService.scheduleTaskNotification(task);
        }
      }
    } catch (e) {
      throw Exception('Erro ao gerar tarefas adicionais: $e');
    }
  }

  /// Busca a última tarefa gerada para um hábito
  Future<TaskModel?> _getLastGeneratedTask(String userId, String objectiveId) async {
    try {
      final tasks = await _taskRepository.getTasks(userId);
      final habitTasks = tasks
          .where((task) => task.linkedObjectiveId == objectiveId)
          .toList();

      if (habitTasks.isEmpty) return null;

      // Ordena por data de criação e retorna a mais recente
      habitTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return habitTasks.first;
    } catch (e) {
      return null;
    }
  }

  /// Verifica se precisa gerar mais tarefas para um hábito
  Future<bool> needsMoreTasks(String userId, String objectiveId) async {
    try {
      final pendingCount = await _taskRepository.countPendingTasksByObjectiveId(userId, objectiveId);
      
      // Se tem menos de 5 tarefas pendentes, precisa gerar mais
      return pendingCount < 5;
    } catch (e) {
      return false;
    }
  }

  /// Cria uma tarefa para uma data específica
  TaskModel _createTaskForDate(ObjectiveModel habit, DateTime date) {
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    
    final task = TaskModel.create(
      userId: habit.userId,
      title: '${habit.title} ($dateStr)',
      description: habit.description,
      rank: TaskRank.d, // Tarefas de hábito são Rank D (normais)
      statType: StatType.spirit, // Hábitos afetam Spirit por padrão
      linkedObjectiveId: habit.id, // Linkada ao hábito
    );
    
    // Adiciona ID único e herda horário do hábito (se tiver)
    return task.copyWith(
      id: const Uuid().v4(),
      createdAt: date,
      time: habit.time, // Herda o horário do hábito
    );
  }

  /// Calcula quantos dias faltam até um dia da semana específico
  /// weekDay: 1=Domingo, 2=Segunda, ..., 7=Sábado
  /// week: 0=esta semana, 1=próxima semana
  int _daysUntilWeekDay(DateTime from, int targetWeekDay, int week) {
    final currentWeekDay = from.weekday == 7 ? 1 : from.weekday + 1;
    int daysToAdd = targetWeekDay - currentWeekDay;
    
    if (daysToAdd < 0) {
      daysToAdd += 7;
    }
    
    return daysToAdd + (week * 7);
  }

  /// Atualiza tarefas recorrentes de um hábito
  /// Deve ser chamado periodicamente (ex: todo dia às 00:00)
  Future<void> updateRecurringTasks(ObjectiveModel habit) async {
    // TODO: Implementar lógica de atualização
    // - Verificar tarefas antigas completadas/expiradas
    // - Gerar novas tarefas se necessário
    // - Manter sempre X dias de tarefas futuras
  }
}
