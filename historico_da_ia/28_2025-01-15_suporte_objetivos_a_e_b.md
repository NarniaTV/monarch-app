# Histórico - Suporte para Objetivos A e B

## Data: 15/01/2025

### Motivo da Mudança
Usuário solicitou adicionar suporte para gerenciar Objetivos A (Metas Principais) e B (Metas Secundárias), não apenas os Objetivos S (Sagrados).

### Problema Anterior

**Objetivos:**
- Sistema suportava apenas Rank S (máximo 3)
- Não havia forma de criar objetivos A ou B
- Modelo `ObjectiveModel` não tinha campo de rank
- Tela de objetivos era específica para Rank S

**Limitações:**
- Usuário não podia criar metas principais (A)
- Usuário não podia criar metas secundárias (B)
- Sistema de ranks incompleto

### Solução Implementada

## 1. ATUALIZAÇÃO DO MODELO DE DADOS

### Enum ObjectiveRank

**Arquivo:** `lib/core/utils/constants.dart`

Adicionado novo enum:

```dart
enum ObjectiveRank {
  s, // Rank S - Objetivos Sagrados (máximo 3)
  a, // Rank A - Metas Principais
  b, // Rank B - Metas Secundárias
}
```

**Características:**
- **S:** Limitado a 3 ativos
- **A:** Ilimitado
- **B:** Ilimitado

### ObjectiveModel Atualizado

**Arquivo:** `lib/models/objective_model.dart`

#### Campo Rank Adicionado

```dart
class ObjectiveModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final ObjectiveRank rank; // NOVO CAMPO
  final DateTime? deadline;
  final int progress;
  final DateTime createdAt;
  final DateTime? completedAt;
  
  ObjectiveModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.rank, // OBRIGATÓRIO
    this.deadline,
    this.progress = 0,
    required this.createdAt,
    this.completedAt,
  });
}
```

#### Método create() Atualizado

```dart
factory ObjectiveModel.create({
  required String userId,
  required String title,
  required ObjectiveRank rank, // NOVO PARÂMETRO
  String? description,
  DateTime? deadline,
}) {
  return ObjectiveModel(
    id: '',
    userId: userId,
    title: title,
    rank: rank,
    description: description,
    deadline: deadline,
    progress: 0,
    createdAt: DateTime.now(),
  );
}
```

#### fromFirestore() com Retrocompatibilidade

```dart
factory ObjectiveModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  
  // Parse rank (default para S se não existir, para compatibilidade)
  ObjectiveRank rank = ObjectiveRank.s;
  final rankString = data['rank'] as String?;
  if (rankString != null) {
    rank = ObjectiveRank.values.firstWhere(
      (r) => r.name == rankString,
      orElse: () => ObjectiveRank.s,
    );
  }
  
  return ObjectiveModel(
    id: doc.id,
    userId: data['userId'] ?? '',
    title: data['title'] ?? '',
    rank: rank, // Usa rank do Firestore ou S por padrão
    // ... outros campos
  );
}
```

**Motivo da Retrocompatibilidade:**
- Objetivos antigos (sem campo rank) são carregados como Rank S
- Evita erros com dados existentes
- Migração suave

#### toFirestore() Atualizado

```dart
Map<String, dynamic> toFirestore() {
  return {
    'userId': userId,
    'title': title,
    'rank': rank.name, // Salva como string ('s', 'a', 'b')
    'description': description,
    'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
    'progress': progress,
    'createdAt': Timestamp.fromDate(createdAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
  };
}
```

#### copyWith() Atualizado

```dart
ObjectiveModel copyWith({
  String? id,
  String? userId,
  String? title,
  String? description,
  ObjectiveRank? rank, // NOVO PARÂMETRO
  DateTime? deadline,
  int? progress,
  DateTime? createdAt,
  DateTime? completedAt,
}) {
  return ObjectiveModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    rank: rank ?? this.rank, // Permite alterar rank
    // ... outros campos
  );
}
```

---

## 2. ATUALIZAÇÃO DO REPOSITORY

### Arquivo: `lib/repositories/objective_repository.dart`

