import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/constants.dart';

/// Modelo de Sombra (extraída de tarefas Rank A ou objetivos S)
class ShadowModel {
  final String id;
  final String userId;
  final String name; // Nome da tarefa/objetivo original
  final String type; // 'task' ou 'objective'
  final TaskRank? taskRank; // A, C, D, E (se for de tarefa)
  final ObjectiveRank? objectiveRank; // S (se for de objetivo)
  final StatType? statType; // Power, Mind, Spirit (opcional para objetivos)
  final int xpBonus; // % de bônus de XP
  final int efficiencyBonus; // % de eficiência
  final bool isEquipped; // Se está equipada (máx 3)
  final DateTime extractedAt;
  final List<String> tags; // Tags para matching de buffs

  ShadowModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.taskRank,
    this.objectiveRank,
    required this.statType,
    required this.xpBonus,
    required this.efficiencyBonus,
    this.isEquipped = false,
    required this.extractedAt,
    this.tags = const [],
  });

  /// Cria sombra a partir de mapa Firestore
  factory ShadowModel.fromMap(Map<String, dynamic> map, String id) {
    return ShadowModel(
      id: id,
      userId: map['userId'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      taskRank: map['taskRank'] != null 
          ? TaskRank.values.firstWhere((e) => e.name == map['taskRank'])
          : null,
      objectiveRank: map['objectiveRank'] != null
          ? ObjectiveRank.values.firstWhere((e) => e.name == map['objectiveRank'])
          : null,
      statType: map['statType'] != null
          ? StatType.values.firstWhere((e) => e.name == map['statType'])
          : null,
      xpBonus: map['xpBonus'] as int,
      efficiencyBonus: map['efficiencyBonus'] as int,
      isEquipped: map['isEquipped'] as bool? ?? false,
      extractedAt: (map['extractedAt'] as Timestamp).toDate(),
      tags: List<String>.from(map['tags'] as List? ?? []),
    );
  }

  /// Converte para mapa Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'taskRank': taskRank?.name,
      'objectiveRank': objectiveRank?.name,
      'statType': statType?.name,
      'xpBonus': xpBonus,
      'efficiencyBonus': efficiencyBonus,
      'isEquipped': isEquipped,
      'extractedAt': Timestamp.fromDate(extractedAt),
      'tags': tags,
    };
  }

  /// Cria cópia com modificações
  ShadowModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    TaskRank? taskRank,
    ObjectiveRank? objectiveRank,
    StatType? statType,
    int? xpBonus,
    int? efficiencyBonus,
    bool? isEquipped,
    DateTime? extractedAt,
    List<String>? tags,
  }) {
    return ShadowModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      taskRank: taskRank ?? this.taskRank,
      objectiveRank: objectiveRank ?? this.objectiveRank,
      statType: statType ?? this.statType,
      xpBonus: xpBonus ?? this.xpBonus,
      efficiencyBonus: efficiencyBonus ?? this.efficiencyBonus,
      isEquipped: isEquipped ?? this.isEquipped,
      extractedAt: extractedAt ?? this.extractedAt,
      tags: tags ?? this.tags,
    );
  }

  /// Retorna nome épico da sombra
  String getEpicName() {
    if (type == 'objective' && objectiveRank == ObjectiveRank.s) {
      final statSuffix = statType != null ? ' [${statType!.name.toUpperCase()}]' : '';
      return 'ETERNAL ${name.toUpperCase()}$statSuffix';
    }
    return 'SHADOW OF ${name.toUpperCase()}';
  }

  /// Retorna cor da sombra baseada no tipo
  int getColorValue() {
    if (type == 'objective' && objectiveRank == ObjectiveRank.s) {
      return 0xFFFFD700; // Dourado para S
    }
    
    // Baseado no rank da tarefa
    if (taskRank == TaskRank.a) return 0xFF9D00FF; // Roxo para A
    if (taskRank == TaskRank.c) return 0xFFFF6B00; // Laranja para C
    if (taskRank == TaskRank.d) return 0xFF00F0FF; // Cyan para D
    if (taskRank == TaskRank.e) return 0xFF808080; // Cinza para E
    
    return 0xFF00F0FF; // Default cyan
  }
}
