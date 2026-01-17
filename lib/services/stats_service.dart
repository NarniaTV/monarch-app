import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/constants.dart';
import '../repositories/user_repository.dart';

/// Informações sobre level up
class LevelUpInfo {
  final int oldLevel;
  final int newLevel;
  final int xpGained;

  LevelUpInfo({
    required this.oldLevel,
    required this.newLevel,
    required this.xpGained,
  });
}

/// Service para gerenciar stats (Power/Mind/Spirit) e XP/Level
class StatsService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository = UserRepository();

  /// Atualiza stats ao completar uma tarefa
  /// 
  /// [statType] - Qual stat aumentar (Power, Mind, Spirit)
  /// [taskRank] - Rank da tarefa (S, A, B, C, D, E)
  /// [isPenaltyZoneActive] - Se está na Penalty Zone (XP reduzido em 50%)
  /// 
  /// Retorna [LevelUpInfo?] se houve level up, null caso contrário
  Future<LevelUpInfo?> updateStatsOnTaskComplete({
    required StatType statType,
    required TaskRank taskRank,
    bool isPenaltyZoneActive = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Busca perfil atual
      final profile = await _userRepository.getUser(user.uid);
      if (profile == null) {
        throw Exception('Perfil não encontrado');
      }

      // Calcula XP baseado no rank
      int xpGained = _calculateXpForRank(taskRank);
      
      // Se está na Penalty Zone, XP é reduzido em 50%
      if (isPenaltyZoneActive) {
        xpGained = (xpGained * 0.5).round();
      }

      // Incrementa stat específico (+1)
      int newPower = profile.power;
      int newMind = profile.mind;
      int newSpirit = profile.spirit;

      switch (statType) {
        case StatType.power:
          newPower++;
          break;
        case StatType.mind:
          newMind++;
          break;
        case StatType.spirit:
          newSpirit++;
          break;
      }

      // Calcula novo XP e verifica level up
      final oldLevel = profile.level;
      final newXp = profile.currentXp + xpGained;
      final newLevel = _calculateLevel(newXp);

      // Atualiza perfil no Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'power': newPower,
        'mind': newMind,
        'spirit': newSpirit,
        'currentXp': newXp,
        'level': newLevel,
      });

      // Retorna info de level up se subiu de level
      if (newLevel > oldLevel) {
        return LevelUpInfo(
          oldLevel: oldLevel,
          newLevel: newLevel,
          xpGained: xpGained,
        );
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao atualizar stats: $e');
    }
  }

  /// Calcula XP ganho baseado no rank da tarefa
  int _calculateXpForRank(TaskRank rank) {
    switch (rank) {
      case TaskRank.s:
        return XpValues.rankS; // 0 (objetivos S não dão XP direto)
      case TaskRank.a:
        return XpValues.rankA; // 0 (metas não dão XP direto)
      case TaskRank.b:
        return XpValues.rankB; // 0 (metas secundárias não dão XP direto)
      case TaskRank.c:
        return XpValues.rankC; // 100 (tarefas importantes)
      case TaskRank.d:
        return XpValues.rankD; // 50 (tarefas médias)
      case TaskRank.e:
        return XpValues.rankE; // 25 (tarefas simples)
    }
  }

  /// Calcula nível baseado no XP total
  /// Fórmula: XP necessário para level N = 100 * (N ^ 1.5)
  int _calculateLevel(int totalXp) {
    int level = 1;
    while (XpValues.xpForLevel(level + 1) <= totalXp) {
      level++;
    }
    return level;
  }

  /// Calcula XP necessário para o próximo level
  int calculateXpForNextLevel(int currentLevel) {
    return XpValues.xpForLevel(currentLevel + 1);
  }

  /// Calcula progresso percentual para o próximo level
  /// Retorna valor entre 0.0 e 1.0
  double calculateLevelProgress(int currentXp, int currentLevel) {
    final xpForCurrentLevel = XpValues.xpForLevel(currentLevel);
    final xpForNextLevel = XpValues.xpForLevel(currentLevel + 1);
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    final xpProgress = currentXp - xpForCurrentLevel;
    
    if (xpNeeded <= 0) return 1.0;
    
    return (xpProgress / xpNeeded).clamp(0.0, 1.0);
  }

  /// Calcula XP dentro do level atual (de 0 até o necessário para upar)
  /// Retorna o progresso dentro do level atual
  int calculateXpInCurrentLevel(int currentXp, int currentLevel) {
    final xpForCurrentLevel = XpValues.xpForLevel(currentLevel);
    return currentXp - xpForCurrentLevel;
  }

  /// Calcula quanto XP é necessário dentro do level atual para upar
  /// Retorna a quantidade de XP necessária dentro do level
  int calculateXpNeededForLevel(int currentLevel) {
    final xpForCurrentLevel = XpValues.xpForLevel(currentLevel);
    final xpForNextLevel = XpValues.xpForLevel(currentLevel + 1);
    return xpForNextLevel - xpForCurrentLevel;
  }

  /// Incrementa stat específico manualmente (para casos especiais)
  Future<void> incrementStat({
    required StatType statType,
    int amount = 1,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final profile = await _userRepository.getUser(user.uid);
      if (profile == null) {
        throw Exception('Perfil não encontrado');
      }

      Map<String, dynamic> updateData = {};

      switch (statType) {
        case StatType.power:
          updateData['power'] = profile.power + amount;
          break;
        case StatType.mind:
          updateData['mind'] = profile.mind + amount;
          break;
        case StatType.spirit:
          updateData['spirit'] = profile.spirit + amount;
          break;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);
    } catch (e) {
      throw Exception('Erro ao incrementar stat: $e');
    }
  }

  /// Adiciona XP manualmente (para casos especiais, como bônus)
  /// 
  /// Retorna [LevelUpInfo?] se houve level up, null caso contrário
  Future<LevelUpInfo?> addXp(int xpAmount) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final profile = await _userRepository.getUser(user.uid);
      if (profile == null) {
        throw Exception('Perfil não encontrado');
      }

      final oldLevel = profile.level;
      final newXp = profile.currentXp + xpAmount;
      final newLevel = _calculateLevel(newXp);

      await _firestore.collection('users').doc(user.uid).update({
        'currentXp': newXp,
        'level': newLevel,
      });

      // Retorna info de level up se subiu de level
      if (newLevel > oldLevel) {
        return LevelUpInfo(
          oldLevel: oldLevel,
          newLevel: newLevel,
          xpGained: xpAmount,
        );
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao adicionar XP: $e');
    }
  }

  /// Reduz nível em 50% (usado ao desistir na Penalty Zone)
  Future<void> reduceLevelBy50Percent() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final profile = await _userRepository.getUser(user.uid);
      if (profile == null) {
        throw Exception('Perfil não encontrado');
      }

      final newLevel = (profile.level * 0.5).round().clamp(1, 999);
      final xpForNewLevel = XpValues.xpForLevel(newLevel);

      await _firestore.collection('users').doc(user.uid).update({
        'level': newLevel,
        'currentXp': xpForNewLevel, // Ajusta XP para o início do novo level
      });
    } catch (e) {
      throw Exception('Erro ao reduzir level: $e');
    }
  }
}
