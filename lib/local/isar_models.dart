import 'package:isar/isar.dart';
import '../core/utils/constants.dart';
import '../models/task_model.dart';
import '../models/objective_model.dart';
import '../models/shadow_model.dart';
import '../models/trophy_model.dart';

part 'isar_models.g.dart';

/// Modelo Isar para Tarefa (armazenamento local)
@collection
class IsarTask {
  Id id = Isar.autoIncrement;

  @Index()
  late String taskId; // ID da tarefa no Firestore
  late String userId;
  late String title;
  String? description;
  late String rank; // TaskRank como string
  late String statType; // StatType como string
  List<String> tags = [];
  late int xpReward;
  late bool isCompleted;
  DateTime? completedAt;
  String? linkedObjectiveId;
  late DateTime createdAt;
  String? time;
  String? calendarEventId;

  // Campos para sincronização
  late bool isSynced; // Se foi sincronizado com Firestore
  DateTime? lastSyncedAt;
  late bool
  needsSync; // Se precisa ser sincronizado (criado/atualizado offline)

  IsarTask(); // Construtor sem nome obrigatório para Isar

  /// Converte TaskModel para IsarTask
  factory IsarTask.fromTaskModel(
    TaskModel task, {
    bool isSynced = true,
    bool needsSync = false,
  }) {
    return IsarTask()
      ..taskId = task.id
      ..userId = task.userId
      ..title = task.title
      ..description = task.description
      ..rank = task.rank.name
      ..statType = task.statType.name
      ..tags = List<String>.from(task.tags)
      ..xpReward = task.xpReward
      ..isCompleted = task.isCompleted
      ..completedAt = task.completedAt
      ..linkedObjectiveId = task.linkedObjectiveId
      ..createdAt = task.createdAt
      ..time = task.time
      ..calendarEventId = task.calendarEventId
      ..isSynced = isSynced
      ..lastSyncedAt = isSynced ? DateTime.now() : null
      ..needsSync = needsSync;
  }

  /// Converte IsarTask para TaskModel
  TaskModel toTaskModel() {
    return TaskModel(
      id: taskId,
      userId: userId,
      title: title,
      description: description,
      rank: TaskRank.values.firstWhere((e) => e.name == rank),
      statType: StatType.values.firstWhere((e) => e.name == statType),
      tags: tags,
      xpReward: xpReward,
      isCompleted: isCompleted,
      completedAt: completedAt,
      linkedObjectiveId: linkedObjectiveId,
      createdAt: createdAt,
      time: time,
      calendarEventId: calendarEventId,
    );
  }
}

/// Modelo Isar para Objetivo (armazenamento local)
@collection
class IsarObjective {
  Id id = Isar.autoIncrement;

  @Index()
  late String objectiveId; // ID do objetivo no Firestore
  late String userId;
  late String title;
  String? description;
  late String rank; // ObjectiveRank como string
  String? statType; // StatType como string (pode ser null)
  late int progress;
  late int streak; // Sequência de dias consecutivos (apenas para B)
  DateTime? deadline;
  late DateTime createdAt;
  DateTime? completedAt;
  String? frequencyType; // FrequencyType como string (para hábitos)
  int? frequencyValue;
  List<int>? weekDays; // Para frequência semanal: [1=Dom, 2=Seg, ..., 7=Sab]
  String? time;
  String? calendarEventId;

  // Campos para sincronização
  late bool isSynced;
  DateTime? lastSyncedAt;
  late bool needsSync;

  IsarObjective(); // Construtor sem nome obrigatório para Isar

  /// Converte ObjectiveModel para IsarObjective
  factory IsarObjective.fromObjectiveModel(
    ObjectiveModel objective, {
    bool isSynced = true,
    bool needsSync = false,
  }) {
    return IsarObjective()
      ..objectiveId = objective.id
      ..userId = objective.userId
      ..title = objective.title
      ..description = objective.description
      ..rank = objective.rank.name
      ..statType = objective.statType?.name
      ..progress = objective.progress
      ..streak = objective.streak
      ..deadline = objective.deadline
      ..createdAt = objective.createdAt
      ..completedAt = objective.completedAt
      ..frequencyType = objective.frequencyType?.name
      ..frequencyValue = objective.frequencyValue
      ..weekDays = objective.weekDays != null
          ? List<int>.from(objective.weekDays!)
          : null
      ..time = objective.time
      ..calendarEventId = objective.calendarEventId
      ..isSynced = isSynced
      ..lastSyncedAt = isSynced ? DateTime.now() : null
      ..needsSync = needsSync;
  }

  /// Converte IsarObjective para ObjectiveModel
  ObjectiveModel toObjectiveModel() {
    return ObjectiveModel(
      id: objectiveId,
      userId: userId,
      title: title,
      description: description,
      rank: ObjectiveRank.values.firstWhere((e) => e.name == rank),
      statType: statType != null
          ? StatType.values.firstWhere((e) => e.name == statType)
          : null,
      progress: progress,
      streak: streak,
      deadline: deadline,
      createdAt: createdAt,
      completedAt: completedAt,
      frequencyType: frequencyType != null
          ? FrequencyType.values.firstWhere((e) => e.name == frequencyType)
          : null,
      frequencyValue: frequencyValue,
      weekDays: weekDays,
      time: time,
      calendarEventId: calendarEventId,
    );
  }
}

