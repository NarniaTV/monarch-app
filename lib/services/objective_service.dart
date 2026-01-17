import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/constants.dart';
import '../models/objective_model.dart';
import '../repositories/objective_repository.dart';
import '../repositories/task_repository.dart';
import 'habit_service.dart';
import 'sync_service.dart';

/// Service para gerenciar lógica de negócio de objetivos
class ObjectiveService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ObjectiveRepository _objectiveRepository = ObjectiveRepository();
  final HabitService _habitService = HabitService();
  final SyncService _syncService = SyncService();

  /// Cria um novo objetivo
  Future<void> createObjective(ObjectiveModel objective) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final isOnline = await _syncService.isOnline();

    try {
      // Garante que o objetivo tem um ID único
      final uuid = const Uuid();
      final objectiveWithId = objective.id.isEmpty 
          ? objective.copyWith(id: uuid.v4())
          : objective;

      // SEMPRE salva no Isar PRIMEIRO (fonte primária)
      await _syncService.saveObjectiveLocally(objectiveWithId);
      
      // Se online, cria no Firestore também
      if (isOnline) {
        try {
          final createdObjective = await _objectiveRepository.createObjective(objectiveWithId);
          // Atualiza no Isar com ID do Firestore se diferente
          if (createdObjective.id != objectiveWithId.id) {
            await _syncService.saveObjectiveLocally(createdObjective);
          }
        } catch (e) {
          print('[OBJECTIVE SERVICE] ⚠️ Erro ao criar no Firestore (já salvo localmente): $e');
        }
      }
      
      // Se for hábito (Rank B), gera tarefas recorrentes
      if (objectiveWithId.rank == ObjectiveRank.b) {
        try {
          await _habitService.generateRecurringTasksForHabit(objectiveWithId);
        } catch (e) {
          print('[OBJECTIVE SERVICE] ⚠️ Erro ao gerar tarefas recorrentes: $e');
        }
      }
    } catch (e) {
      print('[OBJECTIVE SERVICE] ❌ Erro ao criar objetivo: $e');
      throw Exception('Erro ao criar objetivo: $e');
    }
  }

  /// Atualiza um objetivo
  Future<void> updateObjective(ObjectiveModel objective) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final isOnline = await _syncService.isOnline();

    try {
      // SEMPRE salva no Isar PRIMEIRO (fonte primária)
      await _syncService.saveObjectiveLocally(objective);
      
      // Se online, atualiza no Firestore também
      if (isOnline) {
        try {
          await _objectiveRepository.updateObjective(objective);
        } catch (e) {
          print('[OBJECTIVE SERVICE] ⚠️ Erro ao atualizar no Firestore (já salvo localmente): $e');
        }
      }
    } catch (e) {
      print('[OBJECTIVE SERVICE] ❌ Erro ao atualizar objetivo: $e');
      throw Exception('Erro ao atualizar objetivo: $e');
    }
  }

  /// Deleta um objetivo e suas tarefas linkadas (cascata)
  Future<void> deleteObjective(String userId, String objectiveId, {required ObjectiveRank rank}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Se for hábito (Rank B), deleta todas as tarefas linkadas
      if (rank == ObjectiveRank.b) {
        final taskRepository = TaskRepository();
        await taskRepository.deleteTasksByObjectiveId(userId, objectiveId);
      }
      
      // Deleta o objetivo
      await _objectiveRepository.deleteObjective(userId, objectiveId);
    } catch (e) {
      throw Exception('Erro ao deletar objetivo: $e');
    }
  }

  /// Busca objetivos ativos
  Future<List<ObjectiveModel>> getActiveObjectives(String userId) async {
    try {
      return await _objectiveRepository.getActiveObjectives(userId);
    } catch (e) {
      throw Exception('Erro ao buscar objetivos: $e');
    }
  }

  /// Stream de objetivos ativos
  Stream<List<ObjectiveModel>> getActiveObjectivesStream(String userId) {
    return _objectiveRepository.getActiveObjectivesStream(userId);
  }
}
