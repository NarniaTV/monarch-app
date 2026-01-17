import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/constants.dart';

/// Modelo de Objetivo (Ranks S, A, B)
/// S = Metas de Vida (máx. 3) - usa progress
/// A = Metas a Alcançar (ilimitado) - usa progress
/// B = Hábitos (ilimitado, com frequência) - usa streak
class ObjectiveModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final ObjectiveRank rank; // S, A ou B
  final DateTime? deadline;
  final int progress; // 0-100 (apenas para S e A)
  final int streak; // Sequência de dias consecutivos (apenas para B)
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? time; // Horário no formato "HH:mm" (ex: "14:30")
  
  // Campos para Hábitos (Rank B)
  final FrequencyType? frequencyType;    // Todo dia, A cada X dias, Semanal
  final int? frequencyValue;             // Para everyXDays: a cada X dias
  final List<int>? weekDays;             // Para weekly: [1=Dom, 2=Seg, ..., 7=Sab]
  final StatType? statType;              // Atributo do hábito (Power, Mind, Spirit)
  final String? calendarEventId;         // ID do evento no Google Calendar

  ObjectiveModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.rank,
    this.deadline,
    this.progress = 0,
    this.streak = 0,
    required this.createdAt,
    this.completedAt,
    this.time,
    this.frequencyType,
    this.frequencyValue,
    this.weekDays,
    this.statType,
    this.calendarEventId,
  });

  /// Cria um novo objetivo
  factory ObjectiveModel.create({
    required String userId,
    required String title,
    required ObjectiveRank rank,
    String? description,
    DateTime? deadline,
    String? time,
    FrequencyType? frequencyType,
    int? frequencyValue,
    List<int>? weekDays,
    StatType? statType,
  }) {
    return ObjectiveModel(
      id: '',
      userId: userId,
      title: title,
      rank: rank,
      description: description,
      deadline: deadline,
      progress: 0,
      streak: 0,
      createdAt: DateTime.now(),
      time: time,
      frequencyType: frequencyType,
      frequencyValue: frequencyValue,
      weekDays: weekDays,
      statType: statType,
      // calendarEventId será atribuído depois quando sincronizar com Google Calendar
    );
  }

  /// Converte do Firestore
  factory ObjectiveModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse rank (default para S se não existir, para compatibilidade com dados antigos)
    ObjectiveRank rank = ObjectiveRank.s;
    final rankString = data['rank'] as String?;
    if (rankString != null) {
      rank = ObjectiveRank.values.firstWhere(
        (r) => r.name == rankString,
        orElse: () => ObjectiveRank.s,
      );
    }
    
    // Parse frequencyType (para hábitos)
    FrequencyType? frequencyType;
    final frequencyString = data['frequencyType'] as String?;
    if (frequencyString != null) {
      try {
        frequencyType = FrequencyType.values.firstWhere(
          (f) => f.name == frequencyString,
        );
      } catch (e) {
        frequencyType = null;
      }
    }
    
    // Parse weekDays (para frequência semanal)
    List<int>? weekDays;
    final weekDaysData = data['weekDays'];
    if (weekDaysData is List) {
      weekDays = weekDaysData.map((e) => e as int).toList();
    }
    
    // Parse statType (para hábitos)
    StatType? statType;
    final statTypeString = data['statType'] as String?;
    if (statTypeString != null) {
      try {
        statType = StatType.values.firstWhere(
          (s) => s.name == statTypeString,
        );
      } catch (e) {
        statType = null;
      }
    }
    
    return ObjectiveModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      rank: rank,
      description: data['description'],
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      progress: data['progress'] ?? 0,
      streak: data['streak'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      time: data['time'] as String?,
      frequencyType: frequencyType,
      frequencyValue: data['frequencyValue'] as int?,
      weekDays: weekDays,
      statType: statType,
      calendarEventId: data['calendarEventId']?.toString(),
    );
  }

  /// Converte para Firestore
  Map<String, dynamic> toFirestore() {
    final map = {
      'userId': userId,
      'title': title,
      'rank': rank.name, // Salva como string (s, a, b)
      'description': description,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'progress': progress,
      'streak': streak,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'time': time,
    };
    
    // Adiciona campos de frequência se for hábito (Rank B)
    if (rank == ObjectiveRank.b) {
      map['frequencyType'] = frequencyType?.name;
      map['frequencyValue'] = frequencyValue;
      map['weekDays'] = weekDays;
      map['statType'] = statType?.name;
    }
    
    // Adiciona calendarEventId se existir
    if (calendarEventId != null) {
      map['calendarEventId'] = calendarEventId;
    }
    
    return map;
  }

  /// Cria uma cópia com campos atualizados
  ObjectiveModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ObjectiveRank? rank,
    DateTime? deadline,
    int? progress,
    int? streak,
    DateTime? createdAt,
    DateTime? completedAt,
    String? time,
    FrequencyType? frequencyType,
    int? frequencyValue,
    List<int>? weekDays,
    StatType? statType,
  }) {
    return ObjectiveModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      rank: rank ?? this.rank,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      progress: progress ?? this.progress,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      time: time ?? this.time,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyValue: frequencyValue ?? this.frequencyValue,
      weekDays: weekDays ?? this.weekDays,
      statType: statType ?? this.statType,
      calendarEventId: calendarEventId ?? this.calendarEventId,
    );
  }

  /// Verifica se o objetivo está completo
  bool get isCompleted => progress >= 100;

  /// Calcula o tempo decorrido desde a criação
  Duration get timeElapsed => DateTime.now().difference(createdAt);

  /// Calcula o tempo até o deadline (se houver)
  Duration? get timeUntilDeadline {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now());
  }
}
