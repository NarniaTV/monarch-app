import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/constants.dart';
import '../models/shadow_model.dart';
import '../models/task_model.dart';
import '../models/objective_model.dart';
import '../repositories/shadow_repository.dart';
import '../repositories/task_repository.dart';
import 'sync_service.dart';

/// Service para gerenciar lógica de negócio de Sombras
class ShadowService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ShadowRepository _shadowRepository = ShadowRepository();
  final TaskRepository _taskRepository = TaskRepository();
  final SyncService _syncService = SyncService();

  /// Extrai sombra de uma tarefa Rank C ou superior
  /// 
  /// Bônus:
  /// - Rank A: 15% XP, 12% eficiência
  /// - Rank C: 10% XP, 8% eficiência
  /// - Rank D: 5% XP, 5% eficiência
  /// - Rank E: não gera sombra
  Future<ShadowModel?> extractShadowFromTask(TaskModel task) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Apenas tarefas completadas Rank C ou superior geram sombras
    if (!task.isCompleted) {
      throw Exception('Tarefa não está completa');
    }

    if (task.rank != TaskRank.a && 
        task.rank != TaskRank.c && 
        task.rank != TaskRank.d) {
      return null; // Rank E não gera sombra
    }

    try {
      // Calcula bônus baseado no rank
      int xpBonus;
      int efficiencyBonus;

      switch (task.rank) {
        case TaskRank.a:
          xpBonus = 15;
          efficiencyBonus = 12;
          break;
        case TaskRank.c:
          xpBonus = 10;
          efficiencyBonus = 8;
          break;
        case TaskRank.d:
          xpBonus = 5;
          efficiencyBonus = 5;
          break;
        default:
          xpBonus = 0;
          efficiencyBonus = 0;
      }

      // Cria sombra
      final uuid = const Uuid();
      final shadow = ShadowModel(
        id: uuid.v4(), // ID único para offline-first
        userId: user.uid,
        name: task.title,
        type: 'task',
        taskRank: task.rank,
        objectiveRank: null,
        statType: task.statType,
        xpBonus: xpBonus,
        efficiencyBonus: efficiencyBonus,
        isEquipped: false,
        extractedAt: DateTime.now(),
        tags: task.tags,
      );

      // SEMPRE salva no Isar PRIMEIRO (fonte primária)
      await _syncService.saveShadowLocally(shadow);

      // Se online, salva no Firestore também
      final isOnline = await _syncService.isOnline();
      if (isOnline) {
        try {
          final shadowId = await _shadowRepository.createShadow(shadow);
          // Atualiza no Isar com ID do Firestore se diferente
          if (shadowId != shadow.id) {
            await _syncService.saveShadowLocally(shadow.copyWith(id: shadowId));
          }
        } catch (e) {
          print('[SHADOW SERVICE] ⚠️ Erro ao criar sombra no Firestore (já salva localmente): $e');
        }
      }

      // Retorna sombra com ID
      return shadow;
    } catch (e) {
      throw Exception('Erro ao extrair sombra da tarefa: $e');
    }
  }

  /// Extrai sombra DOURADA de um objetivo S completado
  /// 
  /// Bônus: +50% XP, 20% eficiência
  /// Stat Type é calculado baseado nas tarefas vinculadas
  Future<ShadowModel> extractShadowFromObjective(ObjectiveModel objective) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Apenas objetivos S completados (100%) geram sombras
    if (objective.rank != ObjectiveRank.s) {
      throw Exception('Apenas objetivos S geram sombras');
    }

    if (objective.progress < 100) {
      throw Exception('Objetivo não está completo');
    }

    try {
      // Busca tarefas vinculadas ao objetivo para determinar o stat predominante
      final tasks = await _taskRepository.getTasksByObjective(user.uid, objective.id);
      
      // Calcula stat predominante (se houver tarefas)
      StatType? predominantStat;
      if (tasks.isNotEmpty) {
        final statCounts = <StatType, int>{};
        for (final task in tasks) {
          statCounts[task.statType] = (statCounts[task.statType] ?? 0) + 1;
        }
        // Pega o stat com mais ocorrências
        predominantStat = statCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // Sombra dourada épica
      final uuid = const Uuid();
      final shadow = ShadowModel(
        id: uuid.v4(), // ID único para offline-first
        userId: user.uid,
        name: objective.title,
        type: 'objective',
        taskRank: null,
        objectiveRank: ObjectiveRank.s,
        statType: predominantStat, // Pode ser null se não houver tarefas
        xpBonus: 50, // Bônus épico!
        efficiencyBonus: 20,
        isEquipped: false,
        extractedAt: DateTime.now(),
        tags: [], // Objetivos S não tem tags
      );

      // SEMPRE salva no Isar PRIMEIRO (fonte primária)
      await _syncService.saveShadowLocally(shadow);

      // Se online, salva no Firestore também
      final isOnline = await _syncService.isOnline();
      if (isOnline) {
        try {
          final shadowId = await _shadowRepository.createShadow(shadow);
          // Atualiza no Isar com ID do Firestore se diferente
          if (shadowId != shadow.id) {
            await _syncService.saveShadowLocally(shadow.copyWith(id: shadowId));
          }
        } catch (e) {
          print('[SHADOW SERVICE] ⚠️ Erro ao criar sombra no Firestore (já salva localmente): $e');
        }
      }

      // Retorna sombra com ID
      return shadow;
    } catch (e) {
      throw Exception('Erro ao extrair sombra do objetivo: $e');
    }
  }

  /// Equipa uma sombra (máximo 3 sombras equipadas)
  Future<void> equipShadow(String shadowId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Verifica quantas sombras já estão equipadas
      final equippedCount = await _shadowRepository.countEquippedShadows(user.uid);

      if (equippedCount >= 3) {
        throw Exception('Máximo de 3 sombras equipadas atingido');
      }

      // Equipa sombra
      await _shadowRepository.equipShadow(user.uid, shadowId);
    } catch (e) {
      throw Exception('Erro ao equipar sombra: $e');
    }
  }

  /// Desequipa uma sombra
  Future<void> unequipShadow(String shadowId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      await _shadowRepository.unequipShadow(user.uid, shadowId);
    } catch (e) {
      throw Exception('Erro ao desequipar sombra: $e');
    }
  }

  /// Calcula o bônus total de XP das sombras equipadas
  /// 
  /// [taskTags] - Tags da tarefa sendo completada (para matching)
  /// [taskStatType] - Stat da tarefa (para matching)
  /// 
  /// Retorna % de bônus total (máximo 100%)
  Future<int> calculateXpBonus({
    List<String> taskTags = const [],
    required StatType taskStatType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      // Busca sombras equipadas
      final equippedShadows = await _shadowRepository.getEquippedShadows(user.uid);

      if (equippedShadows.isEmpty) return 0;

      int totalBonus = 0;

      for (final shadow in equippedShadows) {
        // Verifica matching de stat (se a sombra tiver stat)
        bool statMatches = shadow.statType != null && shadow.statType == taskStatType;

        // Verifica matching de tags
        bool tagMatches = false;
        if (taskTags.isNotEmpty && shadow.tags.isNotEmpty) {
          tagMatches = taskTags.any((tag) => shadow.tags.contains(tag));
        }

        // Se houver match (stat ou tag), aplica bônus
        // Sombras sem stat específico (de objetivos) aplicam sempre
        if (statMatches || tagMatches || shadow.statType == null) {
          totalBonus += shadow.xpBonus;
        }
      }

      // Limita a 100% de bônus máximo
      return totalBonus > 100 ? 100 : totalBonus;
    } catch (e) {
      print('Erro ao calcular bônus de XP: $e');
      return 0;
    }
  }

  /// Calcula o bônus de eficiência das sombras equipadas
  /// 
  /// Similar ao XP bonus, mas retorna % de eficiência
  Future<int> calculateEfficiencyBonus({
    List<String> taskTags = const [],
    required StatType taskStatType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final equippedShadows = await _shadowRepository.getEquippedShadows(user.uid);

      if (equippedShadows.isEmpty) return 0;

      int totalBonus = 0;

      for (final shadow in equippedShadows) {
        bool statMatches = shadow.statType != null && shadow.statType == taskStatType;
        bool tagMatches = false;
        
        if (taskTags.isNotEmpty && shadow.tags.isNotEmpty) {
          tagMatches = taskTags.any((tag) => shadow.tags.contains(tag));
        }

        // Sombras sem stat específico (de objetivos) aplicam sempre
        if (statMatches || tagMatches || shadow.statType == null) {
          totalBonus += shadow.efficiencyBonus;
        }
      }

      return totalBonus > 50 ? 50 : totalBonus; // Máximo 50% de eficiência
    } catch (e) {
      print('Erro ao calcular bônus de eficiência: $e');
      return 0;
    }
  }

  /// Retorna todas as sombras do usuário
  Future<List<ShadowModel>> getAllShadows() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    return await _shadowRepository.getAllShadows(user.uid);
  }

  /// Stream de todas as sombras
  Stream<List<ShadowModel>> watchShadows() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    return _shadowRepository.watchShadows(user.uid);
  }

  /// Stream de sombras equipadas
  Stream<List<ShadowModel>> watchEquippedShadows() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    return _shadowRepository.watchEquippedShadows(user.uid);
  }

  /// Deleta uma sombra
  Future<void> deleteShadow(String shadowId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      await _shadowRepository.deleteShadow(user.uid, shadowId);
    } catch (e) {
      throw Exception('Erro ao deletar sombra: $e');
    }
  }
}
