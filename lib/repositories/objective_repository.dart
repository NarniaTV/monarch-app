import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/objective_model.dart';
import '../core/utils/constants.dart';
import '../local/isar_service.dart';
import '../local/isar_models.dart';

/// Repository para gerenciar Objetivos - OFFLINE-FIRST
/// Sempre salva no Isar primeiro, sincroniza Firestore em background
class ObjectiveRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- MÉTODOS DE LEITURA (OFFLINE-FIRST) ---

  /// Busca objetivos ativos por rank - OFFLINE-FIRST
  Future<List<ObjectiveModel>> getActiveObjectivesByRank(
    String userId,
    ObjectiveRank rank,
  ) async {
    // 1. Lê do Isar primeiro (Rápido)
    final isar = await IsarService.instance;
    final isarObjectives = await isar.isarObjectives
        .filter()
        .userIdEqualTo(userId)
        .rankEqualTo(rank.name)
        .progressLessThan(100)
        .findAll();
    
    // Se tiver dados locais, retorna eles
    if (isarObjectives.isNotEmpty) {
      return isarObjectives.map((o) => o.toObjectiveModel()).toList();
    }

    // Se Isar vazio (primeiro uso), tenta Firestore
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('objectives')
          .where('rank', isEqualTo: rank.name)
          .where('progress', isLessThan: 100)
          .orderBy('progress')
          .orderBy('createdAt')
          .get()
          .timeout(const Duration(seconds: 5));

      final objectives = snapshot.docs
          .map((doc) => ObjectiveModel.fromFirestore(doc))
          .toList();
      
      // Salva no Isar para próximas leituras
      for (final obj in objectives) {
        _saveLocalOnly(obj).catchError((e) => print('[OBJ REPO] Erro ao salvar: $e'));
      }
      
      return objectives;
    } catch (e) {
      print('[OBJ REPO] ⚠️ Erro ao buscar do Firestore: $e');
      return [];
    }
  }

  /// Stream de objetivos ativos por rank - OFFLINE-FIRST
  Stream<List<ObjectiveModel>> getActiveObjectivesStreamByRank(
    String userId,
    ObjectiveRank rank,
  ) async* {
    final isar = await IsarService.instance;
    
    // PASSO 1: Lê PRIMEIRO do Isar (fonte primária - retorna imediatamente)
    try {
      final isarObjectives = await isar.isarObjectives
          .filter()
          .userIdEqualTo(userId)
          .rankEqualTo(rank.name)
          .progressLessThan(100)
          .findAll();
      
      final localObjectives = isarObjectives.map((o) => o.toObjectiveModel()).toList();
      print('[OBJ REPO] ✅ ${localObjectives.length} objetivos ativos encontrados localmente (exibindo imediatamente)');
      yield localObjectives; // Emite dados locais imediatamente
    } catch (e) {
      print('[OBJ REPO] ⚠️ Erro ao buscar localmente: $e');
      yield <ObjectiveModel>[];
      return; // Para se falhar ao buscar localmente
    }
    
    // PASSO 2: Se online, sincroniza do Firestore em background
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.every((result) => result == ConnectivityResult.none)) {
      print('[OBJ REPO] Offline - usando apenas dados locais (stream finalizado)');
      return; // Offline - finaliza stream imediatamente
    }
    
    // Online: Sincroniza em background
    try {
      await for (final snapshot in _firestore
          .collection('users')
          .doc(userId)
          .collection('objectives')
          .where('rank', isEqualTo: rank.name)
          .where('progress', isLessThan: 100)
          .orderBy('progress')
          .orderBy('createdAt')
          .snapshots()
          .timeout(const Duration(seconds: 10), onTimeout: (sink) {
            print('[OBJ REPO] ⚠️ Timeout no stream Firestore (mantendo dados locais)');
            sink.close();
          })) {
        try {
          final objectives = snapshot.docs
              .map((doc) {
                try {
                  return ObjectiveModel.fromFirestore(doc);
                } catch (e) {
                  print('[OBJ REPO] Erro ao converter objetivo ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<ObjectiveModel>()
              .toList();
          
          // Atualiza Isar em background (não bloqueia)
          for (final obj in objectives) {
            _saveLocalOnly(obj).catchError((e) {
              print('[OBJ REPO] Erro ao salvar localmente: $e');
            });
          }
          
          yield objectives; // Emite atualização quando sincronização completar
        } catch (e) {
          print('[OBJ REPO] ⚠️ Erro ao processar snapshot: $e');
          // Não emite novamente - mantém dados locais já emitidos
        }
      }
    } catch (error, stackTrace) {
      print('[OBJ REPO] ⚠️ Erro no stream Firestore (mantendo dados locais): $error');
      print('[OBJ REPO] Stack trace: $stackTrace');
      // Não emite novamente - já emitiu dados locais acima
      return; // Finaliza o stream para evitar loops
    }
  }

  /// Busca todos os objetivos ativos (todos os ranks) - OFFLINE-FIRST
  Future<List<ObjectiveModel>> getActiveObjectives(String userId) async {
    // 1. Lê do Isar (Rápido)
    final isar = await IsarService.instance;
    final isarObjectives = await isar.isarObjectives
        .filter()
        .userIdEqualTo(userId)
        .progressLessThan(100)
        .findAll();
    
    // Se tiver dados locais, retorna eles
    if (isarObjectives.isNotEmpty) {
      return isarObjectives.map((o) => o.toObjectiveModel()).toList();
    }

    // Se Isar vazio (primeiro uso), tenta Firestore
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('objectives')
          .where('progress', isLessThan: 100)
          .orderBy('progress')
          .orderBy('createdAt')
          .get()
          .timeout(const Duration(seconds: 5));

      final objectives = snapshot.docs
          .map((doc) => ObjectiveModel.fromFirestore(doc))
          .toList();
      
      // Salva no Isar para próximas leituras
      for (final obj in objectives) {
        _saveLocalOnly(obj).catchError((e) => print('[OBJ REPO] Erro ao salvar: $e'));
      }
      
      return objectives;
    } catch (e) {
      print('[OBJ REPO] ⚠️ Erro ao buscar do Firestore: $e');
      return [];
    }
  }

  /// Stream de todos os objetivos ativos - OFFLINE-FIRST
  Stream<List<ObjectiveModel>> getActiveObjectivesStream(String userId) async* {
    final isar = await IsarService.instance;
    
    // PASSO 1: Lê PRIMEIRO do Isar (fonte primária - retorna imediatamente)
    try {
      final isarObjectives = await isar.isarObjectives
          .filter()
          .userIdEqualTo(userId)
          .progressLessThan(100)
          .findAll();
      
      final localObjectives = isarObjectives.map((o) => o.toObjectiveModel()).toList();
      print('[OBJ REPO] ✅ ${localObjectives.length} objetivos ativos encontrados localmente (exibindo imediatamente)');
      yield localObjectives; // Emite dados locais imediatamente
    } catch (e) {
      print('[OBJ REPO] ⚠️ Erro ao buscar localmente: $e');
      yield <ObjectiveModel>[];
      return; // Para se falhar ao buscar localmente
    }
    
    // PASSO 2: Se online, sincroniza do Firestore em background
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.every((result) => result == ConnectivityResult.none)) {
      print('[OBJ REPO] Offline - usando apenas dados locais (stream finalizado)');
      return; // Offline - finaliza stream imediatamente
    }
    
    // Online: Sincroniza em background
    try {
      await for (final snapshot in _firestore
          .collection('users')
          .doc(userId)
          .collection('objectives')
          .where('progress', isLessThan: 100)
          .orderBy('progress')
          .orderBy('createdAt')
          .snapshots()
          .timeout(const Duration(seconds: 10), onTimeout: (sink) {
            print('[OBJ REPO] ⚠️ Timeout no stream Firestore (mantendo dados locais)');
            sink.close();
          })) {
        try {
          final objectives = snapshot.docs
              .map((doc) {
                try {
                  return ObjectiveModel.fromFirestore(doc);
                } catch (e) {
                  print('[OBJ REPO] Erro ao converter objetivo ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<ObjectiveModel>()
              .toList();
          
          // Atualiza Isar em background (não bloqueia)
          for (final obj in objectives) {
            _saveLocalOnly(obj).catchError((e) {
              print('[OBJ REPO] Erro ao salvar localmente: $e');
            });
          }
          
          yield objectives; // Emite atualização quando sincronização completar
        } catch (e) {
          print('[OBJ REPO] ⚠️ Erro ao processar snapshot: $e');
          // Não emite novamente - mantém dados locais já emitidos
        }
      }
    } catch (error, stackTrace) {
      print('[OBJ REPO] ⚠️ Erro no stream Firestore (mantendo dados locais): $error');
      print('[OBJ REPO] Stack trace: $stackTrace');
      // Não emite novamente - já emitiu dados locais acima
      return; // Finaliza o stream para evitar loops
    }
  }

  // --- MÉTODOS DE ESCRITA (OFFLINE-FIRST) ---

  /// Cria um novo objetivo - OFFLINE-FIRST
  /// Salva no Isar PRIMEIRO, sincroniza Firestore em background
  /// 
  /// Se o objetivo não tiver ID, gera UUID v4 automaticamente
  Future<ObjectiveModel> createObjective(ObjectiveModel objective) async {
    // Verifica limite apenas para Rank S (máximo 3) - lê do Isar
    if (objective.rank == ObjectiveRank.s) {
      final activeObjectivesS = await getActiveObjectivesByRank(
        objective.userId,
        ObjectiveRank.s,
      );
      if (activeObjectivesS.length >= SystemLimits.maxObjectivesS) {
        throw Exception('Máximo de ${SystemLimits.maxObjectivesS} objetivos S ativos atingido');
      }
    }

    // 1. Garante que o objetivo tem um ID único (UUID v4)
    final uuid = const Uuid();
    final objectiveWithId = objective.id.isEmpty 
        ? objective.copyWith(id: uuid.v4()) 
        : objective;
    
    // 2. Salva no Isar IMEDIATAMENTE (Sem depender de internet)
    await _saveLocalOnly(objectiveWithId);

    // 3. Tenta enviar para nuvem em background (Fire and Forget)
    _trySyncToFirestore(objectiveWithId);
    
    // Retorna objetivo com ID já existente (UUID gerado localmente)
    return objectiveWithId;
  }

  /// Atualiza um objetivo - OFFLINE-FIRST (ATOMIC READ-MODIFY-WRITE)
  Future<void> updateObjective(ObjectiveModel objective) async {
    final isar = await IsarService.instance;
    
    await isar.writeTxn(() async {
      // 1. Busca o objeto REAL do banco local usando o UUID
      final isarObjective = await isar.isarObjectives
          .filter()
          .objectiveIdEqualTo(objective.id)
          .findFirst();
      
      if (isarObjective == null) {
        // Se não existe, cria novo (caso edge)
        final newIsarObjective = IsarObjective.fromObjectiveModel(
          objective,
          isSynced: false,
          needsSync: true,
        );
        await isar.isarObjectives.put(newIsarObjective);
        print('[OBJ REPO] ✅ Objetivo criado (não existia): ${objective.title}');
        return;
      }
      
      // 2. Modifica as propriedades no objeto recuperado (preserva id interno)
      isarObjective.title = objective.title;
      isarObjective.description = objective.description;
      isarObjective.rank = objective.rank.name;
      isarObjective.statType = objective.statType?.name;
      isarObjective.progress = objective.progress;
      isarObjective.streak = objective.streak;
      isarObjective.deadline = objective.deadline;
      isarObjective.completedAt = objective.completedAt;
      isarObjective.frequencyType = objective.frequencyType?.name;
      isarObjective.frequencyValue = objective.frequencyValue;
      isarObjective.weekDays = objective.weekDays != null
          ? List<int>.from(objective.weekDays!)
          : null;
      isarObjective.time = objective.time;
      isarObjective.calendarEventId = objective.calendarEventId;
      
      // Marca para sincronização
      isarObjective.isSynced = false;
      isarObjective.needsSync = true;
      
      // 3. Salva o MESMO objeto (mantendo o id interno)
      await isar.isarObjectives.put(isarObjective);
      print('[OBJ REPO] ✅ Objetivo atualizado localmente: ${objective.title}');
    });
    
    // 4. Tenta sync em background (Fire and Forget)
    _trySyncToFirestore(objective);
  }

  /// Completa um objetivo (marca progresso como 100%) - OFFLINE-FIRST (ATOMIC READ-MODIFY-WRITE)
  Future<void> completeObjective(ObjectiveModel objective) async {
    final isar = await IsarService.instance;
    
    await isar.writeTxn(() async {
      // 1. Busca o objeto REAL do banco local usando o UUID
      final isarObjective = await isar.isarObjectives
          .filter()
          .objectiveIdEqualTo(objective.id)
          .findFirst();
      
      if (isarObjective == null) {
        print('[OBJ REPO] ⚠️ Objetivo não encontrado para completar: ${objective.id}');
        return;
      }
      
      // 2. Modifica as propriedades no objeto recuperado
      isarObjective.progress = 100;
      isarObjective.completedAt = DateTime.now();
      isarObjective.isSynced = false; // Marca para sync
      isarObjective.needsSync = true;
      
      // 3. Salva o MESMO objeto (mantendo o id interno)
      await isar.isarObjectives.put(isarObjective);
      print('[OBJ REPO] ✅ Objetivo completado localmente: ${objective.title}');
    });
    
    // 4. Tenta sync em background (Fire and Forget)
    final completedObjective = objective.copyWith(
      progress: 100,
      completedAt: DateTime.now(),
    );
    _trySyncToFirestore(completedObjective);
  }

  /// Deleta um objetivo - OFFLINE-FIRST
  Future<void> deleteObjective(String userId, String objectiveId) async {
    // 1. Deleta do Isar
    final isar = await IsarService.instance;
    final existing = await isar.isarObjectives
        .filter()
        .objectiveIdEqualTo(objectiveId)
        .findFirst();
    
    if (existing != null) {
      await isar.writeTxn(() async {
        await isar.isarObjectives.delete(existing.id);
      });
    }

    // 2. Deleta do Firestore (silenciosamente em background)
    _firestore
        .collection('users')
        .doc(userId)
        .collection('objectives')
        .doc(objectiveId)
        .delete()
        .catchError((e) => print('[OBJ REPO] Erro ao deletar no Firestore (será sincronizado depois): $e'));
  }

  // --- MÉTODOS AUXILIARES PRIVADOS ---

  /// Salva no Isar marcando como 'needsSync = true' (Pessimista)
  Future<void> _saveLocalOnly(ObjectiveModel objective) async {
    final isar = await IsarService.instance;
    
    // Converte para modelo do Isar
    // Assumimos 'needsSync = true' por padrão. Se a net funcionar depois, mudamos pra false.
    final isarObjective = IsarObjective.fromObjectiveModel(
      objective, 
      isSynced: false, 
      needsSync: true,
    );

    // Precisamos manter o ID interno do Isar se já existir
    final existing = await isar.isarObjectives
        .filter()
        .objectiveIdEqualTo(objective.id)
        .findFirst();
    
    if (existing != null) {
      isarObjective.id = existing.id;
    }

    await isar.writeTxn(() async {
      await isar.isarObjectives.put(isarObjective);
    });
    
    print('[OBJ REPO] ✅ Objetivo salvo localmente: ${objective.title}');
  }

  /// Tenta enviar pro Firestore sem travar a UI
  Future<void> _trySyncToFirestore(ObjectiveModel objective) async {
    // Verifica conexão rapidinho
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.every((result) => result == ConnectivityResult.none)) {
      print('[OBJ REPO] Offline - objetivo será sincronizado depois: ${objective.title}');
      return; // Sem net, deixa quieto (já tá salvo no Isar com needsSync=true)
    }

    try {
      await _firestore
          .collection('users')
          .doc(objective.userId)
          .collection('objectives')
          .doc(objective.id)
          .set(objective.toFirestore(), SetOptions(merge: true));

      // Se chegou aqui, salvou na nuvem! Atualiza o Isar para needsSync = false
      final isar = await IsarService.instance;
      final existing = await isar.isarObjectives
          .filter()
          .objectiveIdEqualTo(objective.id)
          .findFirst();
      
      if (existing != null) {
        existing.isSynced = true;
        existing.needsSync = false;
        existing.lastSyncedAt = DateTime.now();
        await isar.writeTxn(() async {
          await isar.isarObjectives.put(existing);
        });
        print('[OBJ REPO] ☁️ Sincronizado com sucesso: ${objective.title}');
      }
    } catch (e) {
      print('[OBJ REPO] ⚠️ Falha no upload (SyncService pegará depois): $e');
    }
  }
}
