import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_quest_model.dart';
import '../repositories/daily_quest_repository.dart';
import 'penalty_service.dart';
import 'notification_service.dart';

/// Service para gerenciar lógica de Daily Quests
class DailyQuestService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DailyQuestRepository _questRepository = DailyQuestRepository();
  final PenaltyService _penaltyService = PenaltyService();
  final NotificationService _notificationService = NotificationService();

  /// Busca todas as daily quests do usuário
  Future<List<DailyQuestModel>> getDailyQuests() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    return await _questRepository.getDailyQuests(user.uid);
  }

  /// Cria uma nova daily quest
  Future<void> createDailyQuest(DailyQuestModel quest) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    // Valida máximo de 5 daily quests
    final currentQuests = await _questRepository.getDailyQuests(user.uid);
    if (currentQuests.length >= 5) {
      throw Exception('Máximo de 5 Daily Quests atingido');
    }

    await _questRepository.createDailyQuest(quest);
  }

  /// Completa uma daily quest
  Future<void> completeDailyQuest(DailyQuestModel quest) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final now = DateTime.now();
    
    // Verifica se já completou hoje
    if (quest.isCompleted && _isSameDay(quest.lastCompletedAt, now)) {
      throw Exception('Quest já completada hoje');
    }

    // Verifica se mantém o streak (completou ontem)
    final yesterday = now.subtract(const Duration(days: 1));
    final maintainsStreak = quest.lastCompletedAt != null && 
                            _isSameDay(quest.lastCompletedAt, yesterday);

    // Atualiza streak
    final newStreak = maintainsStreak ? quest.streak + 1 : 1;

    // Atualiza quest
    final updatedQuest = quest.copyWith(
      isCompleted: true,
      lastCompletedAt: now,
      streak: newStreak,
    );

    await _questRepository.updateDailyQuest(user.uid, updatedQuest);
  }

  /// Desmarca uma daily quest (se completou hoje)
  Future<void> uncompleteDailyQuest(DailyQuestModel quest) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final now = DateTime.now();
    
    // Só permite desmarcar se foi completada hoje
    if (!quest.isCompleted || !_isSameDay(quest.lastCompletedAt, now)) {
      throw Exception('Não é possível desmarcar esta quest');
    }

    // Reverte o streak (decrementa)
    final newStreak = quest.streak > 0 ? quest.streak - 1 : 0;

    final updatedQuest = quest.copyWith(
      isCompleted: false,
      streak: newStreak,
    );

    await _questRepository.updateDailyQuest(user.uid, updatedQuest);
  }

  /// Verifica se precisa resetar daily quests (deve rodar diariamente)
  Future<void> checkAndResetDailyQuests() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final quests = await _questRepository.getDailyQuests(user.uid);
      final now = DateTime.now();

      for (final quest in quests) {
        // Se a última reset date foi ontem ou antes, precisa resetar
        if (!_isSameDay(quest.lastResetDate, now)) {
          // Verifica se quebrou o streak (não completou ontem)
          final yesterday = now.subtract(const Duration(days: 1));
          final completedYesterday = quest.lastCompletedAt != null && 
                                     _isSameDay(quest.lastCompletedAt, yesterday);

          // Se não completou ontem e tinha streak, quebrou o streak
          if (!completedYesterday && quest.streak > 0 && quest.isCompleted) {
            // Streak quebrado! Entra na Penalty Zone
            await _penaltyService.enterPenaltyZone(user.uid);
          }

          // Reseta a quest para hoje
          final resetQuest = quest.copyWith(
            isCompleted: false,
            lastResetDate: now,
            // Mantém o streak se completou ontem
            streak: completedYesterday ? quest.streak : 0,
          );

          await _questRepository.updateDailyQuest(user.uid, resetQuest);
        }
      }
      
      // FASE 1: Agenda notificação para meia-noite (próximo reset)
      await _notificationService.scheduleDailyQuestNotification();
    } catch (e) {
      print('Erro ao resetar daily quests: $e');
    }
  }

  /// Verifica se todas as daily quests foram completadas hoje
  Future<bool> allQuestsCompletedToday() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final quests = await _questRepository.getDailyQuests(user.uid);
      if (quests.isEmpty) return false;

      final now = DateTime.now();
      
      // Todas devem estar completadas E ter sido completadas hoje
      return quests.every((quest) => 
        quest.isCompleted && 
        quest.lastCompletedAt != null && 
        _isSameDay(quest.lastCompletedAt, now)
      );
    } catch (e) {
      return false;
    }
  }

  /// Deleta uma daily quest
  Future<void> deleteDailyQuest(String questId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _questRepository.deleteDailyQuest(user.uid, questId);
  }

  /// Verifica se duas datas são do mesmo dia
  bool _isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}
