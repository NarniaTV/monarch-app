# Implementação Offline-First - Monarch Flutter

## 📋 Visão Geral

Esta implementação transforma o app Monarch em um sistema **offline-first** onde:
- **Isar é a fonte primária de dados** (todas as operações salvam primeiro aqui)
- **Firestore sincroniza em background** quando há conexão
- **Todas as operações funcionam instantaneamente offline**
- **Sincronização automática e bidirecional** quando volta online

---

## 🏗️ Arquitetura

### Fluxo de Dados:

```
┌─────────────────┐
│   UI/Widgets    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────┐
│    Services     │────▶│   Isar   │ ◀── FONTE PRIMÁRIA
└────────┬────────┘     └────┬─────┘
         │                    │
         │ (em background)    │ (sync automático)
         ▼                    ▼
┌─────────────────┐     ┌──────────┐
│  Repositories   │────▶│ Firestore│ ◀── Sincronização
└─────────────────┘     └──────────┘
```

### Princípios:

1. **Save Locally First**: Sempre salvar primeiro no Isar (retorna sucesso imediato)
2. **Sync in Background**: Sincronização com Firestore acontece em background
3. **Read from Local**: Repositories leem primeiro do Isar (instantâneo)
4. **Background Sync**: Em background, tenta sincronizar Firestore → Isar e Isar → Firestore
5. **Conflict Resolution**: Timestamp mais recente vence em caso de conflito

---

## 📝 Mudanças Necessárias

### 1. SyncService (Expandir)

Adicionar métodos para salvar localmente todas as entidades:
- ✅ `saveTaskLocally()` - já existe
- ⚠️ `saveObjectiveLocally()` - criar
- ⚠️ `saveShadowLocally()` - criar
- ⚠️ `saveTrophyLocally()` - criar
- ⚠️ `getTaskFromLocal()` - criar (já mencionado)
- ⚠️ `deleteTaskLocally()` - criar (já mencionado)

### 2. Services (Modificar)

Todos os services devem:
1. Salvar PRIMEIRO no Isar via `SyncService.save*Locally()`
2. Em background (se online), sincronizar com Firestore
3. Retornar sucesso imediatamente após salvar no Isar

**Services a modificar:**
- ✅ TaskService - parcialmente feito
- ⚠️ ObjectiveService
- ⚠️ ShadowService
- ⚠️ TrophyService
- ⚠️ PenaltyService (se necessário)

### 3. Repositories (Modificar)

Todos os repositories devem:
1. Ler PRIMEIRO do Isar via `SyncService.get*FromLocal()`
2. Retornar dados locais imediatamente
3. Em background (se online), sincronizar Firestore → Isar
4. Emitir atualização quando sincronização completar

**Repositories a modificar:**
- ⚠️ TaskRepository - criar métodos que leem do Isar primeiro
- ⚠️ ObjectiveRepository - criar métodos que leem do Isar primeiro
- ⚠️ ShadowRepository - criar métodos que leem do Isar primeiro
- ⚠️ TrophyRepository - criar métodos que leem do Isar primeiro

### 4. Sincronização Automática

- ✅ ConnectivityService - já existe
- ✅ SyncService.syncAll() - já existe
- ⚠️ Melhorar para sincronizar todas as entidades
- ⚠️ Adicionar tratamento de conflitos (timestamp)

### 5. UI/UX

- ✅ Indicador de conexão - já existe
- ⚠️ Indicador de sincronização ("Sincronizando...")
- ⚠️ Badge "Não sincronizado" em itens pendentes
- ⚠️ Feedback visual quando sincronização completa

---

## 🚀 Plano de Implementação

### Fase 1: Expandir SyncService
1. Adicionar `saveObjectiveLocally()`
2. Adicionar `saveShadowLocally()`
3. Adicionar `saveTrophyLocally()`
4. Adicionar `getTaskFromLocal()` / `getObjectiveFromLocal()` etc
5. Adicionar `deleteTaskLocally()` / `deleteObjectiveLocally()` etc
6. Melhorar `syncAll()` para sincronizar todas as entidades
7. Adicionar tratamento de conflitos baseado em timestamp

### Fase 2: Modificar Services (Offline-First)
1. TaskService - modificar `createTask()`, `updateTask()`, `completeTask()`, `deleteTask()`
2. ObjectiveService - modificar `createObjective()`, `updateObjective()`
3. ShadowService - modificar `extractShadowFromTask()`, `extractShadowFromObjective()`
4. TrophyService - modificar `createTrophyFromObjective()`

### Fase 3: Modificar Repositories (Read Local First)
1. TaskRepository - modificar métodos para ler do Isar primeiro
2. ObjectiveRepository - modificar métodos para ler do Isar primeiro
3. ShadowRepository - modificar métodos para ler do Isar primeiro
4. TrophyRepository - modificar métodos para ler do Isar primeiro

### Fase 4: UI/UX Improvements
1. Indicador de sincronização no Dashboard
2. Badge "Não sincronizado" em itens pendentes
3. Feedback visual quando sincronização completa

---

## ⚠️ Considerações Importantes

1. **Não quebrar funcionalidades existentes**: Manter toda lógica de negócio
2. **Preservar cálculos**: XP, stats, levels devem continuar funcionando
3. **Sistema de ranks**: Manter funcionalidade de ranks, shadows, trophies
4. **Performance**: Isar é rápido, então ler do Isar primeiro não deve causar problemas de performance
5. **Sincronização**: Deve acontecer em background, sem bloquear UI

---

## 📚 Referências

- SyncService atual: `lib/services/sync_service.dart`
- Isar Models: `lib/local/isar_models.dart`
- Isar Service: `lib/local/isar_service.dart`
- Connectivity Service: `lib/services/connectivity_service.dart`