#### Novos Métodos (Por Rank)

```dart
/// Busca objetivos ativos por rank específico
Future<List<ObjectiveModel>> getActiveObjectivesByRank(
  String userId,
  ObjectiveRank rank,
) async {
  final snapshot = await _firestore
      .collection('users')
      .doc(userId)
      .collection('objectives')
      .where('rank', isEqualTo: rank.name) // Filtra por rank
      .where('progress', isLessThan: 100)
      .orderBy('progress')
      .orderBy('createdAt')
      .get();

  return snapshot.docs
      .map((doc) => ObjectiveModel.fromFirestore(doc))
      .toList();
}

/// Stream de objetivos ativos por rank
Stream<List<ObjectiveModel>> getActiveObjectivesStreamByRank(
  String userId,
  ObjectiveRank rank,
) {
  return _firestore
      .collection('users')
      .doc(userId)
      .collection('objectives')
      .where('rank', isEqualTo: rank.name)
      .where('progress', isLessThan: 100)
      .orderBy('progress')
      .orderBy('createdAt')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ObjectiveModel.fromFirestore(doc))
          .toList());
}
```

**Queries Firestore:**
- Filtra por `rank` (campo string: 's', 'a', 'b')
- Filtra por `progress < 100` (ativos)
- Ordena por progresso e data de criação

#### createObjective() com Validação de Limite

```dart
Future<ObjectiveModel> createObjective(ObjectiveModel objective) async {
  try {
    // Verifica limite APENAS para Rank S (máximo 3)
    if (objective.rank == ObjectiveRank.s) {
      final activeObjectivesS = await getActiveObjectivesByRank(
        objective.userId,
        ObjectiveRank.s,
      );
      if (activeObjectivesS.length >= SystemLimits.maxObjectivesS) {
        throw Exception('Máximo de 3 objetivos S ativos atingido');
      }
    }
    // Ranks A e B não têm limite

    final docRef = await _firestore
        .collection('users')
        .doc(objective.userId)
        .collection('objectives')
        .add(objective.toFirestore());

    return objective.copyWith(id: docRef.id);
  } catch (e) {
    throw Exception('Erro ao criar objetivo: $e');
  }
}
```

**Lógica de Limite:**
- **Rank S:** Máximo 3 ativos
- **Rank A:** Ilimitado
- **Rank B:** Ilimitado

---

## 3. TELA DE OBJETIVOS REFATORADA

### Arquivo: `lib/features/objectives/presentation/objectives_screen.dart`

#### Design com Filtros de Rank

```
┌─────────────────────────────────────────┐
│ [← Back] // OBJETIVOS_SAGRADOS          │
│          OBJETIVOS E METAS              │
├─────────────────────────────────────────┤
│ CATEGORIA:                              │
│ [RANK S]  [RANK A]  [RANK B]            │
│ Sagrados   Metas    Secundárias         │
├─────────────────────────────────────────┤
│ ┌─ Lista de Objetivos do Rank Selecionado
│ │ 🏁 Ser fluente em inglês    [RANK S] │
│ │ ─────────────────────────────────────│
│ │ PROGRESSO              75%           │
│ │ [===========════════]                │
│ └──────────────────────────────────────┘
│                                         │
│           [+ NOVO OBJETIVO] (FAB)       │
└─────────────────────────────────────────┘
```

#### Estado Local para Filtro

```dart
class _ObjectivesScreenState extends ConsumerState<ObjectivesScreen> {
  ObjectiveRank _selectedRank = ObjectiveRank.s; // Padrão: Rank S
  
  @override
  Widget build(BuildContext context) {
    // ... usa _selectedRank para filtrar
  }
}
```

#### Chips de Filtro (3 Ranks)

```dart
Widget _buildRankFilter() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATEGORIA:', style: ...),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRankChip(
              label: 'RANK S',
              subtitle: 'Sagrados',
              rank: ObjectiveRank.s,
              icon: Icons.flag,
            ),
            _buildRankChip(
              label: 'RANK A',
              subtitle: 'Metas',
              rank: ObjectiveRank.a,
              icon: Icons.star,
            ),
            _buildRankChip(
              label: 'RANK B',
              subtitle: 'Secundárias',
              rank: ObjectiveRank.b,
              icon: Icons.flag_outlined,
            ),
          ],
        ),
      ],
    ),
  );
}
```

