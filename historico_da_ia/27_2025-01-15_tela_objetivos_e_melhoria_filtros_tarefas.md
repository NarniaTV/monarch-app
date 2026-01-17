# Histórico - Tela de Objetivos S + Melhorias na Tela de Tarefas

## Data: 15/01/2025

### Motivo da Mudança
Usuário solicitou:
1. **Criar tela para gerenciar Objetivos S** (não apenas tarefas)
2. **Melhorar visualização de tarefas**: Mostrar TODAS as tarefas por padrão (em vez de separadas por rank), com filtros opcionais por rank (E, D, C)

### Problema Anterior

**Objetivos S:**
- Não havia tela dedicada para gerenciar objetivos S
- Usuário só via os objetivos no Dashboard
- Não havia forma de criar, editar ou deletar objetivos pela UI

**Tarefas:**
- A tela mostrava tarefas separadas por **TABS** de rank (C, D, E)
- Usuário tinha que navegar entre tabs para ver tarefas de ranks diferentes
- Não havia visão geral de todas as tarefas juntas
- Sistema de filtros era obrigatório (tabs), não opcional

### Solução Implementada

## 1. NOVA TELA DE OBJETIVOS S

### Arquivo Criado: `lib/features/objectives/presentation/objectives_screen.dart`

**Design:** Tactical HUD com padrão militar futurista, tema dourado (Rank S)

#### Estrutura da Tela

```
┌─────────────────────────────────────────┐
│ [← Back] // OBJETIVOS_SAGRADOS          │
│          RANK S              [MAX: 3]   │
│ Seus objetivos mais importantes...      │
├─────────────────────────────────────────┤
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🏁 Ser fluente em inglês      [X]   │ │
│ │ Descrição do objetivo...            │ │
│ │ ─────────────────────────────────── │ │
│ │ PROGRESSO              75%          │ │
│ │ [===========════════════]            │ │
│ │ ⏰ Criado em 15/01/2025              │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🏁 Dominar Flutter            [X]   │ │
│ │ ─────────────────────────────────── │ │
│ │ PROGRESSO              50%          │ │
│ │ [======════════════════]             │ │
│ └─────────────────────────────────────┘ │
│                                         │
│           [+ NOVO OBJETIVO] (FAB)       │
└─────────────────────────────────────────┘
```

#### Componentes Principais

**1. Header:**
- Botão de voltar
- Micro-data: `// OBJETIVOS_SAGRADOS`
- Título: `RANK S` (Orbitron, dourado, bold)
- Badge: `MAX: 3` (indica limite)
- Descrição explicativa

**2. Lista de Objetivos (StreamBuilder):**
- Atualização em tempo real via `StreamBuilder`
- Cards com:
  - Ícone de flag dourado
  - Título e descrição
  - Barra de progresso visual (0-100%)
  - Data de criação
  - Botão de deletar (IconButton vermelho)

**3. Empty State:**
```
🏁
NENHUM OBJETIVO ATIVO
Defina seus objetivos sagrados para começar sua jornada.
```

**4. FAB (Floating Action Button):**
- Label: `NOVO OBJETIVO` (quando < 3 objetivos)
- Label: `LIMITE ATINGIDO` (quando = 3 objetivos)
- Background dourado (ativo) ou cinza (limite)
- Navega para `/objectives/create`

**5. Diálogos:**

**Delete Dialog:**
```
EXCLUIR OBJETIVO
Tem certeza que deseja excluir "Título"? 
Esta ação não pode ser desfeita.

[CANCELAR]  [EXCLUIR]
```

**Limit Dialog:**
```
LIMITE ATINGIDO
Você já possui 3 objetivos S ativos. 
Exclua um objetivo existente para criar um novo.

[ENTENDI]
```

#### Funcionalidades

1. **Visualização em Tempo Real:**
   ```dart
   StreamBuilder<List<ObjectiveModel>>(
     stream: _objectiveRepository.getActiveObjectivesStream(userId),
     ...
   )
   ```

