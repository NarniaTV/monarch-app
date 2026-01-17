# Histórico - Rank B como Hábitos + Contexto de Rank na Criação

## Data: 15/01/2025

### Problema Reportado pelo Usuário

1. **Rank B não tratado como hábito:** Labels ainda diziam "Metas Secundárias"
2. **Rank errado ao criar:** Ao clicar no FAB em Rank A ou B, a tela de criação abria sempre em Rank S

### Solução Implementada

## 1. RENOMEAÇÃO COMPLETA DO RANK B PARA "HÁBITOS"

### Tela de Objetivos (objectives_screen.dart)

**Chip de Filtro:**
```dart
// ANTES
_buildRankChip(
  label: 'RANK B',
  subtitle: 'Secundárias',
  rank: ObjectiveRank.b,
  icon: Icons.flag_outlined,
)

// DEPOIS
_buildRankChip(
  label: 'RANK B',
  subtitle: 'Hábitos',
  rank: ObjectiveRank.b,
  icon: Icons.flag_outlined,
)
```

**Labels de Seção:**
```dart
// ANTES
String _getRankLabel(ObjectiveRank rank) {
  case ObjectiveRank.s: return 'OBJETIVOS_SAGRADOS';
  case ObjectiveRank.a: return 'METAS_PRINCIPAIS';
  case ObjectiveRank.b: return 'METAS_SECUNDARIAS';
}

// DEPOIS
String _getRankLabel(ObjectiveRank rank) {
  case ObjectiveRank.s: return 'METAS_DE_VIDA';
  case ObjectiveRank.a: return 'METAS_A_ALCANCAR';
  case ObjectiveRank.b: return 'HABITOS';
}
```

**Mensagens de Empty State:**
```dart
// ANTES
case ObjectiveRank.s: 
  return 'Defina seus objetivos sagrados para começar sua jornada.';
case ObjectiveRank.a: 
  return 'Crie metas principais para guiar seu progresso.';
case ObjectiveRank.b: 
  return 'Adicione metas secundárias para complementar seus objetivos.';

// DEPOIS
case ObjectiveRank.s: 
  return 'Defina suas grandes metas de vida (ex: comprar carro, abrir empresa).';
case ObjectiveRank.a: 
  return 'Crie metas com tarefas menores para alcançá-las.';
case ObjectiveRank.b: 
  return 'Adicione hábitos que você quer praticar regularmente.';
```

### Tela de Criação (create_objective_screen.dart)

**Chip de Seleção:**
```dart
// ANTES
_buildRankChip(
  label: 'RANK B',
  subtitle: 'Secundária',
  rank: ObjectiveRank.b,
  icon: Icons.flag_outlined,
)

// DEPOIS
_buildRankChip(
  label: 'RANK B',
  subtitle: 'Hábito',
  rank: ObjectiveRank.b,
  icon: Icons.repeat,  // Novo ícone!
)
```

**Info Card:**
```dart
// ANTES
case ObjectiveRank.s:
  return 'Objetivos S são suas metas mais importantes. Máximo 3 ativas.';
case ObjectiveRank.a:
  return 'Metas A são seus objetivos principais. Você pode ter quantas quiser.';
case ObjectiveRank.b:
  return 'Metas B são objetivos secundários que complementam suas metas principais. Sem limite.';

// DEPOIS
case ObjectiveRank.s:
  return 'Metas de vida grandes (ex: comprar carro dos sonhos, abrir empresa). Máximo 3 ativas.';
case ObjectiveRank.a:
  return 'Metas a serem alcançadas com tarefas menores. Você pode ter quantas quiser.';
case ObjectiveRank.b:
  return 'Hábitos são ações repetidas regularmente (ex: correr, estudar). Sem limite.';
```

**Placeholders:**
```dart
// ANTES
case ObjectiveRank.s: return 'Ex: Ser fluente em inglês';
case ObjectiveRank.a: return 'Ex: Concluir curso de Flutter';
case ObjectiveRank.b: return 'Ex: Ler 1 livro por mês';

// DEPOIS
case ObjectiveRank.s: return 'Ex: Comprar carro dos sonhos';
case ObjectiveRank.a: return 'Ex: Conseguir promoção no trabalho';
case ObjectiveRank.b: return 'Ex: Correr 3x por semana';
```

---

## 2. CONTEXTO DE RANK NA NAVEGAÇÃO

### Problema

Quando o usuário estava visualizando Rank A ou B e clicava no FAB para criar, a tela abria sempre com Rank S pré-selecionado. Isso causava confusão.

### Solução: Query Parameter + Inicialização Contextual

#### Passo 1: Passar Rank na URL

**objectives_screen.dart:**
```dart
// FAB para Ranks A e B
FloatingActionButton.extended(
  onPressed: () => context.push('/objectives/create?rank=${_selectedRank.name}'),
  // ...
)

// FAB para Rank S (com validação de limite)
FloatingActionButton.extended(
  onPressed: canCreate
      ? () => context.push('/objectives/create?rank=${ObjectiveRank.s.name}')
      : () => _showLimitDialog(),
  // ...
)
```