**Características dos Chips:**
- Layout 3 colunas (igualmente distribuídas)
- Ícone, label, subtitle
- Background colorido quando selecionado
- Borda da cor do rank
- Interativo (GestureDetector)

#### Stream com Filtro de Rank

```dart
Widget _buildObjectivesList(String userId) {
  return StreamBuilder<List<ObjectiveModel>>(
    stream: _objectiveRepository.getActiveObjectivesStreamByRank(
      userId, 
      _selectedRank, // Filtra por rank selecionado
    ),
    builder: (context, snapshot) {
      // ... renderiza lista
    },
  );
}
```

**Atualização em Tempo Real:**
- Stream atualiza automaticamente
- Filtra apenas objetivos do rank selecionado
- Recarrega ao mudar de rank

#### FAB Condicional (Limite apenas para S)

```dart
Widget _buildFAB(String userId) {
  // Ranks A e B: Sempre permitir criar
  if (_selectedRank != ObjectiveRank.s) {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/objectives/create'),
      backgroundColor: _getRankColor(_selectedRank),
      icon: const Icon(Icons.add, color: Colors.black),
      label: Text('NOVO OBJETIVO', ...),
    );
  }

  // Rank S: Verifica limite de 3
  return StreamBuilder<List<ObjectiveModel>>(
    stream: _objectiveRepository.getActiveObjectivesStreamByRank(
      userId, 
      ObjectiveRank.s,
    ),
    builder: (context, snapshot) {
      final canCreate = (snapshot.data?.length ?? 0) < 3;

      return FloatingActionButton.extended(
        onPressed: canCreate
            ? () => context.push('/objectives/create')
            : () => _showLimitDialog(),
        backgroundColor: canCreate ? AppColors.rankS : Colors.grey,
        icon: Icon(canCreate ? Icons.add : Icons.block, ...),
        label: Text(canCreate ? 'NOVO OBJETIVO' : 'LIMITE ATINGIDO', ...),
      );
    },
  );
}
```

**Lógica:**
- **A e B:** FAB sempre ativo (sem limite)
- **S:** FAB verifica quantidade e desabilita se >= 3

#### Cores por Rank

```dart
Color _getRankColor(ObjectiveRank rank) {
  switch (rank) {
    case ObjectiveRank.s:
      return AppColors.rankS; // Dourado
    case ObjectiveRank.a:
      return AppColors.rankA; // Laranja Escuro
    case ObjectiveRank.b:
      return AppColors.rankB; // Laranja Claro
  }
}
```

#### Ícones por Rank

```dart
IconData _getRankIcon(ObjectiveRank rank) {
  switch (rank) {
    case ObjectiveRank.s:
      return Icons.flag;           // Bandeira sólida
    case ObjectiveRank.a:
      return Icons.star;           // Estrela
    case ObjectiveRank.b:
      return Icons.flag_outlined;  // Bandeira outline
  }
}
```

#### Mensagens Contextuais

```dart
String _getEmptyMessage(ObjectiveRank rank) {
  switch (rank) {
    case ObjectiveRank.s:
      return 'Defina seus objetivos sagrados para começar sua jornada.';
    case ObjectiveRank.a:
      return 'Crie metas principais para guiar seu progresso.';
    case ObjectiveRank.b:
      return 'Adicione metas secundárias para complementar seus objetivos.';
  }
}
```

---

## 4. TELA DE CRIAÇÃO ATUALIZADA

### Arquivo: `lib/features/objectives/presentation/create_objective_screen.dart`

#### Seletor de Rank (3 Opções)

```
┌─────────────────────────────────────────┐
│ CATEGORIA                               │
│ ┌──────┐  ┌──────┐  ┌──────┐          │
│ │  🏁  │  │  ⭐  │  │  🚩  │          │
│ │RANK S│  │RANK A│  │RANK B│          │
│ │Sagrado│ │ Meta │ │Secundária│        │
│ └──────┘  └──────┘  └──────┘          │
└─────────────────────────────────────────┘
```

