import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/constants.dart';

/// Modelo de Troféu (concedido ao completar objetivo S)
class TrophyModel {
  final String id;
  final String userId;
  final String objectiveId;
  final String title; // Título do objetivo S original
  final String description; // Descrição do objetivo
  final StatType? statType; // Opcional (objetivos podem não ter stat específico)
  final DateTime completedAt;
  final int daysToComplete; // Tempo levado em dias
  final bool displayOnDashboard; // Se exibe no dashboard (máx 3)
  final int totalTasksCompleted; // Quantas tarefas foram feitas

  TrophyModel({
    required this.id,
    required this.userId,
    required this.objectiveId,
    required this.title,
    required this.description,
    required this.statType,
    required this.completedAt,
    required this.daysToComplete,
    this.displayOnDashboard = false,
    required this.totalTasksCompleted,
  });

  /// Cria troféu a partir de mapa Firestore
  factory TrophyModel.fromMap(Map<String, dynamic> map, String id) {
    return TrophyModel(
      id: id,
      userId: map['userId'] as String,
      objectiveId: map['objectiveId'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      statType: map['statType'] != null
          ? StatType.values.firstWhere((e) => e.name == map['statType'])
          : null,
      completedAt: (map['completedAt'] as Timestamp).toDate(),
      daysToComplete: map['daysToComplete'] as int,
      displayOnDashboard: map['displayOnDashboard'] as bool? ?? false,
      totalTasksCompleted: map['totalTasksCompleted'] as int? ?? 0,
    );
  }

  /// Converte para mapa Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'objectiveId': objectiveId,
      'title': title,
      'description': description,
      'statType': statType?.name,
      'completedAt': Timestamp.fromDate(completedAt),
      'daysToComplete': daysToComplete,
      'displayOnDashboard': displayOnDashboard,
      'totalTasksCompleted': totalTasksCompleted,
    };
  }

  /// Cria cópia com modificações
  TrophyModel copyWith({
    String? id,
    String? userId,
    String? objectiveId,
    String? title,
    String? description,
    StatType? statType,
    DateTime? completedAt,
    int? daysToComplete,
    bool? displayOnDashboard,
    int? totalTasksCompleted,
  }) {
    return TrophyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      objectiveId: objectiveId ?? this.objectiveId,
      title: title ?? this.title,
      description: description ?? this.description,
      statType: statType ?? this.statType,
      completedAt: completedAt ?? this.completedAt,
      daysToComplete: daysToComplete ?? this.daysToComplete,
      displayOnDashboard: displayOnDashboard ?? this.displayOnDashboard,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
    );
  }

  /// Retorna mensagem de tempo levado
  String getTimeMessage() {
    if (daysToComplete == 0) {
      return 'Completado em menos de 1 dia';
    } else if (daysToComplete == 1) {
      return 'Completado em 1 dia';
    } else if (daysToComplete < 30) {
      return 'Completado em $daysToComplete dias';
    } else if (daysToComplete < 365) {
      final months = (daysToComplete / 30).floor();
      return 'Completado em $months ${months == 1 ? "mês" : "meses"}';
    } else {
      final years = (daysToComplete / 365).floor();
      final remainingDays = daysToComplete % 365;
      final months = (remainingDays / 30).floor();
      if (months == 0) {
        return 'Completado em $years ${years == 1 ? "ano" : "anos"}';
      }
      return 'Completado em $years ${years == 1 ? "ano" : "anos"} e $months ${months == 1 ? "mês" : "meses"}';
    }
  }
}