2. **Navegação:**
   - `/objectives` - Tela principal
   - `/objectives/create` - Criar novo objetivo

3. **CRUD:**
   - ✅ CREATE: Via FAB (se < 3 objetivos)
   - ✅ READ: Stream em tempo real
   - ❌ UPDATE: Não implementado (pode adicionar depois)
   - ✅ DELETE: Via IconButton com confirmação

4. **Validações:**
   - Máximo de 3 objetivos ativos
   - Confirmação antes de deletar
   - Feedback via SnackBar

---

## 2. TELA DE CRIAÇÃO DE OBJETIVOS

### Arquivo Criado: `lib/features/objectives/presentation/create_objective_screen.dart`

**Design:** Militar futurista, formulário limpo e direto

#### Estrutura da Tela

```
┌─────────────────────────────────────────┐
│ [← Back] // CRIAR_OBJETIVO_S            │
│          NOVO OBJETIVO                  │
├─────────────────────────────────────────┤
│                                         │
│ ℹ️ Objetivos S são suas metas mais     │
│    importantes. Máximo 3 ativos.       │
│                                         │
│ TÍTULO                                  │
│ ┌─────────────────────────────────────┐ │
│ │ Ex: Ser fluente em inglês           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ DESCRIÇÃO (OPCIONAL)                    │
│ ┌─────────────────────────────────────┐ │
│ │ Detalhes sobre seu objetivo...      │ │
│ │                                     │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [      CRIAR OBJETIVO      ]            │
└─────────────────────────────────────────┘
```

#### Campos do Formulário

**1. Info Card (topo):**
- Ícone de informação
- Texto explicativo sobre objetivos S
- Background dourado translúcido

**2. Campo Título (obrigatório):**
- Placeholder: "Ex: Ser fluente em inglês"
- Validação: 
  - Não vazio
  - Mínimo 3 caracteres
- Tipografia: Orbitron
- Background: `#1A1D24` (escuro)
- Borda: Dourada

**3. Campo Descrição (opcional):**
- Placeholder: "Detalhes sobre seu objetivo..."
- Multiline (4 linhas)
- Tipografia: Share Tech Mono
- Mesmo estilo visual do título

**4. Botão Criar:**
- Full width
- Background dourado
- Texto preto bold: "CRIAR OBJETIVO"
- Loading indicator ao processar
- BeveledRectangleBorder (cantos chanfrados)

#### Lógica de Criação

```dart
final objective = ObjectiveModel(
  id: Uuid().v4(),
  userId: currentUser.uid,
  title: titleController.text.trim(),
  description: descriptionController.text.trim().isEmpty 
      ? null 
      : descriptionController.text.trim(),
  createdAt: DateTime.now(),
  progress: 0,
);

await objectiveService.createObjective(objective);
```

#### Validações

1. **Título obrigatório:** Mínimo 3 caracteres
2. **Descrição opcional:** Pode ficar vazia
3. **Limite de 3:** Verificado no repository

#### Feedback

- **Sucesso:** SnackBar verde + navegação de volta
- **Erro:** SnackBar vermelho + mensagem de erro

---

## 3. SERVICE PARA OBJETIVOS

### Arquivo Criado: `lib/services/objective_service.dart`

**Camada de serviço** para lógica de negócio de objetivos.

#### Métodos Implementados

```dart
class ObjectiveService {
  final ObjectiveRepository _objectiveRepository;

  // CREATE
  Future<void> createObjective(ObjectiveModel objective);
  
  // READ
  Future<List<ObjectiveModel>> getActiveObjectives(String userId);
  Stream<List<ObjectiveModel>> getActiveObjectivesStream(String userId);
  
  // UPDATE
  Future<void> updateObjective(ObjectiveModel objective);
  
  // DELETE
  Future<void> deleteObjective(String userId, String objectiveId);
}
```

