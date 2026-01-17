# Histórico - Adição do Rank B ao Sistema

## Data: 14/01/2025

### Motivo da Mudança
O usuário solicitou a adição do Rank B para "Metas Secundárias" e deixar o Rank A apenas para "Metas", criando uma hierarquia mais detalhada de objetivos/metas antes de chegar às tarefas.

### Problema Identificado
- **Rank A sobrecarregado**: Era usado tanto para "metas" quanto para "metas secundárias"
- **Falta de granularidade**: Não havia distinção clara entre diferentes níveis de metas
- **Hierarquia incompleta**: Pulava de A direto para C (tarefas)

### Solução Implementada

#### 1. NOVA HIERARQUIA COMPLETA DE RANKS

**Estrutura Anterior (após adição do C):**
```
S: Objetivos Sagrados (3 máx) - 0 XP
A: Metas Secundárias (objetivos menores) - 0 XP
C: Tarefas Importantes - 100 XP
D: Tarefas Médias - 50 XP
E: Tarefas Simples - 25 XP
```

**Nova Estrutura (com Rank B):**
```
S: Objetivos Sagrados (3 máx) - 0 XP
A: Metas - 0 XP
B: Metas Secundárias - 0 XP (NOVO)
C: Tarefas Importantes - 100 XP
D: Tarefas Médias - 50 XP
E: Tarefas Simples - 25 XP
```

**Conceitos Clarificados:**
- **S:** Objetivos Sagrados (os 3 pilares da vida)
- **A:** Metas principais (objetivos importantes de médio prazo)
- **B:** Metas secundárias (sub-objetivos, marcos intermediários)
- **C, D, E:** Tarefas (ações diárias que dão XP)

#### 2. ENUM TASKRANK ATUALIZADO

**Arquivo:** `lib/core/utils/constants.dart`

```dart
/// Enum para ranks de tarefas e objetivos
enum TaskRank {
  s, // Rank S - Objetivos Sagrados (limitado a 3)
  a, // Rank A - Metas
  b, // Rank B - Metas Secundárias
  c, // Rank C - Tarefas Importantes
  d, // Rank D - Tarefas médias
  e, // Rank E - Tarefas simples
}
```

**Mudanças:**
- Rank A: "Metas Secundárias (objetivos menores que S)" → "Metas"
- Adicionado: Rank B - "Metas Secundárias"

#### 3. VALORES DE XP ATUALIZADOS

**Arquivo:** `lib/core/utils/constants.dart`

```dart
/// Valores de XP por rank
class XpValues {
  static const int rankS = 0; // Objetivos S não dão XP direto
  static const int rankA = 0; // Metas A não dão XP direto (são metas)
  static const int rankB = 0; // Metas B não dão XP direto (metas secundárias)
  static const int rankC = 100; // Tarefas importantes
  static const int rankD = 50; // Tarefas médias
  static const int rankE = 25; // Tarefas simples
}
```

**Mudanças:**
- Adicionado: `rankB = 0` (é meta, não dá XP direto)
- Comentário do rankA atualizado

#### 4. CORES DOS RANKS

**Arquivo:** `lib/core/theme/app_colors.dart`

```dart
// Cores para ranks
static const Color rankS = Color(0xFFFFD700); // Dourado - Objetivos Sagrados
static const Color rankA = Color(0xFFFF8C00); // Laranja Escuro - Metas
static const Color rankB = Color(0xFFFF6B35); // Laranja Claro - Metas Secundárias
static const Color rankC = Color(0xFFFF5252); // Vermelho - Tarefas Importantes
static const Color rankD = Color(0xFF2196F3); // Azul - Tarefas Médias
static const Color rankE = Color(0xFF4CAF50); // Verde - Tarefas Simples
```

