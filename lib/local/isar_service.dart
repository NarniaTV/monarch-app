import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_models.dart';

/// Serviço para gerenciar instância do Isar
class IsarService {
  static Isar? _isar;
  static bool _initialized = false;

  /// Inicializa o Isar
  static Future<Isar> init() async {
    if (_isar != null) {
      return _isar!;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [
          IsarTaskSchema,
          IsarObjectiveSchema,
          IsarShadowSchema,
          IsarTrophySchema,
        ],
        directory: dir.path,
      );
      _initialized = true;
      return _isar!;
    } catch (e) {
      throw Exception('Erro ao inicializar Isar: $e');
    }
  }

  /// Obtém instância do Isar (inicializa se necessário)
  static Future<Isar> get instance async {
    if (_isar != null) {
      return _isar!;
    }
    return await init();
  }

  /// Verifica se Isar está inicializado
  static bool get isInitialized => _initialized && _isar != null;

  /// Fecha o Isar (útil para testes ou limpeza)
  static Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      _initialized = false;
    }
  }
}
