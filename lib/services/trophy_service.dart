import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/constants.dart';
import '../models/trophy_model.dart';
import '../models/objective_model.dart';
import '../repositories/trophy_repository.dart';
import '../repositories/task_repository.dart';
import 'sync_service.dart';

/// Service para gerenciar lógica de negócio de Troféus
class TrophyService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TrophyRepository _trophyRepository = TrophyRepository();
  final TaskRepository _taskRepository = TaskRepository();
  final SyncService _syncService = SyncService();

  /// Cria um troféu ao completar um objetivo S
  Future<TrophyModel> createTrophyFromObjective(ObjectiveModel objective) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Verifica se já existe troféu para este objetivo
    final exists = await _trophyRepository.trophyExistsForObjective(
      user.uid,
      objective.id,
    );

    if (exists) {
      throw Exception('Troféu já existe para este objetivo');
    }

    try {
      // Calcula dias para completar
      final now = DateTime.now();
      final daysToComplete = now.difference(objective.createdAt).inDays;

      // Conta quantas tarefas foram completadas (vinculadas a este objetivo)
      final tasks = await _taskRepository.getTasksByObjective(user.uid, objective.id);
      final completedTasks = tasks.where((t) => t.isCompleted).length;

      // Calcula stat predominante baseado nas tarefas
      StatType? predominantStat;
      if (tasks.isNotEmpty) {
        final statCounts = <StatType, int>{};
        for (final task in tasks) {
          statCounts[task.statType] = (statCounts[task.statType] ?? 0) + 1;
        }
        // Pega o stat com mais ocorrências
        predominantStat = statCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // Cria troféu
      final uuid = const Uuid();
      final trophy = TrophyModel(
        id: uuid.v4(), // ID único para offline-first
        userId: user.uid,
        objectiveId: objective.id,
        title: objective.title,
        description: objective.description ?? '',
        statType: predominantStat,
        completedAt: now,
        daysToComplete: daysToComplete,
        displayOnDashboard: false,
        totalTasksCompleted: completedTasks,
      );

      // SEMPRE salva no Isar PRIMEIRO (fonte primária)
      await _syncService.saveTrophyLocally(trophy);

      // Se online, salva no Firestore também
      final isOnline = await _syncService.isOnline();
      if (isOnline) {
        try {
          final trophyId = await _trophyRepository.createTrophy(trophy);
          // Atualiza no Isar com ID do Firestore se diferente
          if (trophyId != trophy.id) {
            await _syncService.saveTrophyLocally(trophy.copyWith(id: trophyId));
          }
        } catch (e) {
          print('[TROPHY SERVICE] ⚠️ Erro ao criar troféu no Firestore (já salvo localmente): $e');
        }
      }

      // Retorna troféu com ID
      return trophy;
    } catch (e) {
      throw Exception('Erro ao criar troféu: $e');
    }
  }

  /// Marca/desmarca troféu para exibir no dashboard
  /// 
  /// Máximo de 3 troféus podem ser exibidos
  Future<void> toggleDisplayOnDashboard(String trophyId, bool display) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      if (display) {
        // Verifica se já existem 3 troféus marcados
        final count = await _trophyRepository.countDashboardTrophies(user.uid);
        
        if (count >= 3) {
          throw Exception('Máximo de 3 troféus no dashboard atingido');
        }
      }

      await _trophyRepository.setDisplayOnDashboard(user.uid, trophyId, display);
    } catch (e) {
      throw Exception('Erro ao atualizar exibição do troféu: $e');
    }
  }

  /// Retorna todos os troféus do usuário
  Future<List<TrophyModel>> getAllTrophies() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    return await _trophyRepository.getAllTrophies(user.uid);
  }

  /// Stream de todos os troféus
  Stream<List<TrophyModel>> watchTrophies() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    return _trophyRepository.watchTrophies(user.uid);
  }

  /// Retorna troféus marcados para dashboard (máx 3)
  Future<List<TrophyModel>> getDashboardTrophies() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    return await _trophyRepository.getDashboardTrophies(user.uid);
  }

  /// Stream de troféus do dashboard
  Stream<List<TrophyModel>> watchDashboardTrophies() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    return _trophyRepository.watchDashboardTrophies(user.uid);
  }

  /// Deleta um troféu
  Future<void> deleteTrophy(String trophyId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      await _trophyRepository.deleteTrophy(user.uid, trophyId);
    } catch (e) {
      throw Exception('Erro ao deletar troféu: $e');
    }
  }
}