**Mudanças:**
- `rankA`: Nova cor Laranja Escuro (#FF8C00) - diferencia mais de S
- `rankB`: Laranja Claro (#FF6B35) - a cor anterior do rank A

**Paleta de Cores Atualizada:**

| Rank | Cor | Hex | Significado |
|------|-----|-----|-------------|
| S | Dourado | #FFD700 | Objetivos Sagrados |
| A | Laranja Escuro | #FF8C00 | Metas |
| B | Laranja Claro | #FF6B35 | Metas Secundárias |
| C | Vermelho | #FF5252 | Tarefas Importantes |
| D | Azul | #2196F3 | Tarefas Médias |
| E | Verde | #4CAF50 | Tarefas Simples |

**Gradiente de Laranja (S → A → B):**
```
Dourado (S)  #FFD700  ████████
    ↓
Laranja Escuro (A)  #FF8C00  ████████
    ↓
Laranja Claro (B)  #FF6B35  ████████
    ↓
Vermelho (C)  #FF5252  ████████
```

#### 5. SWITCH CASE ATUALIZADO

**Arquivo:** `lib/models/task_model.dart`

```dart
switch (rank) {
  case TaskRank.s:
    xpReward = XpValues.rankS;
    break;
  case TaskRank.a:
    xpReward = XpValues.rankA;
    break;
  case TaskRank.b: // NOVO
    xpReward = XpValues.rankB;
    break;
  case TaskRank.c:
    xpReward = XpValues.rankC;
    break;
  case TaskRank.d:
    xpReward = XpValues.rankD;
    break;
  case TaskRank.e:
    xpReward = XpValues.rankE;
    break;
}
```

#### 6. TUTORIAL DO ONBOARDING ATUALIZADO

**Arquivo:** `lib/features/onboarding/presentation/onboarding_screen.dart`

**Antes:**
```
S: Objetivos Sagrados (3 máx)
A: Metas Secundárias (objetivos menores)
C: Tarefas Importantes (100 XP)
D: Tarefas Médias (50 XP)
E: Tarefas Simples (25 XP)
```

**Depois:**
```
S: Objetivos Sagrados (3 máx)
A: Metas
B: Metas Secundárias
C: Tarefas Importantes (100 XP)
D: Tarefas Médias (50 XP)
E: Tarefas Simples (25 XP)
```

### Arquivos Modificados

#### Modificados
- `lib/core/utils/constants.dart`
  - Enum `TaskRank`: Adicionado rank B, comentário do A atualizado
  - Classe `XpValues`: Adicionado `rankB = 0`

- `lib/core/theme/app_colors.dart`
  - `rankA`: Nova cor Laranja Escuro (#FF8C00)
  - Adicionado: `rankB` Laranja Claro (#FF6B35)

- `lib/models/task_model.dart`
  - Switch case: Adicionado caso para TaskRank.b

- `lib/features/onboarding/presentation/onboarding_screen.dart`
  - Card "SISTEMA DE RANKS": Descrição atualizada com rank B

#### Documentação
- `historico_da_ia/15_2025-01-14_adicao_rank_b.md` (criado)
- `historico_da_ia/README.md` (atualizado)

### Comparação: Antes vs Depois

#### Hierarquia

| Rank | Antes | Depois | XP |
|------|-------|--------|-----|
| **S** | Objetivos Sagrados | Objetivos Sagrados | 0 |
| **A** | Metas Secundárias | **Metas** | 0 |
| **B** | ❌ Não existia | **Metas Secundárias** | **0** |
| **C** | Tarefas Importantes | Tarefas Importantes | 100 |
| **D** | Tarefas Médias | Tarefas Médias | 50 |
| **E** | Tarefas Simples | Tarefas Simples | 25 |

#### Cores

| Rank | Cor Antes | Cor Depois | Mudança |
|------|-----------|------------|---------|
| S | Dourado | Dourado | - |
| A | Laranja Claro | **Laranja Escuro** | ✅ Cor mais forte |
| B | - | **Laranja Claro** | ✅ Novo rank |
| C | Vermelho | Vermelho | - |
| D | Azul | Azul | - |
| E | Verde | Verde | - |

### Hierarquia Completa Explicada

#### OBJETIVOS E METAS (S, A, B) - Não dão XP direto
- **Rank S:** Objetivos Sagrados (máximo 3)
  - Os 3 pilares fundamentais da vida
  - Conquistas de longo prazo (meses/anos)
  - Exemplo: "Formar em Engenharia"
  
- **Rank A:** Metas
  - Objetivos importantes de médio prazo
  - Marcos significativos
  - Exemplo: "Passar em Cálculo II"

- **Rank B:** Metas Secundárias
  - Sub-objetivos, marcos intermediários
  - Passos menores rumo às metas A
  - Exemplo: "Terminar lista de exercícios de Cálculo"

#### TAREFAS (C, D, E) - Dão XP
- **Rank C:** Tarefas Importantes (100 XP)
  - Tarefas complexas e impactantes
  - Exemplo: "Estudar 4 horas para prova"
  
- **Rank D:** Tarefas Médias (50 XP)
  - Tarefas cotidianas regulares
  - Exemplo: "Fazer exercícios de matemática"
  
- **Rank E:** Tarefas Simples (25 XP)
  - Tarefas rápidas e fáceis
  - Exemplo: "Revisar anotações"

### Exemplos de Uso

#### Objetivo S: "Formar em Engenharia de Software"
- **Meta A:** "Passar em todas as matérias do 3º semestre"
  - **Meta B:** "Conseguir média 7 em Estruturas de Dados"
    - **Tarefa C:** "Implementar árvore binária do projeto"
    - **Tarefa D:** "Resolver lista de exercícios"
    - **Tarefa E:** "Revisar conceitos básicos"

### Impacto no Plano Original
⚠️ **Desvio pequeno do plano.** O plano original previa S, A, D, E. Adições de B e C:
- Criam hierarquia mais completa e intuitiva (alfabética)
- Separam claramente objetivos/metas (S, A, B) de tarefas (C, D, E)
- Não afetam arquitetura ou funcionalidade existente
- Melhoram UX ao dar mais opções de classificação

### Próximos Passos
1. ✅ Atualizar enum TaskRank
2. ✅ Atualizar XpValues
3. ✅ Adicionar cor rankB
4. ✅ Atualizar switch cases
5. ✅ Atualizar tutorial do onboarding
6. ⚠️ TODO: Revisar textos que mencionam ranks
7. ⚠️ TODO: Atualizar UI de criação de tarefas/metas para incluir B

### Status
✅ **Código compila sem erros**
✅ **Rank B adicionado ao enum**
✅ **Valores de XP atualizados**
✅ **Cor laranja escuro para rank A**
✅ **Cor laranja claro para rank B**
✅ **Switch case atualizado**
✅ **Tutorial atualizado**
✅ **Hierarquia completa: S-A-B-C-D-E**

---

## Checklist de Conformidade

### Enum TaskRank
- ✅ Adicionado rank B
- ✅ Comentários atualizados
- ✅ Ordem correta (s, a, b, c, d, e)

### XpValues
- ✅ rankS = 0 (objetivo)
- ✅ rankA = 0 (meta)
- ✅ rankB = 0 (meta secundária)
- ✅ rankC = 100 (tarefa importante)
- ✅ rankD e rankE mantidos

### AppColors
- ✅ rankS: Dourado (#FFD700)
- ✅ rankA: Laranja Escuro (#FF8C00)
- ✅ rankB: Laranja Claro (#FF6B35)
- ✅ rankC: Vermelho (#FF5252)
- ✅ rankD: Azul (#2196F3)
- ✅ rankE: Verde (#4CAF50)

### Switch Cases
- ✅ Caso TaskRank.b adicionado
- ✅ Todos os ranks cobertos

### Onboarding Tutorial
- ✅ Rank A: "Metas"
- ✅ Rank B: "Metas Secundárias" (novo)
- ✅ Ordem correta (S, A, B, C, D, E)

---

## Detalhes Técnicos

### Gradiente de Cores por Importância

```
Hierarquia Visual Completa:

S (Dourado)          #FFD700  ████████  Mais importante
    ↓
A (Laranja Escuro)   #FF8C00  ████████
    ↓
B (Laranja Claro)    #FF6B35  ████████
    ↓
C (Vermelho)         #FF5252  ████████
    ↓
D (Azul)             #2196F3  ████████
    ↓
E (Verde)            #4CAF50  ████████  Menos importante
```

### Por que Duas Tonalidades de Laranja?

**Laranja Escuro (A) - #FF8C00:**
- Mais próximo do Dourado (S)
- Indica maior importância
- Diferencia claramente de B

**Laranja Claro (B) - #FF6B35:**
- Tom intermediário entre A e C
- Mantém família laranja das metas
- Clara distinção visual de A

### Sistema de 6 Níveis

A hierarquia S-A-B-C-D-E oferece:
- **3 níveis de objetivos/metas** (S, A, B) - Planejamento estratégico
- **3 níveis de tarefas** (C, D, E) - Execução tática

Isso cria um sistema completo que cobre desde os objetivos de vida até as micro-tarefas diárias.

---

## Observações Finais

Esta adição completa o sistema de ranks com uma hierarquia alfabética intuitiva (S-A-B-C-D-E) e clara separação conceitual:

1. **OBJETIVOS/METAS (S, A, B):** Planejamento de longo e médio prazo (0 XP)
2. **TAREFAS (C, D, E):** Ações diárias que geram progresso (XP)

O **Rank B** preenche a lacuna entre "metas principais" (A) e "tarefas importantes" (C), permitindo melhor granularidade na classificação de sub-objetivos e marcos intermediários.

A escala de cores em gradiente (Dourado → Laranjas → Vermelho → Azul → Verde) reforça visualmente a hierarquia de importância.
