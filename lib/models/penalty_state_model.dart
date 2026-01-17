import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de estado da Penalty Zone
class PenaltyStateModel {
  final String userId;
  final bool isInPenaltyZone;
  final DateTime? penaltyStartedAt;
  final int daysRemaining; // 3 dias para completar quitação
  final int quitationProgress; // 0-3 (completar todas daily quests 3 dias seguidos)
  final DateTime? lastQuitationDate; // Última vez que progrediu na quitação

  PenaltyStateModel({
    required this.userId,
    this.isInPenaltyZone = false,
    this.penaltyStartedAt,
    this.daysRemaining = 3,
    this.quitationProgress = 0,
    this.lastQuitationDate,
  });

  /// Cria estado inicial (sem penalty)
  factory PenaltyStateModel.initial(String userId) {
    return PenaltyStateModel(
      userId: userId,
      isInPenaltyZone: false,
      daysRemaining: 3,
      quitationProgress: 0,
    );
  }

  /// Converte do Firestore
  factory PenaltyStateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PenaltyStateModel(
      userId: doc.id,
      isInPenaltyZone: data['isInPenaltyZone'] ?? false,
      penaltyStartedAt: (data['penaltyStartedAt'] as Timestamp?)?.toDate(),
      daysRemaining: data['daysRemaining'] ?? 3,
      quitationProgress: data['quitationProgress'] ?? 0,
      lastQuitationDate: (data['lastQuitationDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Converte para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'isInPenaltyZone': isInPenaltyZone,
      'penaltyStartedAt': penaltyStartedAt != null ? Timestamp.fromDate(penaltyStartedAt!) : null,
      'daysRemaining': daysRemaining,
      'quitationProgress': quitationProgress,
      'lastQuitationDate': lastQuitationDate != null ? Timestamp.fromDate(lastQuitationDate!) : null,
    };
  }

  /// Cria uma cópia com campos atualizados
  PenaltyStateModel copyWith({
    String? userId,
    bool? isInPenaltyZone,
    DateTime? penaltyStartedAt,
    int? daysRemaining,
    int? quitationProgress,
    DateTime? lastQuitationDate,
  }) {
    return PenaltyStateModel(
      userId: userId ?? this.userId,
      isInPenaltyZone: isInPenaltyZone ?? this.isInPenaltyZone,
      penaltyStartedAt: penaltyStartedAt ?? this.penaltyStartedAt,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      quitationProgress: quitationProgress ?? this.quitationProgress,
      lastQuitationDate: lastQuitationDate ?? this.lastQuitationDate,
    );
  }
}