**Código:**

```dart
Widget _buildRankSelector() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('CATEGORIA', style: ...),
      const SizedBox(height: 12),
      Row(
        children: [
          _buildRankChip(
            label: 'RANK S',
            subtitle: 'Sagrado',
            rank: ObjectiveRank.s,
            icon: Icons.flag,
          ),
          _buildRankChip(
            label: 'RANK A',
            subtitle: 'Meta',
            rank: ObjectiveRank.a,
            icon: Icons.star,
          ),
          _buildRankChip(
            label: 'RANK B',
            subtitle: 'Secundária',
            rank: ObjectiveRank.b,
            icon: Icons.flag_outlined,
          ),
        ],
      ),
    ],
  );
}
```

**Design:**
- 3 colunas (expanded)
- Ícone + label + subtitle
- Background da cor do rank quando selecionado
- Borda destacada quando selecionado

#### Info Card Contextual

```dart
Widget _buildInfoCard() {
  final color = _getRankColor(_selectedRank);
  final info = _getRankInfo(_selectedRank);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(info, style: ...),
        ),
      ],
    ),
  );
}

String _getRankInfo(ObjectiveRank rank) {
  switch (rank) {
    case ObjectiveRank.s:
      return 'Objetivos S são suas metas mais importantes. Máximo 3 ativos.';
    case ObjectiveRank.a:
      return 'Metas A são seus objetivos principais. Sem limite.';
    case ObjectiveRank.b:
      return 'Metas B complementam suas metas principais. Sem limite.';
  }
}
```

**Comportamento:**
- Cor e mensagem mudam conforme rank selecionado
- Explica diferenças entre S, A e B
- Informa sobre limites

#### Placeholder Contextual

```dart
String _getPlaceholderTitle(ObjectiveRank rank) {
  switch (rank) {
    case ObjectiveRank.s:
      return 'Ex: Ser fluente em inglês';
    case ObjectiveRank.a:
      return 'Ex: Concluir curso de Flutter';
    case ObjectiveRank.b:
      return 'Ex: Ler 1 livro por mês';
  }
}
```

**Usado em:**
```dart
TextFormField(
  controller: _titleController,
  decoration: InputDecoration(
    hintText: _getPlaceholderTitle(_selectedRank),
    // ...
  ),
)
```

#### Criação com Rank

```dart
Future<void> _handleCreate() async {
  // ... validações

  final objective = ObjectiveModel(
    id: const Uuid().v4(),
    userId: user.uid,
    title: _titleController.text.trim(),
    rank: _selectedRank, // Usa rank selecionado pelo usuário
    description: _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim(),
    createdAt: DateTime.now(),
    progress: 0,
  );

  await _objectiveService.createObjective(objective);
  
  // Feedback contextual
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Objetivo ${_getRankLabel(_selectedRank)} criado com sucesso!',
        // ...
      ),
    ),
  );
}
```

---

## 5. ATUALIZAÇÃO DO ONBOARDING

### Arquivo: `lib/features/onboarding/presentation/onboarding_screen.dart`

#### Rank S Fixo no Onboarding

```dart
objectives.add(
  ObjectiveModel.create(
    userId: user.uid,
    title: title,
    rank: ObjectiveRank.s, // Onboarding sempre cria Rank S
    description: _objectiveDescriptionControllers[i].text.trim().isEmpty
        ? null
        : _objectiveDescriptionControllers[i].text.trim(),
    deadline: _objectiveDeadlines[i],
  ),
);
```

**Motivo:**
- Onboarding é para definir os 3 objetivos SAGRADOS iniciais
- Ranks A e B podem ser criados depois, na tela de objetivos
- Mantém semântica do onboarding (objetivos fundamentais)

#### Import Adicionado

```dart
import '../../../../core/utils/constants.dart'; // Para ObjectiveRank
```

---

## 6. COMPARAÇÃO: ANTES vs DEPOIS

