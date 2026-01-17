import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de perfil do usuário no Firestore
class UserProfileModel {
  final String userId;
  final String email;
  final String? displayName;
  final String nickname; // Nickname único obrigatório
  final DateTime createdAt;
  
  // Campos de game
  final int level;
  final int currentXp;
  final int power;
  final int mind;
  final int spirit;
  
  // Campos de config
  final String? penaltyMessage;
  final bool hasCompletedOnboarding;
  final bool skipOnboardingPrompt; // Se true, não mostra mais o prompt de onboarding

  UserProfileModel({
    required this.userId,
    required this.email,
    this.displayName,
    required this.nickname,
    required this.createdAt,
    this.level = 1,
    this.currentXp = 0,
    this.power = 0,
    this.mind = 0,
    this.spirit = 0,
    this.penaltyMessage,
    this.hasCompletedOnboarding = false,
    this.skipOnboardingPrompt = false,
  });

  /// Cria um novo perfil de usuário com valores padrão
  factory UserProfileModel.create({
    required String userId,
    required String email,
    String? displayName,
    required String nickname,
  }) {
    return UserProfileModel(
      userId: userId,
      email: email,
      displayName: displayName,
      nickname: nickname,
      createdAt: DateTime.now(),
      level: 1,
      currentXp: 0,
      power: 0,
      mind: 0,
      spirit: 0,
      hasCompletedOnboarding: false,
      skipOnboardingPrompt: false,
    );
  }

  /// Converte do Firestore
  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfileModel(
      userId: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      nickname: data['nickname'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      level: data['level'] ?? 1,
      currentXp: data['currentXp'] ?? 0,
      power: data['power'] ?? 0,
      mind: data['mind'] ?? 0,
      spirit: data['spirit'] ?? 0,
      penaltyMessage: data['penaltyMessage'],
      hasCompletedOnboarding: data['hasCompletedOnboarding'] ?? false,
      skipOnboardingPrompt: data['skipOnboardingPrompt'] ?? false,
    );
  }

  /// Converte para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'nickname': nickname,
      'createdAt': Timestamp.fromDate(createdAt),
      'level': level,
      'currentXp': currentXp,
      'power': power,
      'mind': mind,
      'spirit': spirit,
      'penaltyMessage': penaltyMessage,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'skipOnboardingPrompt': skipOnboardingPrompt,
    };
  }

  /// Cria uma cópia com campos atualizados
  UserProfileModel copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? nickname,
    DateTime? createdAt,
    int? level,
    int? currentXp,
    int? power,
    int? mind,
    int? spirit,
    String? penaltyMessage,
    bool? hasCompletedOnboarding,
    bool? skipOnboardingPrompt,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      power: power ?? this.power,
      mind: mind ?? this.mind,
      spirit: spirit ?? this.spirit,
      penaltyMessage: penaltyMessage ?? this.penaltyMessage,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      skipOnboardingPrompt: skipOnboardingPrompt ?? this.skipOnboardingPrompt,
    );
  }
}