#### Padrão Arquitetural

```
UI (Screen/Widget)
     ↓
ObjectiveService (Lógica de negócio)
     ↓
ObjectiveRepository (Acesso ao Firestore)
     ↓
Firestore Database
```

**Vantagens:**
- Separa lógica de negócio da UI
- Facilita testes
- Centraliza validações e regras
- Reutilizável entre diferentes UIs

---

## 4. REFATORAÇÃO DA TELA DE TAREFAS

### Arquivo Modificado: `lib/features/tasks/presentation/tasks_screen.dart`

#### ANTES (Com Tabs)

```
┌─────────────────────────────────────┐
│ TAREFAS                             │
├─────────────────────────────────────┤
│ [TAB C] [TAB D] [TAB E]             │ ← Tabs obrigatórias
├─────────────────────────────────────┤
│ Conteúdo do Rank C                  │
│ • Tarefa 1                          │
│ • Tarefa 2                          │
└─────────────────────────────────────┘
```

**Problemas:**
- Usuário DEVE escolher um tab
- Não vê todas as tarefas de uma vez
- Navegação fragmentada

#### DEPOIS (Com Filtros Opcionais)

```
┌─────────────────────────────────────┐
│ TAREFAS                             │
├─────────────────────────────────────┤
│ FILTROS:                            │
│ [TODAS] [RANK C] [RANK D] [RANK E]  │ ← Chips opcionais
├─────────────────────────────────────┤
│ ┌─ ATIVAS (5) ─────────────────┐   │
│ │ ⭕ Tarefa C1    [RANK C]      │   │
│ │ ⭕ Tarefa D1    [RANK D]      │   │
│ │ ⭕ Tarefa E1    [RANK E]      │   │
│ │ ⭕ Tarefa C2    [RANK C]      │   │
│ │ ⭕ Tarefa D2    [RANK D]      │   │
│ └──────────────────────────────┘   │
│                                     │
│ ┌─ CONCLUÍDAS (2) ─────────────┐   │
│ │ ✅ Tarefa E2    [RANK E]      │   │
│ │ ✅ Tarefa D3    [RANK D]      │   │
│ └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Melhorias:**
- ✅ Mostra TODAS as tarefas por padrão
- ✅ Filtros são **opcionais** (chips clicáveis)
- ✅ Visão geral completa
- ✅ Seções "ATIVAS" e "CONCLUÍDAS" sempre visíveis

#### Nova Estrutura

**1. Header:**
- Botão de voltar
- Micro-data: `// GERENCIADOR_DE_TAREFAS`
- Título: `TAREFAS`

**2. Filtros (Chips):**
```dart
Wrap(
  spacing: 8,
  children: [
    FilterChip('TODAS', selected: filter == null),
    FilterChip('RANK C', selected: filter == TaskRank.c),
    FilterChip('RANK D', selected: filter == TaskRank.d),
    FilterChip('RANK E', selected: filter == TaskRank.e),
  ],
)
```

**Design dos Chips:**
- **Selecionado:** 
  - Background colorido translúcido
  - Borda 2px da cor do rank
  - Texto bold
- **Não selecionado:**
  - Background transparente
  - Borda 1px translúcida
  - Texto normal

**3. Lista de Tarefas:**

Duas seções sempre visíveis (se houver tarefas):

```dart
// Seção ATIVAS
_buildSectionHeader('ATIVAS', count)
...tasks.map(_buildTaskCard)

// Seção CONCLUÍDAS  
_buildSectionHeader('CONCLUÍDAS', count)
...tasks.map(_buildTaskCard)
```

**4. Cards de Tarefa:**

Mantém o mesmo design anterior:
- Checkbox circular
- Título + descrição
- Tags (Rank, Stat, XP)
- Botão deletar

**5. Empty State:**

Mensagens contextuais:
- **Sem filtro:** "Nenhuma tarefa cadastrada"
- **Com filtro:** "Nenhuma tarefa encontrada para este filtro"

