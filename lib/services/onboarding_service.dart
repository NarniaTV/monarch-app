import 'package:firebase_auth/firebase_auth.dart';
import '../models/objective_model.dart';
import '../repositories/user_repository.dart';
import '../repositories/objective_repository.dart';
import '../core/utils/constants.dart';

/// Service para gerenciar o processo de onboarding
class OnboardingService {
  final UserRepository _userRepository = UserRepository();
  final ObjectiveRepository _objectiveRepository = ObjectiveRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Salva os 3 objetivos S do usuário
  Future<void> saveObjectives({
    required List<ObjectiveModel> objectives,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Validação: deve ter exatamente 3 objetivos
    if (objectives.length != SystemLimits.maxObjectivesS) {
      throw Exception('Você deve definir exatamente ${SystemLimits.maxObjectivesS} objetivos');
    }

    // Validação: todos devem ter título
    for (final objective in objectives) {
      if (objective.title.trim().isEmpty) {
        throw Exception('Todos os objetivos devem ter um título');
      }
    }

    try {
      // IMPORTANTE: Durante o onboarding, deletamos todos os objetivos ativos existentes
      // para garantir que o usuário comece limpo com os 3 novos objetivos
      final existingObjectives = await _objectiveRepository.getActiveObjectives(user.uid);
      for (final existing in existingObjectives) {
        await _objectiveRepository.deleteObjective(user.uid, existing.id);
      }

      // Salva cada objetivo
      for (final objective in objectives) {
        await _objectiveRepository.createObjective(objective);
      }
    } catch (e) {
      throw Exception('Erro ao salvar objetivos: $e');
    }
  }

  /// Salva a mensagem personalizada da Penalty Zone
  Future<void> savePenaltyMessage({
    required String penaltyMessage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    if (penaltyMessage.trim().isEmpty) {
      throw Exception('A mensagem não pode estar vazia');
    }

    if (penaltyMessage.length > 500) {
      throw Exception('A mensagem deve ter no máximo 500 caracteres');
    }

    try {
      await _userRepository.updatePenaltyMessage(
        userId: user.uid,
        penaltyMessage: penaltyMessage.trim(),
      );
    } catch (e) {
      throw Exception('Erro ao salvar mensagem: $e');
    }
  }

  /// Marca o onboarding como completo
  Future<void> markOnboardingComplete() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      await _userRepository.markOnboardingComplete(user.uid);
    } catch (e) {
      throw Exception('Erro ao marcar onboarding como completo: $e');
    }
  }

  /// Verifica se o usuário já completou o onboarding
  Future<bool> hasCompletedOnboarding() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userProfile = await _userRepository.getUser(user.uid);
      return userProfile?.hasCompletedOnboarding ?? false;
    } catch (e) {
      return false;
    }
  }
}