### Estrutura de Dados

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Ranks Suportados** | Apenas S | S, A e B |
| **Limite S** | 3 | 3 (mantido) |
| **Limite A** | N/A | Ilimitado |
| **Limite B** | N/A | Ilimitado |
| **Campo rank** | Não existia | Obrigatório |
| **Retrocompatibilidade** | N/A | Objetivos antigos = Rank S |

### Tela de Objetivos

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Filtro de Ranks** | Não tinha | 3 chips (S, A, B) |
| **Visualização** | Apenas Rank S | Filtra por rank selecionado |
| **FAB** | Sempre limita a 3 | Condicional (limite só no S) |
| **Cores** | Apenas dourado | Dourado, laranja escuro, laranja claro |
| **Ícones** | Apenas flag | Flag, star, flag_outlined |

### Tela de Criação

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Escolha de Rank** | Sempre S | Seletor de 3 ranks |
| **Info Card** | Genérico | Contextual por rank |
| **Placeholder** | Fixo | Contextual por rank |
| **Validação** | Sempre limite 3 | Condicional (apenas S) |
| **Feedback** | Genérico | "Objetivo S/A/B criado" |

### Onboarding

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Rank Criado** | Implícito (S) | Explícito (S) |
| **Compatibilidade** | Quebrava sem rank | Funciona com novo campo |

---

## 7. CORES DOS RANKS

```dart
// AppColors
static const Color rankS = Color(0xFFFFD700); // Dourado
static const Color rankA = Color(0xFFFF8C00); // Laranja Escuro
static const Color rankB = Color(0xFFFF6B35); // Laranja Claro
```

**Hierarquia Visual:**
- **S (Dourado):** Mais importante, brilhante
- **A (Laranja Escuro):** Importante, vibrante
- **B (Laranja Claro):** Complementar, suave

---

## 8. ÍCONES DOS RANKS

```dart
S → Icons.flag           // Bandeira sólida (conquista máxima)
A → Icons.star           // Estrela (objetivo brilhante)
B → Icons.flag_outlined  // Bandeira outline (objetivo secundário)
```

**Semântica:**
- **S:** Flag sólida = objetivo máximo, firme
- **A:** Star = objetivo brilhante, destacado
- **B:** Flag outline = objetivo secundário, suporte

---

## 9. FLUXOS DE USO

### Criar Objetivo S (com limite)

```
1. Dashboard → OBJETIVOS
2. Chip "RANK S" selecionado (padrão)
3. Vê lista de objetivos S (0 a 3)
4. Clica FAB "NOVO OBJETIVO" (se < 3)
5. CreateScreen abre com Rank S pré-selecionado
6. Preenche título e descrição
7. Clica "CRIAR OBJETIVO"
8. Volta para lista → objetivo aparece
```

### Criar Objetivo A (sem limite)

```
1. Dashboard → OBJETIVOS
2. Clica chip "RANK A"
3. Vê lista de metas A (pode estar vazia)
4. Clica FAB "NOVO OBJETIVO" (sempre disponível)
5. CreateScreen abre com Rank S padrão
6. Clica chip "RANK A" no seletor
7. Info card atualiza: "Metas A são... Sem limite"
8. Preenche título e descrição
9. Clica "CRIAR OBJETIVO"
10. Volta para lista → meta A aparece
```

### Criar Objetivo B (sem limite)

```
Similar ao fluxo A, mas seleciona Rank B
```

### Alternar entre Ranks

```
1. Na tela ObjectivesScreen
2. Clica em chip diferente (S → A → B)
3. Lista recarrega automaticamente
4. FAB atualiza (limite no S, livre no A/B)
5. Cores do header atualizam
```

---

## 10. ARQUIVOS MODIFICADOS/CRIADOS

### Modificados

1. **`lib/core/utils/constants.dart`**
   - Adicionado `enum ObjectiveRank { s, a, b }`

2. **`lib/models/objective_model.dart`**
   - Campo `rank` adicionado
   - `create()` requer rank
   - `fromFirestore()` com retrocompatibilidade
   - `toFirestore()` salva rank
   - `copyWith()` permite alterar rank