#### Lógica de Filtro

```dart
TaskRank? _selectedRankFilter; // null = todas

// Aplicar filtro
final filteredActive = _selectedRankFilter == null
    ? activeTasks
    : activeTasks.where((t) => t.rank == _selectedRankFilter).toList();

final filteredCompleted = _selectedRankFilter == null
    ? completedTasks
    : completedTasks.where((t) => t.rank == _selectedRankFilter).toList();
```

**Estado do Filtro:**
- `null` → Mostra TODAS as tarefas
- `TaskRank.c` → Mostra apenas Rank C
- `TaskRank.d` → Mostra apenas Rank D
- `TaskRank.e` → Mostra apenas Rank E

---

## 5. ROTAS E NAVEGAÇÃO

### Modificado: `lib/core/routing/app_router.dart`

#### Novas Rotas Adicionadas

```dart
GoRoute(
  path: '/objectives',
  builder: (context, state) => const ObjectivesScreen(),
),
GoRoute(
  path: '/objectives/create',
  builder: (context, state) => const CreateObjectiveScreen(),
),
```

#### Imports Adicionados

```dart
import '../../features/objectives/presentation/objectives_screen.dart';
import '../../features/objectives/presentation/create_objective_screen.dart';
```

#### Estrutura de Rotas (Completa)

```
/                           → DashboardScreen
/login                      → LoginScreen
/register                   → RegisterScreen
/onboarding                 → OnboardingScreen
/tasks                      → TasksScreen
/tasks/create               → CreateTaskScreen
/objectives                 → ObjectivesScreen (NOVO)
/objectives/create          → CreateObjectiveScreen (NOVO)
/stats                      → StatsScreen
```

---

## 6. ATUALIZAÇÃO DO DASHBOARD

### Modificado: `lib/features/dashboard/presentation/dashboard_screen.dart`

#### ANTES (2 Botões)

```
┌─ AÇÕES RÁPIDAS ──────────┐
│ [TAREFAS]    [STATS]     │
└──────────────────────────┘
```

#### DEPOIS (3 Botões)

```
┌─ AÇÕES RÁPIDAS ──────────┐
│ [OBJETIVOS]  [TAREFAS]   │
│ [STATS]                  │
└──────────────────────────┘
```

#### Novo Botão de Objetivos

```dart
_buildActionButton(
  'OBJETIVOS',
  Icons.flag,
  AppColors.rankS,  // Dourado
  () => context.push('/objectives'),
)
```

**Layout:**
- Grid 2 colunas (primeira linha)
- Grid 1 coluna (segunda linha, stats)
- Cores distintas:
  - Objetivos: Dourado (Rank S)
  - Tarefas: Cyan
  - Stats: Cyan

---

## 7. COMPARAÇÃO: ANTES vs DEPOIS

### Objetivos S

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Visualização** | Apenas no Dashboard | Tela dedicada completa |
| **Criação** | Via Onboarding (1x) | Qualquer momento (limite 3) |
| **Edição** | Não disponível | Deletar + recriar |
| **Exclusão** | Não disponível | Sim, com confirmação |
| **Progresso** | Visível no Dashboard | Visível em detalhes |
| **Limite** | 3 fixo | 3 com validação ativa |

### Tarefas

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Visualização Padrão** | Separadas por tabs | TODAS juntas |
| **Filtros** | Obrigatórios (tabs) | Opcionais (chips) |
| **Navegação** | Entre tabs | Scroll contínuo |
| **Visão Geral** | Não disponível | Sim (padrão) |
| **Organização** | Por rank apenas | Por status (ativas/concluídas) + filtro opcional |
| **UX** | Fragmentada | Unificada |

### Navegação Geral

```
ANTES:
Dashboard → Tarefas (separadas)
Dashboard → Stats

DEPOIS:
Dashboard → Objetivos → Criar Objetivo
Dashboard → Tarefas (todas + filtros opcionais)
Dashboard → Stats
```

