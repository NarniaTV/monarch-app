import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';
import 'local/isar_service.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientação apenas portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar status bar e navigation bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializar Isar (banco de dados local)
  try {
    await IsarService.init();
    debugPrint('✅ Isar inicializado com sucesso');
  } catch (e) {
    debugPrint('⚠️ Erro ao inicializar Isar: $e');
    // Continua mesmo se Isar falhar (modo online puro)
  }

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inicializar NotificationService após Firebase
    await NotificationService().initializeNotifications();
  } catch (e) {
    // Se Firebase não estiver configurado, o app ainda pode rodar
    // mas a autenticação não funcionará
    debugPrint('Erro ao inicializar Firebase: $e');
    debugPrint(
      'Execute: flutter pub global activate flutterfire_cli && flutterfire configure',
    );
  }

  // Inicializar ConnectivityService para sincronização automática
  try {
    final connectivityService = ConnectivityService();
    await connectivityService.startListening();
    debugPrint(
      '✅ ConnectivityService iniciado - sincronização automática ativa',
    );
  } catch (e) {
    debugPrint('⚠️ Erro ao inicializar ConnectivityService: $e');
    // Continua mesmo se falhar (sincronização manual ainda funciona)
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.createRouter(ref);

    return MaterialApp.router(
      title: 'SYSTEM: AWAKEN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
