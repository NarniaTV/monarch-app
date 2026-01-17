import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';
import '../models/task_model.dart';
import '../models/objective_model.dart';
import '../models/user_profile_model.dart';
import '../local/isar_service.dart';
import '../local/isar_models.dart';
import '../repositories/task_repository.dart';
import '../repositories/objective_repository.dart';
import '../repositories/user_repository.dart';
import '../core/utils/constants.dart';

/// Modelo de dados para histórico de progresso diário
class DailyProgress {
  final DateTime date;
  final int tasksCompleted;
  final int xpGained;
  final int objectivesProgress;

  DailyProgress({
    required this.date,
    this.tasksCompleted = 0,
    this.xpGained = 0,
    this.objectivesProgress = 0,
  });
}

/// Modelo de dados para tendência de stats
class StatsTrend {
  final DateTime date;
  final int power;
  final int mind;
  final int spirit;
  final int totalXp;

  StatsTrend({
    required this.date,
    required this.power,
    required this.mind,
    required this.spirit,
    required this.totalXp,
  });
}

/// Serviço de Analytics e Insights
class AnalyticsService {
  final TaskRepository _taskRepository = TaskRepository();
  final ObjectiveRepository _objectiveRepository = ObjectiveRepository();
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Busca histórico de progresso dos últimos N dias
  Future<List<DailyProgress>> getProgressHistory(int days) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Busca todas as tarefas do usuário (do Isar primeiro)
      final allTasks = await _taskRepository.getTasks(user.uid);
      
      // Filtra apenas tarefas completadas
      final completedTasks = allTasks.where((t) => t.isCompleted && t.completedAt != null).toList();
      
      // Agrupa por data
      final Map<DateTime, List<TaskModel>> tasksByDate = {};
      for (final task in completedTasks) {
        if (task.completedAt != null) {
          final date = DateTime(
            task.completedAt!.year,
            task.completedAt!.month,
            task.completedAt!.day,
          );
          tasksByDate.putIfAbsent(date, () => []).add(task);
        }
      }
      
      // Cria lista de progresso diário para os últimos N dias
      final now = DateTime.now();
      final List<DailyProgress> history = [];
      
      for (int i = days - 1; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final tasksOnDate = tasksByDate[date] ?? [];
        
        final xpGained = tasksOnDate.fold<int>(0, (sum, task) => sum + task.xpReward);
        
        history.add(DailyProgress(
          date: date,
          tasksCompleted: tasksOnDate.length,
          xpGained: xpGained,
        ));
      }
      
