# 📋 Resumo: Implementação Offline-First Monarch

## 🎯 Objetivo

Implementar modo **offline-first** onde:
- **Isar é a fonte primária** (todas operações salvam primeiro aqui)
- **Firestore sincroniza em background** quando há conexão
- **Todas operações funcionam instantaneamente offline**

---

## ✅ Status Atual vs Status Desejado

### Status Atual:
- ✅ SyncService existe com métodos básicos
- ✅ Isar models existem (IsarTask, IsarObjective, IsarShadow, IsarTrophy)
- ✅ TaskService já tem algumas operações offline
- ❌ **Services não salvam PRIMEIRO no Isar** - ainda tentam Firestore primeiro
- ❌ **Repositories não leem PRIMEIRO do Isar** - ainda leem Firestore primeiro
- ❌ **Outras entidades não têm suporte offline completo**

### Status Desejado:
- ✅ **Todos Services salvam PRIMEIRO no Isar** (retorna sucesso imediato)
- ✅ **Todos Repositories leem PRIMEIRO do Isar** (mostra dados instantaneamente)
- ✅ **Sincronização em background** quando online
- ✅ **Tratamento de conflitos** (timestamp mais recente vence)

---

## 📊 Escopo da Implementação

### Arquivos a Modificar (Prioridade Alta):

1. **lib/services/sync_service.dart** (~300 linhas → ~800 linhas)
   - Adicionar métodos para salvar localmente todas entidades
   - Adicionar métodos para buscar do local todas entidades
   - Melhorar sincronização bidirecional com conflito resolution

2. **lib/services/task_service.dart** (~500 linhas)
   - Modificar `createTask()` - já parcialmente feito
   - Modificar `updateTask()` - precisa salvar primeiro no Isar
   - Modificar `completeTask()` - precisa salvar primeiro no Isar
   - Modificar `deleteTask()` - precisa salvar primeiro no Isar

3. **lib/services/objective_service.dart**
   - Modificar `createObjective()` - salvar primeiro no Isar
   - Modificar `updateObjective()` - salvar primeiro no Isar

4. **lib/services/shadow_service.dart**
   - Modificar `extractShadowFromTask()` - salvar primeiro no Isar
   - Modificar `extractShadowFromObjective()` - salvar primeiro no Isar

5. **lib/services/trophy_service.dart**
   - Modificar `createTrophyFromObjective()` - salvar primeiro no Isar

6. **lib/repositories/task_repository.dart** (~230 linhas)
   - Modificar `getTasks()` - ler primeiro do Isar
   - Modificar `getTasksStream()` - ler primeiro do Isar, sincronizar em background
   - Manter métodos Firestore para sincronização

7. **lib/repositories/objective_repository.dart**
   - Modificar métodos para ler primeiro do Isar

8. **lib/repositories/shadow_repository.dart**
   - Modificar métodos para ler primeiro do Isar

9. **lib/repositories/trophy_repository.dart**
   - Modificar métodos para ler primeiro do Isar

### Arquivos Adicionais (Prioridade Média):

10. **UI Indicators** (Dashboard)
    - Indicador de sincronização ("Sincronizando...")
    - Badge "Não sincronizado" em itens pendentes

---

## 🚀 Estratégia de Implementação Recomendada

### Opção 1: Implementação Completa (Recomendada)
- Implementar todas as mudanças de uma vez
- Garantir que tudo funcione offline-first
- **Tempo estimado**: 2-3 horas
- **Risco**: Médio (mudanças extensas)

### Opção 2: Implementação Gradual (Mais Segura)
- Fase 1: Expandir SyncService (30 min)
- Fase 2: Modificar TaskService (45 min)
- Fase 3: Modificar ObjectiveService (30 min)
- Fase 4: Modificar ShadowService + TrophyService (30 min)
- Fase 5: Modificar Repositories (1 hora)
- Fase 6: UI Indicators (30 min)
- **Tempo total**: ~4 horas
- **Risco**: Baixo (mudanças incrementais)

---

## ⚠️ Riscos e Considerações

1. **Tamanho da Implementação**: ~2000-3000 linhas de código modificado
2. **Complexidade**: Mudanças em múltiplos arquivos interdependentes
3. **Testes**: Necessário testar offline e online para cada operação
4. **Conflitos**: Tratamento de conflitos precisa ser cuidadoso

---

## 💡 Recomendação

**Implementação Gradual (Opção 2)** é mais segura e permite testes incrementais.

Cada fase pode ser testada independentemente antes de prosseguir para a próxima.

---

## 📝 Próximos Passos

1. Confirme qual abordagem prefere (Completa ou Gradual)
2. Começarei pela Fase 1 (Expandir SyncService)
3. Testaremos cada fase antes de prosseguir
4. Documentaremos todas as mudanças

---

**Aguardando confirmação para iniciar implementação.**
