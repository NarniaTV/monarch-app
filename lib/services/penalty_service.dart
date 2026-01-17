import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/constants.dart';
import '../models/penalty_state_model.dart';
import '../repositories/penalty_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/objective_repository.dart';
import 'notification_service.dart';

/// Service para gerenciar Penalty Zone 2.0
class PenaltyService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PenaltyRepository _penaltyRepository = PenaltyRepository();
  final UserRepository _userRepository = UserRepository();
  final ObjectiveRepository _objectiveRepository = ObjectiveRepository();
  final NotificationService _notificationService = NotificationService();

  /// Entra na Penalty Zone (quando streak de daily quest quebra)
  Future<void> enterPenaltyZone(String userId) async {
    try {
      final now = DateTime.now();
      
      final penaltyState = PenaltyStateModel(
        userId: userId,
        isInPenaltyZone: true,
        penaltyStartedAt: now,
        daysRemaining: 3,
        quitationProgress: 0,
      );

      await _penaltyRepository.updatePenaltyState(userId, penaltyState);
      
      // FASE 1: Agenda notificação de Penalty Zone
      await _notificationService.schedulePenaltyZoneNotification();
    } catch (e) {
      throw Exception('Erro ao entrar na Penalty Zone: $e');
    }
  }

  /// Atualiza progresso de quitação (quando completa todas as daily quests)
  Future<void> updateQuitationProgress(String userId) async {
    try {
      final state = await _penaltyRepository.getPenaltyState(userId);
      
      if (!state.isInPenaltyZone) return;

      final now = DateTime.now();
      
      // Verifica se já progrediu hoje
      if (state.lastQuitationDate != null && _isSameDay(state.lastQuitationDate, now)) {
        return; // Já progrediu hoje
      }

      final newProgress = state.quitationProgress + 1;
      final newDaysRemaining = state.daysRemaining - 1;

      // Se completou 3 dias, sai da Penalty Zone
      if (newProgress >= 3) {
        await exitPenaltyZone(userId);
      } else {
        // Atualiza progresso
        final updatedState = state.copyWith(
          quitationProgress: newProgress,
          daysRemaining: newDaysRemaining,
          lastQuitationDate: now,
        );
        
        await _penaltyRepository.updatePenaltyState(userId, updatedState);
      }
    } catch (e) {
      throw Exception('Erro ao atualizar progresso de quitação: $e');
    }
  }

  /// Sai da Penalty Zone (quitação completa)
  Future<void> exitPenaltyZone(String userId) async {
    try {
      // Reseta estado da penalty zone
      await _penaltyRepository.resetPenaltyState(userId);

      // Dá bônus de +200 XP por sair
      final profile = await _userRepository.getUser(userId);
      if (profile != null) {
        final newXp = profile.currentXp + 200;
        final updatedProfile = profile.copyWith(currentXp: newXp);
        await _userRepository.updateUser(updatedProfile);
      }
    } catch (e) {
      throw Exception('Erro ao sair da Penalty Zone: $e');
    }
  }

  /// Desiste (reseta objetivos S e penalidades)
  Future<void> giveUp(String userId) async {
    try {
      // Busca objetivos S ativos
      final objectives = await _objectiveRepository.getActiveObjectives(userId);
      final objectivesS = objectives.where((obj) => obj.rank == ObjectiveRank.s).toList();

      // Deleta todos os objetivos S
      for (final objective in objectivesS) {
        await _objectiveRepository.deleteObjective(userId, objective.id);
      }

      // Reduz level em 50%
      final profile = await _userRepository.getUser(userId);
      if (profile != null) {
        final newLevel = (profile.level * 0.5).ceil();
        final updatedProfile = profile.copyWith(level: newLevel, currentXp: 0);
        await _userRepository.updateUser(updatedProfile);
      }

      // Reseta Penalty Zone
      await _penaltyRepository.resetPenaltyState(userId);
    } catch (e) {
      throw Exception('Erro ao desistir: $e');
    }
  }

  /// Verifica se duas datas são do mesmo dia
  bool _isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}