/// Modelo Isar para Sombra (armazenamento local)
@collection
class IsarShadow {
  Id id = Isar.autoIncrement;

  @Index()
  late String shadowId; // ID da sombra no Firestore
  late String userId;
  late String name;
  late String type; // 'task' ou 'objective'
  String? taskRank; // TaskRank como string (A, C, D, E se for de tarefa)
  String? objectiveRank; // ObjectiveRank como string (S se for de objetivo)
  String? statType; // StatType como string (opcional para objetivos)
  late int xpBonus; // % de bônus de XP
  late int efficiencyBonus; // % de eficiência
  late DateTime extractedAt;
  late bool isEquipped;
  List<String> tags = []; // Tags para matching de buffs

  // Campos para sincronização
  late bool isSynced;
  DateTime? lastSyncedAt;
  late bool needsSync;

  IsarShadow(); // Construtor sem nome obrigatório para Isar

  /// Converte ShadowModel para IsarShadow
  factory IsarShadow.fromShadowModel(
    ShadowModel shadow, {
    bool isSynced = true,
    bool needsSync = false,
  }) {
    return IsarShadow()
      ..shadowId = shadow.id
      ..userId = shadow.userId
      ..name = shadow.name
      ..type = shadow.type
      ..taskRank = shadow.taskRank?.name
      ..objectiveRank = shadow.objectiveRank?.name
      ..statType = shadow.statType?.name
      ..xpBonus = shadow.xpBonus
      ..efficiencyBonus = shadow.efficiencyBonus
      ..extractedAt = shadow.extractedAt
      ..isEquipped = shadow.isEquipped
      ..tags = List<String>.from(shadow.tags)
      ..isSynced = isSynced
      ..lastSyncedAt = isSynced ? DateTime.now() : null
      ..needsSync = needsSync;
  }

  /// Converte IsarShadow para ShadowModel
  ShadowModel toShadowModel() {
    return ShadowModel(
      id: shadowId,
      userId: userId,
      name: name,
      type: type,
      taskRank: taskRank != null
          ? TaskRank.values.firstWhere((e) => e.name == taskRank)
          : null,
      objectiveRank: objectiveRank != null
          ? ObjectiveRank.values.firstWhere((e) => e.name == objectiveRank)
          : null,
      statType: statType != null
          ? StatType.values.firstWhere((e) => e.name == statType)
          : null,
      xpBonus: xpBonus,
      efficiencyBonus: efficiencyBonus,
      extractedAt: extractedAt,
      isEquipped: isEquipped,
      tags: tags,
    );
  }
}

/// Modelo Isar para Troféu (armazenamento local)
@collection
class IsarTrophy {
  Id id = Isar.autoIncrement;

  @Index()
  late String trophyId; // ID do troféu no Firestore
  late String userId;
  late String objectiveId;
  late String title; // Título do objetivo S original
  late String description; // Descrição do objetivo
  String? statType; // StatType como string (opcional)
  late DateTime completedAt;
  late int daysToComplete; // Tempo levado em dias
  late bool displayOnDashboard; // Se exibe no dashboard (máx 3)
  late int totalTasksCompleted; // Quantas tarefas foram feitas

  // Campos para sincronização
  late bool isSynced;
  DateTime? lastSyncedAt;
  late bool needsSync;

  IsarTrophy(); // Construtor sem nome obrigatório para Isar

  /// Converte TrophyModel para IsarTrophy
  factory IsarTrophy.fromTrophyModel(
    TrophyModel trophy, {
    bool isSynced = true,
    bool needsSync = false,
  }) {
    return IsarTrophy()
      ..trophyId = trophy.id
      ..userId = trophy.userId
      ..objectiveId = trophy.objectiveId
      ..title = trophy.title
      ..description = trophy.description
      ..statType = trophy.statType?.name
      ..completedAt = trophy.completedAt
      ..daysToComplete = trophy.daysToComplete
      ..displayOnDashboard = trophy.displayOnDashboard
      ..totalTasksCompleted = trophy.totalTasksCompleted
      ..isSynced = isSynced
      ..lastSyncedAt = isSynced ? DateTime.now() : null
      ..needsSync = needsSync;
  }

  /// Converte IsarTrophy para TrophyModel
  TrophyModel toTrophyModel() {
    return TrophyModel(
      id: trophyId,
      userId: userId,
      objectiveId: objectiveId,
      title: title,
      description: description,
      statType: statType != null
          ? StatType.values.firstWhere((e) => e.name == statType)
          : null,
      completedAt: completedAt,
      daysToComplete: daysToComplete,
      displayOnDashboard: displayOnDashboard,
      totalTasksCompleted: totalTasksCompleted,
    );
  }
}
