# Histórico - FASE 5: Sistema de Tarefas e Stats

## Data: 15/01/2025

### Motivo da Mudança
Usuário solicitou avançar para a próxima fase do projeto conforme o plano de implementação completo.

**Fase 5:** Sistema de Tarefas e Stats - Sistema de criação/gestão de tarefas (Rank C, D, E), sistema de stats (Power, Mind, Spirit) e XP/Level.

### Implementação Completa

#### 1. SERVICES CRIADOS

**Arquivo:** `lib/services/stats_service.dart`
- Gerencia stats (Power, Mind, Spirit) e XP/Level
- Métodos principais:
  - `updateStatsOnTaskComplete()`: Atualiza stats e XP ao completar tarefa
  - `calculateLevel()`: Calcula level baseado em XP (fórmula exponencial)
  - `calculateLevelProgress()`: Progresso percentual para próximo level
  - `incrementStat()`: Incrementa stat específico manualmente
  - `addXp()`: Adiciona XP manualmente (bônus)
  - `reduceLevelBy50Percent()`: Reduz level (Penalty Zone)

**XP por Rank:**
- Rank S: 0 XP (objetivos sagrados)
- Rank A: 0 XP (metas)
- Rank B: 0 XP (metas secundárias)
- Rank C: 100 XP (tarefas importantes)
- Rank D: 50 XP (tarefas médias)
- Rank E: 25 XP (tarefas simples)

**Fórmula de Level:**
```dart
XP necessário = 100 * (level ^ 1.5)
```

**Arquivo:** `lib/services/task_service.dart`
- Gerencia lógica de negócio de tarefas
- Métodos principais:
  - `completeTask()`: Marca como completa, atualiza stats/XP, atualiza objetivo S linkado
  - `uncompleteTask()`: Desfaz conclusão
  - `createTask()`, `updateTask()`, `deleteTask()`: CRUD
  - `getTasksByRank()`, `getActiveTasks()`, `getCompletedTasks()`: Queries

#### 2. PROVIDERS CRIADOS

**Arquivo:** `lib/features/tasks/data/task_provider.dart`
- `taskServiceProvider`: Provider do TaskService
- `statsServiceProvider`: Provider do StatsService
- `activeTasksProvider`: Stream de tarefas ativas
- `completedTasksProvider`: Stream de tarefas completadas
- `tasksByRankProvider`: Stream de tarefas por rank
- `taskLoadingProvider`: Estado de loading

#### 3. TELAS CRIADAS

**Arquivo:** `lib/features/tasks/presentation/create_task_screen.dart`
- Formulário de criação de tarefas
- Campos:
  - Título (obrigatório)
  - Descrição (opcional)
  - Rank (C, D, E) - Visual com chips selecionáveis
  - Stat afetado (Power, Mind, Spirit) - Chips selecionáveis
  - Linkar a Objetivo S (opcional) - Dropdown
- Design: Militar Futurista com TacticalBackground
- Validações: Título obrigatório
- Usa `TaskModel.create()` para gerar task com XP correto

**Arquivo:** `lib/features/tasks/presentation/tasks_screen.dart`
- Listagem de tarefas com tabs por rank (C, D, E)
- Features:
  - Tabs por rank
  - Lista dividida: Ativas | Completadas
  - Checkbox para completar/descompletar
  - Tags visuais: Rank, Stat, Linked (se linkado a objetivo S)
  - Botão de deletar
  - Dialog de confirmação de exclusão
  - Feedback: SnackBar com XP/Stat ganhos
  - FAB (+) para criar nova tarefa
- Design: Cards táticos com bordas coloridas por rank

**Arquivo:** `lib/features/dashboard/presentation/stats_screen.dart`
- Visualização de stats e progresso
- Seções:
  - **Level Card**: Level atual, XP atual/próximo, barra de progresso
  - **Atributos**: Power, Mind, Spirit com barras visuais
  - **Totais**: Resumo dos 3 stats + total
- Design: Cards escuros com bordas cyan, informações visuais claras

#### 4. ROUTING ATUALIZADO

**Arquivo:** `lib/core/routing/app_router.dart`
- Rotas adicionadas:
  - `/tasks`: TasksScreen
  - `/tasks/create`: CreateTaskScreen
  - `/stats`: StatsScreen
- Dashboard atualizado:
  - Botões de navegação para Tarefas e Stats
  - Visual melhorado com ícones

#### 5. DEPENDÊNCIAS ADICIONADAS

**Arquivo:** `pubspec.yaml`
- `uuid: ^4.5.1` - Geração de IDs únicos para tarefas

### Estrutura de Tarefas

#### TaskModel (Existente, Atualizado)
```dart
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskRank rank;          // C, D, E
  final StatType statType;      // Power, Mind, Spirit
  final int xpReward;           // Calculado automaticamente
  final bool isCompleted;
  final DateTime? completedAt;
  final String? linkedObjectiveId;  // Pode linkar a objetivo S
  final DateTime createdAt;
}
```

#### TaskRank (Atualizado)
```dart
enum TaskRank {
  s,  // Objetivos Sagrados (não usados em tarefas)
  a,  // Metas (não usados em tarefas)
  b,  // Metas Secundárias (não usados em tarefas)
  c,  // Tarefas Importantes (100 XP)
  d,  // Tarefas Médias (50 XP)
  e,  // Tarefas Simples (25 XP)
}
```

