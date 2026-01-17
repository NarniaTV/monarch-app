import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';

/// Serviço para gerenciar conectividade e sincronização automática
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final SyncService _syncService = SyncService();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isListening = false;
  bool _wasOffline = false;

  /// Inicia listener de conectividade para sincronização automática
  Future<void> startListening() async {
    if (_isListening) return;

    _isListening = true;

    // Verifica estado inicial
    final initialStatus = await _connectivity.checkConnectivity();
    _wasOffline = initialStatus.every((result) => result == ConnectivityResult.none);

    // Listener para mudanças de conectividade
    // Apenas monitora status - sincronização é passiva via streams do Firestore
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final isOffline = results.every((result) => result == ConnectivityResult.none);
        
        print('[CONNECTIVITY] Mudança detectada: ${isOffline ? "OFFLINE" : "ONLINE"} (${results.join(", ")})');

        if (_wasOffline && !isOffline) {
          // Voltou online - streams do Firestore sincronizam automaticamente
          print('[CONNECTIVITY] ✅ Conexão restabelecida - streams sincronizam automaticamente');
        } else if (!_wasOffline && isOffline) {
          // Ficou offline
          print('[CONNECTIVITY] ⚠️ Conexão perdida - modo offline ativado');
        }

        _wasOffline = isOffline;
      },
      onError: (error) {
        print('[CONNECTIVITY] ❌ Erro no listener de conectividade: $error');
      },
      cancelOnError: false, // Continua ouvindo mesmo se houver erro
    );

    print('[CONNECTIVITY] ✅ Listener de conectividade iniciado');
  }

  /// Para o listener de conectividade
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    print('[CONNECTIVITY] Listener de conectividade parado');
  }

  /// Verifica estado atual de conectividade (usa SyncService para verificação robusta)
  Future<bool> isOnline() async {
    return await _syncService.isOnline();
  }

  /// Verifica se está escutando
  bool get isListening => _isListening;
}
