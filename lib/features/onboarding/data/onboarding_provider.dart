import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/onboarding_service.dart';
import '../../../../repositories/user_repository.dart';

/// Provider para OnboardingService
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

/// Provider para verificar se o usuário completou o onboarding
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final userRepository = UserRepository();
  final userProfile = await userRepository.getUser(user.uid);
  return userProfile?.hasCompletedOnboarding ?? false;
});

/// Provider para o perfil do usuário
final userProfileProvider = StreamProvider((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  final userRepository = UserRepository();
  return userRepository.getUserStream(user.uid);
});