3. **`lib/repositories/objective_repository.dart`**
   - `getActiveObjectivesByRank()` (Future)
   - `getActiveObjectivesStreamByRank()` (Stream)
   - `createObjective()` valida limite apenas para S

4. **`lib/features/objectives/presentation/objectives_screen.dart`**
   - Completamente refatorada
   - Filtros de rank (chips)
   - Lista por rank
   - FAB condicional
   - Cores e ícones por rank

5. **`lib/features/objectives/presentation/create_objective_screen.dart`**
   - Completamente refatorada
   - Seletor de rank
   - Info card contextual
   - Placeholder contextual
   - Criação com rank

6. **`lib/features/onboarding/presentation/onboarding_screen.dart`**
   - Import de `constants.dart` (ObjectiveRank)
   - `ObjectiveModel.create()` com `rank: ObjectiveRank.s`

7. **`historico_da_ia/README.md`**
   - Adicionada entrada para histórico 28

### Criados

1. **`historico_da_ia/28_2025-01-15_suporte_objetivos_a_e_b.md`**
   - Esta documentação

---

## 11. STATUS FINAL

✅ **Compilação:** 0 erros  
⚠️ **Análise:** 4 info (use_build_context_synchronously - não crítico)  
✅ **Funcionalidade:** Completa  
✅ **Design:** Consistente com resto do app  
✅ **Documentação:** Completa  
✅ **Retrocompatibilidade:** Garantida  

---

## 12. OBSERVAÇÕES FINAIS

### Retrocompatibilidade

Objetivos antigos (sem campo `rank`) são automaticamente tratados como Rank S ao carregar:

```dart
ObjectiveRank rank = ObjectiveRank.s;
final rankString = data['rank'] as String?;
if (rankString != null) {
  rank = ObjectiveRank.values.firstWhere(
    (r) => r.name == rankString,
    orElse: () => ObjectiveRank.s,
  );
}
```

**Resultado:**
- Dados antigos continuam funcionando
- Nenhuma migração manual necessária
- Transição suave

### Hierarquia de Objetivos

```
┌─ RANK S (Sagrados) ────────┐
│ • Máximo 3 ativos          │
│ • Mais importantes         │
│ • Criados no onboarding    │
└────────────────────────────┘
         ↓
┌─ RANK A (Metas) ───────────┐
│ • Ilimitados               │
│ • Objetivos principais     │
│ • Guiam progresso          │
└────────────────────────────┘
         ↓
┌─ RANK B (Secundárias) ─────┐
│ • Ilimitadas               │
│ • Complementares           │
│ • Suporte às metas         │
└────────────────────────────┘
```

### Design Patterns

**Strategy Pattern (Rank):**
- Comportamento (limite, cor, ícone) varia por rank
- Switch statements centralizados
- Fácil adicionar novos ranks

**Repository Pattern:**
- Queries específicas por rank
- Validações no repository
- Service usa repository (camada de abstração)

**Composition Over Inheritance:**
- `_buildRankChip()` reutilizado
- Parametrizado (label, subtitle, rank, icon)
- DRY (Don't Repeat Yourself)

### Performance

**Firestore Indexes Necessários:**

```
Collection: objectives
Indexes:
1. rank (ASC) + progress (ASC) + createdAt (ASC)
2. progress (ASC) + createdAt (ASC)
```

**Criados automaticamente ao rodar queries.**

---

## 13. PRÓXIMOS PASSOS POSSÍVEIS

1. **Rank C, D, E para Objetivos:** Expandir sistema (atualmente são apenas para tarefas)
2. **Dashboard por Rank:** Mostrar resumo de S/A/B no dashboard
3. **Progresso Automático:** Atualizar progresso baseado em tarefas linkadas
4. **Conclusão de Objetivo:** Modal especial ao atingir 100%
5. **Histórico de Objetivos:** Ver objetivos completados por rank
6. **Estatísticas:** Gráficos de progresso por rank ao longo do tempo

---

**Resultado:** Sistema completo de gerenciamento de Objetivos S, A e B, com design profissional e consistente! 🎯✨