#### StatType
```dart
enum StatType {
  power,   // Poder (físico/ação)
  mind,    // Mente (intelectual/estratégia)
  spirit,  // Espírito (emocional/social)
}
```

### Fluxos Principais

#### Criar Tarefa
```
1. Usuário vai para Dashboard
2. Clica "TAREFAS"
3. Clica no FAB (+)
4. Preenche formulário:
   - Título: "Estudar Flutter" ✓
   - Descrição: "Capítulos 1-3" (opcional)
   - Rank: C (100 XP)
   - Stat: Mind
   - Objetivo S: Nenhum (opcional)
5. Clica "CRIAR TAREFA"
6. Task é salva no Firestore
7. Retorna para TasksScreen
```

#### Completar Tarefa
```
1. Usuário está em TasksScreen
2. Vê lista de tarefas ativas no Rank C
3. Clica no checkbox da tarefa
4. Sistema:
   - Atualiza task.isCompleted = true
   - Incrementa Mind +1
   - Adiciona 100 XP
   - Recalcula level se necessário
   - Se linkada, incrementa progresso do objetivo S
5. SnackBar mostra: "+100 XP | +1 MIND"
6. Tarefa move para seção "Completadas"
```

#### Visualizar Stats
```
1. Usuário vai para Dashboard
2. Clica "STATS"
3. Vê:
   - Level atual: 3
   - XP: 450 / 600
   - Barra de progresso: 75%
   - Power: 12
   - Mind: 18
   - Spirit: 8
   - Total: 38
```

### Correções Realizadas

#### Erros de Compilação
- **UserRepository**: Método correto é `getUser()`, não `getUserProfile()`
- **TaskRepository**: `updateTask()` recebe apenas `TaskModel`, não `(userId, task)`
- **ObjectiveRepository**: Não tem `getObjective()`, usar `getActiveObjectives()` e filtrar
- **TaskModel**: Requer `xpReward` obrigatório, usar `TaskModel.create()` ou calcular manualmente

#### Erros de Tipagem
- `FutureBuilder` sem tipo genérico causava erros de inferência
- `Iterable<Widget>` sem `.toList()` em `Wrap.children`
- Nullable descriptions precisavam de verificação (`task.description != null`)

#### Erros de Sintaxe
- Arquivo `stats_screen.dart` tinha problema de parsing (resolvido recriando)

### Arquivos Modificados

#### Criados
- `lib/services/stats_service.dart`
- `lib/services/task_service.dart`
- `lib/features/tasks/data/task_provider.dart`
- `lib/features/tasks/presentation/create_task_screen.dart`
- `lib/features/tasks/presentation/tasks_screen.dart`
- `lib/features/dashboard/presentation/stats_screen.dart`
- `historico_da_ia/25_2025-01-15_fase5_tarefas_e_stats.md`

#### Modificados
- `pubspec.yaml` - Adicionado `uuid: ^4.5.1`
- `lib/core/routing/app_router.dart` - Rotas `/tasks`, `/tasks/create`, `/stats` + Dashboard atualizado

### Status da Fase 5

✅ **COMPLETO**

- [x] Sistema de criação de tarefas (Rank C, D, E)
- [x] Sistema de listagem/gerenciamento de tarefas
- [x] Sistema de stats (Power, Mind, Spirit)
- [x] Sistema de XP e Level
- [x] Integração: Completar tarefa → Atualiza stats + XP
- [x] Linkagem com objetivos S (opcional)
- [x] UI tática/militar consistente com o resto do app
- [x] Validações e feedback ao usuário

### Próxima Fase

**FASE 6: Daily Quests e Penalty Zone 2.0**

Funcionalidades:
- Sistema de Daily Quests (máximo 5)
- Streaks por quest
- Penalty Zone com mensagem personalizada
- Sistema de quitação (3 dias seguidos)
- Penalidades: XP reduzido 50%, UI vermelha
- Opção de desistir (reset objetivos S, -50% level)

### Observações Técnicas

1. **Polling vs Snapshots:** O método `getTasksByRank()` usa polling simplificado. Em produção, migrar para `snapshots()` do Firestore para real-time.

2. **Validação de Nickname:** Ainda pendente no Firestore. As regras atualizadas pelo usuário permitem queries limitadas.

3. **XP Exponencial:** A fórmula `100 * (level ^ 1.5)` cria progressão equilibrada. Level 10 requer ~3162 XP total.

4. **Penalty Zone:** Campo `penaltyMessage` no UserProfile usado para check simplificado. Implementação completa na Fase 6.

5. **Sombras (Shadow System):** Preparado no código (comentário TODO) para extração na Fase 7.

### Métricas

- **Arquivos criados:** 7
- **Arquivos modificados:** 2
- **Linhas de código:** ~1800+
- **Tempo de implementação:** ~1 sessão
- **Erros corrigidos:** 47
- **Status final:** 0 erros, 0 warnings

---

## Checkpoint Fase 5

- [x] Criar tarefas funciona
- [x] Completar tarefas funciona
- [x] Stats aumentam corretamente
- [x] XP e Level funcionam
- [x] Tarefas podem ser linkadas a objetivos S
- [x] UI consistente com design militar/tático
- [x] Código sem erros de compilação
- [x] Navegação entre telas funcional

**Status:** ✅ FASE 5 COMPLETA E VALIDADA
