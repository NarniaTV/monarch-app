# Correções Críticas - Modo Offline

## Data: 15/01/2025

### Problemas Reportados

1. ❌ Não conseguia criar tarefas offline
2. ❌ Tarefas não apareciam quando offline
3. ❌ Erros do Firestore: "Unable to resolve host firestore.googleapis.com"

---

## 🔧 Correções Implementadas

### 1. TaskService.createTask() - Modo Offline

**Problema:** Tentava criar no Firestore primeiro, falhava quando offline.

**Solução:**
- ✅ Verifica conectividade **antes** de tentar criar no Firestore
- ✅ Se offline: cria apenas no Isar (marca `needsSync: true`)
- ✅ Se online: cria no Firestore + salva no Isar (cache)

**Código:**
```dart
if (isOnline) {
  // Cria no Firestore primeiro
  final createdTask = await _taskRepository.createTask(task);
  await _syncService.saveTaskLocally(createdTask);
} else {
  // Offline: cria apenas no Isar
  final taskWithId = task.id.isEmpty 
      ? task.copyWith(id: const Uuid().v4())
      : task;
  await _syncService.saveTaskLocally(taskWithId);
}
```

---

### 2. TaskService.getActiveTasks() - Stream Offline

**Problema:** Stream do Firestore falhava e não emitia nada quando offline.

**Solução:**
- ✅ Verifica conectividade antes de tentar stream
- ✅ Se offline: usa dados do Isar + polling a cada 3 segundos
- ✅ Se stream falhar: fallback automático para dados locais
- ✅ Polling controlado (para após 100 iterações ou quando voltar online)

**Código:**
```dart
if (isOnline) {
  // Stream do Firestore + cache no Isar
  await for (final tasks in _taskRepository.getTasksStream(user.uid)) {
    // ...
  }
} else {
  // Offline: dados locais + polling
  final localTasks = await _syncService.getTasksFromLocal();
  yield localTasks.where((t) => !t.isCompleted).toList();
  
  // Polling controlado
  await for (final _ in Stream.periodic(Duration(seconds: 3)).take(100)) {
    // ...
  }
}
```

---

### 3. Dashboard - Fallback para Dados Locais

**Problema:** Quando stream falhava, mostrava apenas erro.

**Solução:**
- ✅ Tratamento de erro melhorado
- ✅ Fallback automático: busca do Isar se stream falhar
- ✅ Método `_buildTasksList()` criado para reutilização

**Código:**
```dart
error: (error, stack) {
  // Fallback para dados locais
  return FutureBuilder<List<TaskModel>>(
    future: _syncService.getTasksFromLocal(),
    builder: (context, snapshot) {
      // Mostra tarefas locais
    },
  );
}
```

---

### 4. SyncService - Criar Tarefas no Firestore

**Problema:** Ao sincronizar, tentava apenas atualizar, não criava tarefas novas.

**Solução:**
- ✅ Tenta atualizar primeiro (se já existe)
- ✅ Se falhar, cria no Firestore com ID específico
- ✅ Usa `Firestore.set()` com ID específico em vez de `.add()`

**Código:**
```dart
try {
  await _taskRepository.updateTask(taskModel);
} catch (updateError) {
  // Se não existe, cria
  await firestore
      .collection('users')
      .doc(userId)
      .collection('tasks')
      .doc(isarTask.taskId)
      .set(taskModel.toFirestore());
}
```

---

### 5. UI - Indicador de Status Dinâmico

**Problema:** Indicador "ONLINE" estava fixo no AppBar.

**Solução:**
- ✅ AppBar mostra "ONLINE" ou "OFFLINE" dinamicamente
- ✅ Cores mudam: Verde (online) / Laranja (offline)
- ✅ Indicador "MODO OFFLINE" aparece no Dashboard quando offline

---

### 6. Mensagens de Feedback

**Problema:** Não havia feedback quando criava tarefa offline.

**Solução:**
- ✅ SnackBar mostra: "Tarefa salva localmente! Será sincronizada ao reconectar."
- ✅ Cor diferente: Laranja quando offline, Ciano quando online

---

## ✅ Teste Rápido

1. **Desative internet**
2. **Aguarde 5-10 segundos**
3. **Verifique:**
   - ✅ Indicador "OFFLINE" no AppBar (laranja)
   - ✅ Banner "MODO OFFLINE" no Dashboard
4. **Crie uma tarefa:**
   - ✅ Deve aparecer mensagem: "Tarefa salva localmente!"
   - ✅ Tarefa deve aparecer no Dashboard imediatamente
5. **Reative internet:**
   - ✅ Aguarde 5-10 segundos
   - ✅ Deve sincronizar automaticamente
   - ✅ Tarefa deve aparecer no Firestore

---

## 📝 Logs Esperados

### Ao criar tarefa offline:
```
[TASK SERVICE] Criando tarefa offline: NomeDaTarefa
[SYNC] 📱 Tarefa salva localmente (offline): NomeDaTarefa
[TASK SERVICE] ✅ Tarefa criada offline e salva localmente: NomeDaTarefa
```

### Ao ver tarefas offline:
```
[TASK SERVICE] Offline - usando dados locais do Isar
[TASK SERVICE] ✅ X tarefas ativas encontradas localmente
```

### Ao reconectar:
```
[CONNECTIVITY] ✅ Conexão restabelecida - sincronizando...
[SYNC] ✅ Tarefa criada no Firestore: NomeDaTarefa
[SYNC] ✅ Tarefa offline sincronizada: NomeDaTarefa
```

---

**Todas as correções foram aplicadas!** 🚀

Teste seguindo o `TESTE_MODO_OFFLINE.md`.
