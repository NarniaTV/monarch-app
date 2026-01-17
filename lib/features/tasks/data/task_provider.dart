import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/task_service.dart';
import '../../../services/stats_service.dart';
import '../../../models/task_model.dart';
import '../../../core/utils/constants.dart';

/// Provider para TaskService
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

/// Provider para StatsService
final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService();
});

/// Provider para stream de tarefas ativas
final activeTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return taskService.getActiveTasks();
});

/// Provider para stream de tarefas completadas
final completedTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return taskService.getCompletedTasks();
});

/// Provider para stream de tarefas por rank
final tasksByRankProvider =
    StreamProvider.family<List<TaskModel>, TaskRank>((ref, rank) {
  final taskService = ref.watch(taskServiceProvider);
  return taskService.getTasksByRank(rank);
});

/// Provider de loading para operações de tarefas
final taskLoadingProvider = StateProvider<bool>((ref) => false);
