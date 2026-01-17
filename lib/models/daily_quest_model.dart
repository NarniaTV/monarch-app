import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Daily Quest (hábito diário com streak)
class DailyQuestModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;
  final int streak; // Sequência de dias consecutivos
  final DateTime? lastCompletedAt;
  final DateTime lastResetDate; // Última vez que resetou
  final int order; // Ordem de exibição (1-5)
  final String? time; // Horário preferido para completar

  DailyQuestModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.streak = 0,
    this.lastCompletedAt,
    required this.lastResetDate,
    this.order = 0,
    this.time,
  });

  /// Cria uma nova daily quest
  factory DailyQuestModel.create({
    required String userId,
    required String title,
    String? description,
    int order = 0,
    String? time,
  }) {
    return DailyQuestModel(
      id: '',
      userId: userId,
      title: title,
      description: description,
      isCompleted: false,
      streak: 0,
      lastResetDate: DateTime.now(),
      order: order,
      time: time,
    );
  }

  /// Converte do Firestore
  factory DailyQuestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DailyQuestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      isCompleted: data['isCompleted'] ?? false,
      streak: data['streak'] ?? 0,
      lastCompletedAt: (data['lastCompletedAt'] as Timestamp?)?.toDate(),
      lastResetDate: (data['lastResetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      order: data['order'] ?? 0,
      time: data['time'] as String?,
    );
  }

  /// Converte para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'streak': streak,
      'lastCompletedAt': lastCompletedAt != null ? Timestamp.fromDate(lastCompletedAt!) : null,
      'lastResetDate': Timestamp.fromDate(lastResetDate),
      'order': order,
      'time': time,
    };
  }

  /// Cria uma cópia com campos atualizados
  DailyQuestModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    int? streak,
    DateTime? lastCompletedAt,
    DateTime? lastResetDate,
    int? order,
    String? time,
  }) {
    return DailyQuestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      streak: streak ?? this.streak,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      order: order ?? this.order,
      time: time ?? this.time,
    );
  }
}
