# SyncService Expanded - Métodos para Adicionar

## Métodos a adicionar ao SyncService

### 1. Objectives

```dart
/// Salva objetivo localmente no Isar (modo offline-first)
Future<void> saveObjectiveLocally(ObjectiveModel objective) async {
  final isar = await IsarService.instance;
  final online = await isOnline();

  final isarObjective = IsarObjective.fromObjectiveModel(
    objective,
    isSynced: online,
    needsSync: !online,
  );

  await isar.writeTxn(() async {
    await isar.isarObjectives.put(isarObjective);
  });

  if (!online) {
    print('[SYNC] 📱 Objetivo salvo localmente (offline): ${objective.title}');
  }
}

/// Busca objetivos do Isar (modo offline)
Future<List<ObjectiveModel>> getObjectivesFromLocal() async {
  final user = _auth.currentUser;
  if (user == null) return [];

  final isar = await IsarService.instance;
  final isarObjectives = await isar.isarObjectives
      .filter()
      .userIdEqualTo(user.uid)
      .findAll();

  return isarObjectives.map((o) => o.toObjectiveModel()).toList();
}

/// Busca um objetivo específico do Isar
Future<ObjectiveModel?> getObjectiveFromLocal(String objectiveId) async {
  final user = _auth.currentUser;
  if (user == null) return null;

  final isar = await IsarService.instance;
  final isarObjective = await isar.isarObjectives
      .filter()
      .objectiveIdEqualTo(objectiveId)
      .userIdEqualTo(user.uid)
      .findFirst();

  return isarObjective?.toObjectiveModel();
}

/// Deleta objetivo localmente do Isar
Future<void> deleteObjectiveLocally(String objectiveId) async {
  final user = _auth.currentUser;
  if (user == null) return;

  final isar = await IsarService.instance;
  final isarObjective = await isar.isarObjectives
      .filter()
      .objectiveIdEqualTo(objectiveId)
      .userIdEqualTo(user.uid)
      .findFirst();

  if (isarObjective != null) {
    await isar.writeTxn(() async {
      await isar.isarObjectives.delete(isarObjective.id);
    });
    print('[SYNC] 📱 Objetivo deletado localmente: $objectiveId');
  }
}
```

### 2. Shadows

```dart
/// Salva sombra localmente no Isar (modo offline-first)
Future<void> saveShadowLocally(ShadowModel shadow) async {
  final isar = await IsarService.instance;
  final online = await isOnline();

  final isarShadow = IsarShadow.fromShadowModel(
    shadow,
    isSynced: online,
    needsSync: !online,
  );

  await isar.writeTxn(() async {
    await isar.isarShadows.put(isarShadow);
  });

  if (!online) {
    print('[SYNC] 📱 Sombra salva localmente (offline): ${shadow.name}');
  }
}

/// Busca sombras do Isar (modo offline)
Future<List<ShadowModel>> getShadowsFromLocal() async {
  final user = _auth.currentUser;
  if (user == null) return [];

  final isar = await IsarService.instance;
  final isarShadows = await isar.isarShadows
      .filter()
      .userIdEqualTo(user.uid)
      .findAll();

  return isarShadows.map((s) => s.toShadowModel()).toList();
}

/// Busca uma sombra específica do Isar
Future<ShadowModel?> getShadowFromLocal(String shadowId) async {
  final user = _auth.currentUser;
  if (user == null) return null;

  final isar = await IsarService.instance;
  final isarShadow = await isar.isarShadows
      .filter()
      .shadowIdEqualTo(shadowId)
      .userIdEqualTo(user.uid)
      .findFirst();

  return isarShadow?.toShadowModel();
}
```

### 3. Trophies

```dart
/// Salva troféu localmente no Isar (modo offline-first)
Future<void> saveTrophyLocally(TrophyModel trophy) async {
  final isar = await IsarService.instance;
  final online = await isOnline();

  final isarTrophy = IsarTrophy.fromTrophyModel(
    trophy,
    isSynced: online,
    needsSync: !online,
  );

  await isar.writeTxn(() async {
    await isar.isarTrophies.put(isarTrophy);
  });

  if (!online) {
    print('[SYNC] 📱 Troféu salvo localmente (offline): ${trophy.title}');
  }
}

/// Busca troféus do Isar (modo offline)
Future<List<TrophyModel>> getTrophiesFromLocal() async {
  final user = _auth.currentUser;
  if (user == null) return [];

  final isar = await IsarService.instance;
  final isarTrophies = await isar.isarTrophies
      .filter()
      .userIdEqualTo(user.uid)
      .findAll();

  return isarTrophies.map((t) => t.toTrophyModel()).toList();
}

/// Busca um troféu específico do Isar
Future<TrophyModel?> getTrophyFromLocal(String trophyId) async {
  final user = _auth.currentUser;
  if (user == null) return null;

  final isar = await IsarService.instance;
  final isarTrophy = await isar.isarTrophies
      .filter()
      .trophyIdEqualTo(trophyId)
      .userIdEqualTo(user.uid)
      .findFirst();

  return isarTrophy?.toTrophyModel();
}
```

### 4. Tasks - Métodos auxiliares

```dart
/// Busca uma tarefa específica do Isar (modo offline)
Future<TaskModel?> getTaskFromLocal(String taskId) async {
  final user = _auth.currentUser;
  if (user == null) return null;

  final isar = await IsarService.instance;
  final isarTask = await isar.isarTasks
      .filter()
      .taskIdEqualTo(taskId)
      .userIdEqualTo(user.uid)
      .findFirst();

  return isarTask?.toTaskModel();
}

/// Deleta tarefa localmente do Isar (modo offline)
Future<void> deleteTaskLocally(String taskId) async {
  final user = _auth.currentUser;
  if (user == null) return;

  final isar = await IsarService.instance;
  final online = await isOnline();

  final isarTask = await isar.isarTasks
      .filter()
      .taskIdEqualTo(taskId)
      .userIdEqualTo(user.uid)
      .findFirst();

  if (isarTask != null) {
    await isar.writeTxn(() async {
      await isar.isarTasks.delete(isarTask.id);
    });
    
    if (online) {
      print('[SYNC] ✅ Tarefa deletada do cache local: $taskId');
    } else {
      print('[SYNC] 📱 Tarefa deletada localmente (offline): $taskId');
    }
  }
}
```

---

**Nota**: Esta é uma versão simplificada. Para implementação completa, consulte `OFFLINE_FIRST_IMPLEMENTATION.md`