**URL geradas:**
- `/objectives/create?rank=s` → Abre com Rank S
- `/objectives/create?rank=a` → Abre com Rank A
- `/objectives/create?rank=b` → Abre com Rank B

#### Passo 2: Receber Rank na Tela de Criação

**create_objective_screen.dart:**

**Widget atualizado:**
```dart
// ANTES
class CreateObjectiveScreen extends ConsumerStatefulWidget {
  const CreateObjectiveScreen({super.key});
  
  @override
  ConsumerState<CreateObjectiveScreen> createState() => _CreateObjectiveScreenState();
}

class _CreateObjectiveScreenState extends ConsumerState<CreateObjectiveScreen> {
  ObjectiveRank _selectedRank = ObjectiveRank.s; // Sempre S
  // ...
}

// DEPOIS
class CreateObjectiveScreen extends ConsumerStatefulWidget {
  final ObjectiveRank? initialRank; // Novo parâmetro opcional
  
  const CreateObjectiveScreen({super.key, this.initialRank});
  
  @override
  ConsumerState<CreateObjectiveScreen> createState() => _CreateObjectiveScreenState();
}

class _CreateObjectiveScreenState extends ConsumerState<CreateObjectiveScreen> {
  late ObjectiveRank _selectedRank; // Não inicializado aqui
  
  @override
  void initState() {
    super.initState();
    _selectedRank = widget.initialRank ?? ObjectiveRank.s; // Usa initial ou S
  }
  // ...
}
```

#### Passo 3: Parse de Query Parameter na Rota

**app_router.dart:**

**Import adicionado:**
```dart
import '../../core/utils/constants.dart'; // Para ObjectiveRank
```

**Rota atualizada:**
```dart
// ANTES
GoRoute(
  path: '/objectives/create',
  builder: (context, state) => const CreateObjectiveScreen(),
),

// DEPOIS
GoRoute(
  path: '/objectives/create',
  builder: (context, state) {
    final rankParam = state.uri.queryParameters['rank'];
    ObjectiveRank? initialRank;
    if (rankParam != null) {
      try {
        initialRank = ObjectiveRank.values.firstWhere(
          (r) => r.name == rankParam,
        );
      } catch (e) {
        initialRank = null;
      }
    }
    return CreateObjectiveScreen(initialRank: initialRank);
  },
),
```

**Lógica:**
1. Lê query parameter `rank` da URL
2. Busca o enum `ObjectiveRank` correspondente
3. Se encontrar, passa como `initialRank`
4. Se não encontrar ou não existir, passa `null` (usa padrão S)

---

## 3. FLUXO DE USUÁRIO MELHORADO

### Antes

```
1. Usuário vai para tela de Objetivos
2. Clica em chip "RANK A"
3. Vê lista de Metas A
4. Clica FAB "NOVO OBJETIVO"
5. Tela abre com Rank S selecionado ❌
6. Usuário tem que clicar em "RANK A" novamente ❌
```

### Depois

```
1. Usuário vai para tela de Objetivos
2. Clica em chip "RANK A"
3. Vê lista de Metas A
4. Clica FAB "NOVO OBJETIVO"
5. Tela abre com Rank A já selecionado ✅
6. Usuário pode começar a digitar imediatamente ✅
```

**Economia:** 2 cliques por criação de objetivo!

---

## 4. NOVA SEMÂNTICA CLARIFICADA

### Hierarquia de Objetivos

```
┌─ RANK S (Metas de Vida) ──────────┐
│ • Máximo 3 ativos                 │
│ • Grandes conquistas de vida      │
│ • Ex: Comprar carro, abrir empresa│
│ • Ícone: 🏁 flag                  │
└───────────────────────────────────┘
         ↓
┌─ RANK A (Metas a Alcançar) ───────┐
│ • Ilimitadas                       │
│ • Com tarefas menores linkadas    │
│ • Ex: Conseguir promoção           │
│ • Ícone: ⭐ star                   │
└───────────────────────────────────┘
         ↓
┌─ RANK B (Hábitos) ─────────────────┐
│ • Ilimitados                       │
│ • Ações repetidas regularmente    │
│ • Ex: Correr 3x por semana         │
│ • Ícone: 🔁 repeat (NOVO!)         │
└───────────────────────────────────┘
```

### Mudanças de Ícones

| Rank | Antes | Depois | Motivo |
|------|-------|--------|--------|
| S | 🏁 flag | 🏁 flag | Mantido (conquista) |
| A | ⭐ star | ⭐ star | Mantido (objetivo brilhante) |
| B | 🚩 flag_outlined | 🔁 repeat | **NOVO:** Representa repetição/hábito |

---

## 5. EXEMPLOS CONTEXTUAIS ATUALIZADOS

### Placeholders por Rank

| Rank | Antes | Depois |
|------|-------|--------|
| S | "Ser fluente em inglês" | **"Comprar carro dos sonhos"** |
| A | "Concluir curso de Flutter" | **"Conseguir promoção no trabalho"** |
| B | "Ler 1 livro por mês" | **"Correr 3x por semana"** |

