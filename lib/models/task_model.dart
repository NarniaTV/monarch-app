import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/constants.dart';

/// Modelo de Tarefa (Rank C, D ou E)
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskRank rank;
  final StatType statType;
  final List<String> tags;
  final int xpReward;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? linkedObjectiveId; // Pode estar linkado a um objetivo ou hábito
  final DateTime createdAt;
  final String? time; // Horário no formato "HH:mm" (ex: "14:30")
  final String? calendarEventId; // ID do evento no Google Calendar

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.rank,
    required this.statType,
    this.tags = const [],
    required this.xpReward,
    this.isCompleted = false,
    this.completedAt,
    this.linkedObjectiveId,
    required this.createdAt,
    this.time,
    this.calendarEventId,
  });

  /// Cria uma nova tarefa
  factory TaskModel.create({
    required String userId,
    required String title,
    String? description,
    required TaskRank rank,
    required StatType statType,
    List<String>? tags,
    String? linkedObjectiveId,
  }) {
    // Calcula XP baseado no rank
    int xpReward;
    switch (rank) {
      case TaskRank.s:
        xpReward = XpValues.rankS;
        break;
      case TaskRank.a:
        xpReward = XpValues.rankA;
        break;
      case TaskRank.b:
        xpReward = XpValues.rankB;
        break;
      case TaskRank.c:
        xpReward = XpValues.rankC;
        break;
      case TaskRank.d:
        xpReward = XpValues.rankD;
        break;
      case TaskRank.e:
        xpReward = XpValues.rankE;
        break;
    }

    return TaskModel(
      id: '',
      userId: userId,
      title: title,
      description: description,
      rank: rank,
      statType: statType,
      tags: tags ?? [],
      xpReward: xpReward,
      isCompleted: false,
      createdAt: DateTime.now(),
      linkedObjectiveId: linkedObjectiveId,
    );
  }

  /// Converte do Firestore
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Documento sem dados: ${doc.id}');
      }
      
      // Parse createdAt com tratamento robusto
      DateTime createdAt;
      if (data['createdAt'] != null) {
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is DateTime) {
          createdAt = data['createdAt'] as DateTime;
        } else {
          createdAt = DateTime.now();
        }
      } else {
        createdAt = DateTime.now();
      }
      
      return TaskModel(
        id: doc.id,
        userId: data['userId']?.toString() ?? '',
        title: data['title']?.toString() ?? '',
        description: data['description']?.toString(),
        rank: TaskRank.values.firstWhere(
          (e) => e.name == (data['rank']?.toString() ?? 'e'),
          orElse: () => TaskRank.e,
        ),
        statType: StatType.values.firstWhere(
          (e) => e.name == (data['statType']?.toString() ?? 'power'),
          orElse: () => StatType.power,
        ),
        tags: data['tags'] != null 
            ? List<String>.from(data['tags'] as List)
            : [],
        xpReward: (data['xpReward'] as num?)?.toInt() ?? 0,
        isCompleted: data['isCompleted'] as bool? ?? false,
        completedAt: data['completedAt'] != null
            ? ((data['completedAt'] is Timestamp)
                ? (data['completedAt'] as Timestamp).toDate()
                : null)
            : null,
        linkedObjectiveId: data['linkedObjectiveId']?.toString(),
        createdAt: createdAt,
        time: data['time']?.toString(),
        calendarEventId: data['calendarEventId']?.toString(),
      );
    } catch (e) {
      print('Erro ao converter TaskModel do Firestore (doc: ${doc.id}): $e');
      // Retorna uma tarefa padrão para não quebrar o stream
      return TaskModel(
        id: doc.id,
        userId: '',
        title: 'Tarefa com erro',
        rank: TaskRank.e,
        statType: StatType.power,
        xpReward: 0,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Converte para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'rank': rank.name,
      'statType': statType.name,
      'tags': tags,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'linkedObjectiveId': linkedObjectiveId,
      'createdAt': Timestamp.fromDate(createdAt),
      'time': time,
      'calendarEventId': calendarEventId,
    };
  }

  /// Cria uma cópia com campos atualizados
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskRank? rank,
    StatType? statType,
    List<String>? tags,
    int? xpReward,
    bool? isCompleted,
    DateTime? completedAt,
    String? linkedObjectiveId,
    DateTime? createdAt,
    String? time,
    String? calendarEventId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      rank: rank ?? this.rank,
      statType: statType ?? this.statType,
      tags: tags ?? this.tags,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      linkedObjectiveId: linkedObjectiveId ?? this.linkedObjectiveId,
      createdAt: createdAt ?? this.createdAt,
      time: time ?? this.time,
      calendarEventId: calendarEventId ?? this.calendarEventId,
    );
  }
}
