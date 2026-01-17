import 'dart:math' as math;

/// Constantes do aplicativo SYSTEM: AWAKEN

/// Enum para ranks de tarefas e objetivos
enum TaskRank {
  s, // Rank S - Objetivos Sagrados (limitado a 3)
  a, // Rank A - Metas
  b, // Rank B - Metas Secundárias
  c, // Rank C - Tarefas Importantes
  d, // Rank D - Tarefas médias
  e, // Rank E - Tarefas simples
}

enum ObjectiveRank {
  s, // Rank S - Objetivos Sagrados (máximo 3)
  a, // Rank A - Metas Principais
  b, // Rank B - Hábitos
}

/// Frequência para hábitos (Rank B)
enum FrequencyType {
  daily,      // Todo dia
  everyXDays, // A cada X dias
  weekly,     // Dias específicos da semana
}

/// Labels para frequências
class FrequencyLabels {
  static String getLabel(FrequencyType type) {
    switch (type) {
      case FrequencyType.daily:
        return 'Todo dia';
      case FrequencyType.everyXDays:
        return 'A cada X dias';
      case FrequencyType.weekly:
        return 'Dias da semana';
    }
  }
}

/// Enum para tipos de stats
enum StatType {
  power, // Força física, ação
  mind, // Intelecto, aprendizado
  spirit, // Emoção, criatividade
}

/// Valores de XP por rank
class XpValues {
  static const int rankS = 0; // Objetivos S não dão XP direto
  static const int rankA = 0; // Metas A não dão XP direto (são metas)
  static const int rankB = 0; // Metas B não dão XP direto (metas secundárias)
  static const int rankC = 100; // Tarefas importantes
  static const int rankD = 50; // Tarefas médias
  static const int rankE = 25; // Tarefas simples

  /// Calcula XP total acumulado necessário para ATINGIR um nível
  /// Fórmula: 100 * (level ^ 1.5)
  /// Level 1 = 0 XP (começo)
  /// Level 2 = 100 XP
  /// Level 3 = 283 XP
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return (100 * math.pow(level, 1.5)).round();
  }
}

/// Limites do sistema
class SystemLimits {
  static const int maxObjectivesS = 3; // Máximo de objetivos S ativos
  static const int maxDailyQuests = 5; // Máximo de daily quests
  static const int maxEquippedShadows = 3; // Máximo de sombras equipadas
  static const int maxDisplayedTrophies = 3; // Máximo de troféus no dashboard
  static const int penaltyZoneDays = 3; // Dias para quitar Penalty Zone
}