      return history;
    } catch (e) {
      print('[ANALYTICS] ⚠️ Erro ao buscar histórico de progresso: $e');
      return [];
    }
  }

  /// Calcula heatmap de produtividade (calendário)
  /// Retorna mapa de data -> número de tarefas completadas
  Future<Map<DateTime, int>> getProductivityHeatmap() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final allTasks = await _taskRepository.getTasks(user.uid);
      final completedTasks = allTasks.where((t) => t.isCompleted && t.completedAt != null).toList();
      
      final Map<DateTime, int> heatmap = {};
      
      for (final task in completedTasks) {
        final completedAt = task.completedAt;
        if (completedAt != null) {
          final date = DateTime(
            completedAt.year,
            completedAt.month,
            completedAt.day,
          );
          heatmap[date] = (heatmap[date] ?? 0) + 1;
        }
      }
      
      return heatmap;
    } catch (e) {
      print('[ANALYTICS] ⚠️ Erro ao calcular heatmap: $e');
      return {};
    }
  }

  /// Busca tendência de stats ao longo do tempo
  /// Nota: Como não temos histórico de stats, vamos simular baseado em tarefas completadas
  Future<List<StatsTrend>> getStatsTrend(int days) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Busca perfil atual
      final profile = await _userRepository.getUser(user.uid);
      if (profile == null) return [];

      // Busca tarefas completadas
      final allTasks = await _taskRepository.getTasks(user.uid);
      final completedTasks = allTasks.where((t) => t.isCompleted && t.completedAt != null).toList();
      
      // Agrupa por data e calcula stats acumulados
      final Map<DateTime, Map<StatType, int>> statsByDate = {};
      
      for (final task in completedTasks) {
        if (task.completedAt != null) {
          final date = DateTime(
            task.completedAt!.year,
            task.completedAt!.month,
            task.completedAt!.day,
          );
          
          statsByDate.putIfAbsent(date, () => {
            StatType.power: 0,
            StatType.mind: 0,
            StatType.spirit: 0,
          });
          
          statsByDate[date]![task.statType] = 
              (statsByDate[date]![task.statType] ?? 0) + task.xpReward;
        }
      }
      
      // Cria tendência acumulada
      final now = DateTime.now();
      final List<StatsTrend> trend = [];
      int powerAcc = profile.power;
      int mindAcc = profile.mind;
      int spiritAcc = profile.spirit;
      int xpAcc = profile.currentXp;
      
      for (int i = days - 1; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final statsOnDate = statsByDate[date];
        
        if (statsOnDate != null) {
          powerAcc -= statsOnDate[StatType.power] ?? 0;
          mindAcc -= statsOnDate[StatType.mind] ?? 0;
          spiritAcc -= statsOnDate[StatType.spirit] ?? 0;
          xpAcc -= (statsOnDate[StatType.power] ?? 0) + 
                   (statsOnDate[StatType.mind] ?? 0) + 
                   (statsOnDate[StatType.spirit] ?? 0);
        }
        
        trend.add(StatsTrend(
          date: date,
          power: powerAcc.clamp(0, double.infinity).toInt(),
          mind: mindAcc.clamp(0, double.infinity).toInt(),
          spirit: spiritAcc.clamp(0, double.infinity).toInt(),
          totalXp: xpAcc.clamp(0, double.infinity).toInt(),
        ));
      }
      
      return trend.reversed.toList(); // Inverte para mostrar do mais antigo ao mais recente
    } catch (e) {
      print('[ANALYTICS] ⚠️ Erro ao buscar tendência de stats: $e');
      return [];
    }
  }

  /// Calcula taxa de conclusão de tarefas
  Future<double> getCompletionRate({int? days}) async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    try {
      final allTasks = await _taskRepository.getTasks(user.uid);
      
      if (allTasks.isEmpty) return 0.0;
      
      DateTime? cutoffDate;
      if (days != null) {
        cutoffDate = DateTime.now().subtract(Duration(days: days));
      }
      
      final relevantTasks = cutoffDate != null
          ? allTasks.where((t) => t.createdAt.isAfter(cutoffDate!)).toList()
          : allTasks;
      
      if (relevantTasks.isEmpty) return 0.0;
      
      final completedCount = relevantTasks.where((t) => t.isCompleted).length;
      return (completedCount / relevantTasks.length) * 100;
    } catch (e) {
      print('[ANALYTICS] ⚠️ Erro ao calcular taxa de conclusão: $e');
      return 0.0;
    }
  }

  /// Busca histórico de streaks de hábitos
  Future<Map<String, int>> getStreakHistory() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final objectives = await _objectiveRepository.getActiveObjectives(user.uid);
      
      // Filtra apenas hábitos (Rank B)
      final habits = objectives.where((o) => o.rank == ObjectiveRank.b).toList();
      
      final Map<String, int> streaks = {};
      for (final habit in habits) {
        streaks[habit.title] = habit.streak;
      }
      
      return streaks;
    } catch (e) {
      print('[ANALYTICS] ⚠️ Erro ao buscar histórico de streaks: $e');
      return {};
    }
  }

  /// Busca estatísticas gerais
  Future<Map<String, dynamic>> getGeneralStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final profile = await _userRepository.getUser(user.uid);
      final allTasks = await _taskRepository.getTasks(user.uid);
      final objectives = await _objectiveRepository.getActiveObjectives(user.uid);
      
      final completedTasks = allTasks.where((t) => t.isCompleted).toList();
      final activeTasks = allTasks.where((t) => !t.isCompleted).toList();
      
      final totalXp = completedTasks.fold<int>(0, (sum, task) => sum + task.xpReward);
      final completionRate = allTasks.isEmpty 
          ? 0.0 
          : (completedTasks.length / allTasks.length) * 100;
      
      final avgStreak = objectives
          .where((o) => o.rank == ObjectiveRank.b)
          .map((o) => o.streak)
          .fold<double>(0, (sum, streak) => sum + streak) / 
          (objectives.where((o) => o.rank == ObjectiveRank.b).length > 0
              ? objectives.where((o) => o.rank == ObjectiveRank.b).length
              : 1);
      
      return {
        'level': profile?.level ?? 1,
        'currentXp': profile?.currentXp ?? 0,
        'power': profile?.power ?? 0,
        'mind': profile?.mind ?? 0,
        'spirit': profile?.spirit ?? 0,
        'totalTasks': allTasks.length,
        'completedTasks': completedTasks.length,
        'activeTasks': activeTasks.length,
        'totalXp': totalXp,
        'completionRate': completionRate,
        'activeObjectives': objectives.length,
        'avgStreak': avgStreak.round(),
      };
    } catch (e) {
      print('[ANALYTICS] ⚠️ Erro ao buscar estatísticas gerais: $e');
      return {};
    }
  }
}