---

## 8. ARQUIVOS MODIFICADOS/CRIADOS

### Criados

1. **`lib/services/objective_service.dart`**
   - Service para lógica de objetivos
   - CRUD completo
   - Validações centralizadas

2. **`lib/features/objectives/presentation/objectives_screen.dart`**
   - Tela principal de objetivos
   - Lista com StreamBuilder
   - FAB condicional
   - Diálogos de confirmação

3. **`lib/features/objectives/presentation/create_objective_screen.dart`**
   - Formulário de criação
   - Validações inline
   - Loading states
   - Feedback visual

4. **`historico_da_ia/27_2025-01-15_tela_objetivos_e_melhoria_filtros_tarefas.md`**
   - Esta documentação

### Modificados

1. **`lib/core/routing/app_router.dart`**
   - Adicionadas rotas `/objectives` e `/objectives/create`
   - Imports das novas telas

2. **`lib/features/tasks/presentation/tasks_screen.dart`**
   - Removidas tabs (TabBar/TabBarView)
   - Adicionados chips de filtro
   - Lógica de filtro opcional
   - Mostra todas as tarefas por padrão
   - Corrigidas assinaturas de métodos do TaskService

3. **`lib/features/dashboard/presentation/dashboard_screen.dart`**
   - Adicionado botão "OBJETIVOS" nas ações rápidas
   - Layout ajustado (2+1 botões)

4. **`historico_da_ia/README.md`**
   - Adicionada entrada para histórico 27

---

## 9. EXPERIÊNCIA DO USUÁRIO

### Fluxo: Gerenciar Objetivos S

```
1. Dashboard
   ↓ [Clica em "OBJETIVOS"]
2. ObjectivesScreen (lista de 0-3 objetivos)
   ↓ [Clica em FAB "NOVO OBJETIVO"]
3. CreateObjectiveScreen (formulário)
   ↓ [Preenche e clica "CRIAR OBJETIVO"]
4. Volta para ObjectivesScreen
   ✅ SnackBar: "Objetivo S criado com sucesso!"
   ✅ Lista atualiza automaticamente (Stream)
```

### Fluxo: Visualizar Todas as Tarefas

```
1. Dashboard
   ↓ [Clica em "TAREFAS"]
2. TasksScreen (TODAS as tarefas visíveis)
   - Vê tarefas C, D, E juntas
   - Ativas e concluídas separadas
   ↓ [Opcional: Clica em chip "RANK C"]
3. Lista filtra apenas Rank C
   ↓ [Clica em chip "TODAS"]
4. Volta a mostrar todas
```

### Fluxo: Criar Objetivo + Criar Tarefa Linkada

```
1. ObjectivesScreen → Cria "Ser fluente em inglês"
2. TasksScreen → Cria nova tarefa
3. CreateTaskScreen → Seleciona objetivo no dropdown
4. Tarefa fica linkada ao objetivo
5. Ao completar tarefa → Progresso do objetivo aumenta
```

---

## 10. ASPECTOS TÉCNICOS

### StreamBuilder vs FutureBuilder

**Objetivos:** Usa `StreamBuilder`
```dart
StreamBuilder<List<ObjectiveModel>>(
  stream: _objectiveRepository.getActiveObjectivesStream(userId),
  builder: (context, snapshot) { ... }
)
```

**Vantagens:**
- Atualização em tempo real
- Sem necessidade de refresh manual
- Sincronização automática com Firestore

**Tarefas:** Usa Riverpod `StreamProvider`
```dart
final activeTasksAsync = ref.watch(activeTasksProvider);
activeTasksAsync.when(
  loading: () => ...,
  error: (e, s) => ...,
  data: (tasks) => ...,
)
```

**Vantagens:**
- Gerenciamento de estado global
- Cache automático
- Rebuilds otimizados

### State Management

