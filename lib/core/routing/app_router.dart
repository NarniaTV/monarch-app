import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/constants.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/tasks/presentation/create_task_screen.dart';
import '../../features/objectives/presentation/objectives_screen.dart';
import '../../features/objectives/presentation/create_objective_screen.dart';
import '../../features/dashboard/presentation/stats_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/daily_quests/presentation/daily_quests_screen.dart';
import '../../features/penalty/presentation/penalty_zone_screen.dart';
import '../../features/shadows/presentation/shadow_inventory_screen.dart';
import '../../features/shadows/presentation/trophies_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../services/auth_service.dart';

/// Provider para verificar estado de autenticação
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider global para AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Router principal do aplicativo
class AppRouter {
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      redirect: (context, state) async {
        final currentUser = FirebaseAuth.instance.currentUser;
        final isLoggedIn = currentUser != null;
        final currentLocation = state.matchedLocation;
        final isGoingToAuth = currentLocation == '/login' ||
            currentLocation == '/register';
        final isGoingToOnboarding = currentLocation == '/onboarding';

        // Se não está logado
        if (!isLoggedIn) {
          // Permite acesso às telas de auth, caso contrário redireciona para login
          if (!isGoingToAuth) {
            return '/login';
          }
          return null;
        }

        // Se está logado
        // Busca perfil do usuário para verificar onboarding
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          
          if (userDoc.exists) {
            final hasCompleted = userDoc.data()?['hasCompletedOnboarding'] ?? false;
            
            // Se NÃO completou onboarding
            if (!hasCompleted) {
              // Permite acesso ao onboarding, caso contrário redireciona
              if (!isGoingToOnboarding) {
                return '/onboarding';
              }
              return null;
            }
            
            // Se completou onboarding e está tentando acessar auth/onboarding
            if (isGoingToAuth || isGoingToOnboarding) {
              return '/';
            }
          }
        } catch (e) {
          // Em caso de erro, permite acesso
          debugPrint('Erro ao verificar onboarding: $e');
        }

        // Permite acesso à rota atual
        return null;
      },
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(
        FirebaseAuth.instance.authStateChanges(),
      ),
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/tasks',
          builder: (context, state) => const TasksScreen(),
        ),
        GoRoute(
          path: '/tasks/create',
          builder: (context, state) => const CreateTaskScreen(),
        ),
        GoRoute(
          path: '/objectives',
          builder: (context, state) => const ObjectivesScreen(),
        ),
        GoRoute(
          path: '/objectives/create',
          builder: (context, state) {
            final rankParam = state.uri.queryParameters['rank'];
            ObjectiveRank? initialRank;
            if (rankParam != null) {
              try {
                initialRank = ObjectiveRank.values.firstWhere(
                  (r) => r.name == rankParam,
                );
              } catch (e) {
                initialRank = null;
              }
            }
            return CreateObjectiveScreen(initialRank: initialRank);
          },
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsScreen(),
        ),
        GoRoute(
          path: '/daily-quests',
          builder: (context, state) => const DailyQuestsScreen(),
        ),
        GoRoute(
          path: '/penalty-zone',
          builder: (context, state) => const PenaltyZoneScreen(),
        ),
        GoRoute(
          path: '/shadow-inventory',
          builder: (context, state) => const ShadowInventoryScreen(),
        ),
        GoRoute(
          path: '/trophies',
          builder: (context, state) => const TrophiesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
      ],
    );
  }
}

/// Helper para fazer o router reagir a mudanças no stream
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<User?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