**Motivo das mudanças:**
- S: Mais focado em conquistas materiais/grandes
- A: Objetivos de carreira/crescimento
- B: Claramente uma ação repetida (hábito)

### Info Cards por Rank

**Rank S:**
- Antes: "Objetivos S são suas metas mais importantes..."
- Depois: **"Metas de vida grandes (ex: comprar carro dos sonhos, abrir empresa)"**

**Rank A:**
- Antes: "Metas A são seus objetivos principais..."
- Depois: **"Metas a serem alcançadas com tarefas menores"**

**Rank B:**
- Antes: "Metas B são objetivos secundários..."
- Depois: **"Hábitos são ações repetidas regularmente (ex: correr, estudar)"**

---

## 6. ARQUIVOS MODIFICADOS

1. **`lib/features/objectives/presentation/objectives_screen.dart`**
   - Chip subtitle: "Secundárias" → "Hábitos"
   - `_getRankLabel()`: Labels atualizados
   - `_getEmptyMessage()`: Mensagens contextualizadas
   - FAB: Passa rank via query parameter

2. **`lib/features/objectives/presentation/create_objective_screen.dart`**
   - Adicionado parâmetro `initialRank` opcional
   - `initState()`: Inicializa com rank passado ou S
   - Chip subtitle: "Secundária" → "Hábito"
   - Ícone B: `flag_outlined` → `repeat`
   - `_getRankInfo()`: Descrições atualizadas
   - `_getPlaceholderTitle()`: Exemplos contextuais

3. **`lib/core/routing/app_router.dart`**
   - Import: `constants.dart` (ObjectiveRank)
   - Rota `/objectives/create`: Parse de query parameter
   - Passa `initialRank` para `CreateObjectiveScreen`

4. **`historico_da_ia/31_2025-01-15_rank_b_habitos_e_rank_context.md`**
   - Esta documentação

---

## 7. TESTES DE VALIDAÇÃO

### Teste 1: Navegação com Rank S

```dart
// User está em Rank S
context.push('/objectives/create?rank=s')
→ Tela abre com Rank S selecionado ✅
→ Info: "Metas de vida grandes..." ✅
→ Placeholder: "Comprar carro dos sonhos" ✅
```

### Teste 2: Navegação com Rank A

```dart
// User está em Rank A
context.push('/objectives/create?rank=a')
→ Tela abre com Rank A selecionado ✅
→ Info: "Metas a serem alcançadas..." ✅
→ Placeholder: "Conseguir promoção" ✅
```

### Teste 3: Navegação com Rank B

```dart
// User está em Rank B
context.push('/objectives/create?rank=b')
→ Tela abre com Rank B selecionado ✅
→ Info: "Hábitos são ações repetidas..." ✅
→ Placeholder: "Correr 3x por semana" ✅
→ Ícone: repeat 🔁 ✅
```

### Teste 4: Navegação sem Parâmetro

```dart
// Navegação direta
context.push('/objectives/create')
→ Tela abre com Rank S (padrão) ✅
```

### Teste 5: Parâmetro Inválido

```dart
// Query parameter inválido
context.push('/objectives/create?rank=xyz')
→ Tela abre com Rank S (fallback) ✅
```

---

## 8. STATUS FINAL

✅ **Compilação:** 0 erros  
✅ **Análise:** Apenas 4 info (não crítico)  
✅ **Rank B:** Renomeado para "Hábitos"  
✅ **Contexto:** Rank pré-selecionado ao criar  
✅ **UX:** 2 cliques economizados por criação  
✅ **Semântica:** Clara e intuitiva  

---

## 9. PRÓXIMOS PASSOS (PENDENTES)

### Sistema de Frequência para Hábitos (Rank B)

**Quando criar um Hábito (Rank B), adicionar:**

1. **Seletor de Frequência:**
   ```
   [x] Todo dia
   [ ] A cada X dias → [Input numérico: 2, 3, 4...]
   [ ] Dias da semana → [S] [T] [Q] [Q] [S] [S] [D]
   [ ] Mensal
   ```

2. **Campos no Model:**
   ```dart
   class ObjectiveModel {
     final FrequencyType? frequency;
     final int? frequencyValue;     // Para "a cada X dias"
     final List<int>? weekDays;     // Para semanal [1-7]
   }
   
   enum FrequencyType { daily, everyXDays, weekly, monthly }
   ```

3. **Geração Automática:**
   - Service que cria tarefas recorrentes
   - Baseado na frequência definida
   - Tarefas linkadas ao hábito
   - Checkbox diário para marcar cumprimento

### Objetivos A com Tarefas Linkadas

**Ao criar Objetivo A:**

1. Após salvar, mostrar modal: "Deseja adicionar tarefas para esta meta?"
2. Se sim, permitir adicionar múltiplas tarefas (C, D, E)
3. Tarefas ficam linkadas ao objetivo A
4. Progresso do objetivo aumenta conforme tarefas são completadas

---

**Resultado:** Rank B agora é claramente "Hábitos" e a criação de objetivos respeita o contexto do usuário! 🎯✨