**Filtro de Tarefas:**
```dart
TaskRank? _selectedRankFilter; // Estado local (StatefulWidget)

setState(() => _selectedRankFilter = TaskRank.c);
```

**Por que local?**
- Filtro é específico da tela
- Não precisa persistir
- Não é compartilhado com outras telas

### Validações

**Client-side (UI):**
- Título não vazio (objetivos)
- Mínimo 3 caracteres (objetivos)
- Limite de 3 objetivos (FAB desabilitado)

**Server-side (Service/Repository):**
- Verifica limite no Firestore
- Autenticação do usuário
- Tratamento de exceções

### Navegação

**Push vs Go:**
```dart
context.push('/objectives/create')  // Push (mantém stack)
context.pop()                       // Volta
```

**Quando usar cada:**
- `push`: Navegação forward (criar, editar)
- `pop`: Navegação back
- `go`: Navegação direta/substituição

---

## 11. FEEDBACK VISUAL

### SnackBars

**Sucesso (Verde):**
- Objetivo criado
- Objetivo deletado
- Tarefa concluída
- Tarefa deletada

**Erro (Vermelho):**
- Erro ao criar/deletar
- Erro ao carregar
- Falha de autenticação

### Diálogos

**Confirmação:**
- Deletar objetivo
- Deletar tarefa

**Informação:**
- Limite de objetivos atingido

### Loading States

**CircularProgressIndicator:**
- Ao carregar listas (Stream)
- Ao processar criação (botão)

**Desabilitar botões:**
- Durante loading (evita duplo-clique)
- Quando limite atingido (FAB)

---

## 12. STATUS FINAL

✅ **Compilação:** 0 erros  
⚠️ **Análise:** 4 info (use_build_context_synchronously - não crítico)  
✅ **Funcionalidade:** Completa  
✅ **Design:** Consistente com resto do app  
✅ **Documentação:** Completa  
✅ **Testes Manuais:** Necessários (usuário deve testar)

---

## 13. PRÓXIMOS PASSOS POSSÍVEIS (NÃO IMPLEMENTADOS)

### Objetivos S
1. **Edição de objetivos:** Tela de edição (título, descrição, progresso manual)
2. **Deadline:** Campo de data limite + notificações
3. **Categorias:** Tags para categorizar objetivos (saúde, carreira, etc.)
4. **Conclusão:** Modal especial ao atingir 100% (comemoração)
5. **Histórico:** Ver objetivos completados

### Tarefas
1. **Ordenação:** Por data, prioridade, XP
2. **Busca:** Campo de busca por título/descrição
3. **Edição rápida:** Editar título inline
4. **Arrastar para reordenar:** Drag & drop
5. **Multi-seleção:** Completar/deletar múltiplas de uma vez

### Geral
1. **Animações:** Transições suaves entre telas
2. **Onboarding:** Tutorial de como criar objetivos/tarefas
3. **Backup:** Exportar/importar objetivos e tarefas
4. **Compartilhar:** Compartilhar objetivos com amigos

---

## 14. OBSERVAÇÕES FINAIS

1. **Design Consistency:** Todas as telas seguem o mesmo padrão "Militar Futurista / Tactical HUD"

2. **Code Quality:** 
   - Código modular e reutilizável
   - Separação de responsabilidades (Service/Repository/UI)
   - Tratamento de erros adequado

3. **User Experience:**
   - Fluxo intuitivo
   - Feedback visual claro
   - Validações client e server-side
   - Estados vazios informativos

4. **Performance:**
   - Streams para atualização em tempo real
   - Filtros locais (não requer query ao Firestore)
   - Cache via Riverpod

5. **Scalability:**
   - Fácil adicionar novos tipos de objetivos
   - Sistema de filtros extensível
   - Arquitetura pronta para novas features

**Resultado:** Sistema completo de gerenciamento de Objetivos S + melhorias significativas na visualização de tarefas! 🎯✅
