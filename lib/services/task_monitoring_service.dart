import 'package:firebase_auth/firebase_auth.dart';
import '../models/objective_model.dart';
import '../core/utils/constants.dart';
import '../repositories/objective_repository.dart';
import 'habit_service.dart';

/// Serviço para monitorar tarefas de hábitos e gerar novas automaticamente
class TaskMonitoringService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ObjectiveRepository _objectiveRepository = ObjectiveRepository();
  final HabitService _habitService = HabitService();

  /// Verifica todos os hábitos ativos e gera tarefas se necessário
  Future<void> checkAndGenerateTasksForAllHabits() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Busca todos os objetivos ativos do usuário
      final objectives = await _objectiveRepository.getActiveObjectives(user.uid);
      
      // Filtra apenas os hábitos (Rank B)
      final habits = objectives.where((obj) => obj.rank == ObjectiveRank.b).toList();

      // Verifica cada hábito
      for (final habit in habits) {
        await _checkAndGenerateTasksForHabit(habit);
      }
    } catch (e) {
      // Log silencioso - não precisa alertar o usuário
      print('Erro ao verificar hábitos: $e');
    }
  }

  /// Verifica um hábito específico e gera tarefas se necessário
  Future<void> _checkAndGenerateTasksForHabit(ObjectiveModel habit) async {
    try {
      // Verifica se precisa gerar mais tarefas
      final needsMore = await _habitService.needsMoreTasks(habit.userId, habit.id);
      
      if (needsMore) {
        // Gera 5 tarefas adicionais
        await _habitService.generateAdditionalTasksForHabit(habit, count: 5);
        print('✅ Geradas 5 tarefas adicionais para "${habit.title}"');
      }
    } catch (e) {
      print('Erro ao gerar tarefas para "${habit.title}": $e');
    }
  }

  /// Verifica e gera tarefas com base na data atual
  /// Útil para ser chamado diariamente ou ao abrir o app
  Future<void> dailyCheck() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      // Busca objetivos ativos
      final objectives = await _objectiveRepository.getActiveObjectives(user.uid);
      final habits = objectives.where((obj) => obj.rank == ObjectiveRank.b).toList();

      for (final habit in habits) {
        // Verifica se o hábito precisa de mais tarefas
        final needsMore = await _habitService.needsMoreTasks(habit.userId, habit.id);
        
        if (needsMore) {
          await _habitService.generateAdditionalTasksForHabit(habit, count: 5);
          print('📅 [${today.day}/${today.month}] Tarefas geradas para "${habit.title}"');
        }
      }
    } catch (e) {
      print('Erro no daily check: $e');
    }
  }

  /// Agenda verificação periódica (pode ser chamado no init do app)
  /// Nota: Para produção, considere usar workmanager ou similar
  Future<void> schedulePeriodicCheck() async {
    // Por ora, apenas executa a verificação imediata
    await checkAndGenerateTasksForAllHabits();
  }
}
