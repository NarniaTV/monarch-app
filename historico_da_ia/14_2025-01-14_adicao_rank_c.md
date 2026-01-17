# Histórico - Adição do Rank C ao Sistema

## Data: 14/01/2025

### Motivo da Mudança
O usuário solicitou a adição de um novo rank (C) ao sistema e reorganização da hierarquia:
- Rank A deve ser para **metas menores que S** (objetivos secundários), não tarefas
- Rank C deve ser criado para **tarefas mais importantes** (anteriormente era rank A)
- Manter D e E como estão (tarefas médias e simples)

### Problema Identificado
- **Rank A mal posicionado**: Era usado para "tarefas importantes", mas deveria ser reservado para objetivos/metas
- **Falta de rank C**: Escala pulava de A direto para D
- **Confusão conceitual**: Mistura de "tarefas" e "objetivos/metas" na mesma categoria

### Solução Implementada

#### 1. NOVA HIERARQUIA DE RANKS

**Estrutura Anterior:**
```
S: Objetivos Sagrados (3 máx)
A: Tarefas Importantes (100 XP)
D: Tarefas Médias (50 XP)
E: Tarefas Simples (25 XP)
```

**Nova Estrutura:**
```
S: Objetivos Sagrados (3 máx) - 0 XP
A: Metas Secundárias (objetivos menores) - 0 XP
C: Tarefas Importantes (100 XP)
D: Tarefas Médias (50 XP)
E: Tarefas Simples (25 XP)
```

**Conceitos:**
- **S e A:** Objetivos/Metas (não dão XP direto)
- **C, D, E:** Tarefas (dão XP)

#### 2. ENUM TASKRANK ATUALIZADO

**Arquivo:** `lib/core/utils/constants.dart`

```dart
/// Ranks disponíveis para tarefas e objetivos
enum TaskRank {
  s, // Sagrado (Objetivo principal - limitado a 3)
  a, // Objetivo secundário (Metas menores que S)
  c, // Alto (Tarefas mais importantes)
  d, // Médio (Tarefas medianas)
  e, // Baixo (Tarefas simples)
}
```

**Mudanças:**
- Comentário do enum: "tarefas" → "tarefas e objetivos"
- Rank A: "Alto (Tarefas importantes)" → "Objetivo secundário (Metas menores que S)"
- Adicionado: Rank C

#### 3. VALORES DE XP ATUALIZADOS

**Arquivo:** `lib/core/utils/constants.dart`

```dart
/// Valores de XP por rank
class XpValues {
  static const int rankS = 0; // Objetivos S não dão XP direto
  static const int rankA = 0; // Metas A não dão XP direto (são objetivos)
  static const int rankC = 100; // Tarefas importantes
  static const int rankD = 50; // Tarefas médias
  static const int rankE = 25; // Tarefas simples
}
```

**Mudanças:**
- `rankA`: De 100 XP para 0 XP (agora é objetivo, não tarefa)
- Adicionado: `rankC = 100` (assumiu o papel do antigo rank A)
- Comentários atualizados para refletir nova estrutura

#### 4. CORES DOS RANKS

**Arquivo:** `lib/core/theme/app_colors.dart`

```dart
// Ranks
static const Color rankS = Color(0xFFFFD700); // Dourado - Objetivos Sagrados
static const Color rankA = Color(0xFFFF6B35); // Laranja - Objetivos Secundários
static const Color rankC = Color(0xFFFF5252); // Vermelho - Tarefas Importantes
static const Color rankD = Color(0xFF2196F3); // Azul - Tarefas Médias
static const Color rankE = Color(0xFF4CAF50); // Verde - Tarefas Simples
```

**Mudanças:**
- `rankA`: Nova cor Laranja (#FF6B35) - diferencia de S mas mantém status de objetivo
- `rankC`: Vermelho (#FF5252) - assumiu a cor do antigo rank A
- Comentários descritivos adicionados a todas as cores

**Paleta de Cores por Rank:**

| Rank | Cor | Hex | Significado |
|------|-----|-----|-------------|
| S | Dourado | #FFD700 | Objetivos Sagrados |
| A | Laranja | #FF6B35 | Objetivos Secundários |
| C | Vermelho | #FF5252 | Tarefas Importantes |
| D | Azul | #2196F3 | Tarefas Médias |
| E | Verde | #4CAF50 | Tarefas Simples |

#### 5. TUTORIAL DO ONBOARDING ATUALIZADO

**Arquivo:** `lib/features/onboarding/presentation/onboarding_screen.dart`

**Antes:**
```dart
description:
  'S: Objetivos Sagrados (3 máx)\n'
  'A: Tarefas Importantes (100 XP)\n'
  'D: Tarefas Médias (50 XP)\n'
  'E: Tarefas Simples (25 XP)'
```

**Depois:**
```dart
description:
  'S: Objetivos Sagrados (3 máx)\n'
  'A: Metas Secundárias (objetivos menores)\n'
  'C: Tarefas Importantes (100 XP)\n'
  'D: Tarefas Médias (50 XP)\n'
  'E: Tarefas Simples (25 XP)'
```

### Arquivos Modificados

#### Modificados
- `lib/core/utils/constants.dart`
  - Enum `TaskRank`: Adicionado rank C, comentário do A atualizado
  - Classe `XpValues`: Adicionado `rankC = 100`, `rankA` mudou para 0

- `lib/core/theme/app_colors.dart`
  - `rankA`: Nova cor Laranja (#FF6B35)
  - Adicionado: `rankC` Vermelho (#FF5252)
  - Comentários descritivos adicionados

- `lib/features/onboarding/presentation/onboarding_screen.dart`
  - Card "SISTEMA DE RANKS": Descrição atualizada com rank C

#### Documentação
- `historico_da_ia/14_2025-01-14_adicao_rank_c.md` (criado)
- `historico_da_ia/README.md` (atualizado)

### Comparação: Antes vs Depois

#### Hierarquia

| Rank | Antes | Depois | XP |
|------|-------|--------|-----|
| **S** | Objetivos Sagrados | Objetivos Sagrados | 0 |
| **A** | Tarefas Importantes | **Metas Secundárias** | ~~100~~ → **0** |
| **C** | ❌ Não existia | **Tarefas Importantes** | **100** |
| **D** | Tarefas Médias | Tarefas Médias | 50 |
| **E** | Tarefas Simples | Tarefas Simples | 25 |

#### Cores

| Rank | Cor Antes | Cor Depois | Mudança |
|------|-----------|------------|---------|
| S | Dourado | Dourado | - |
| A | Vermelho | **Laranja** | ✅ Nova cor |
| C | - | **Vermelho** | ✅ Novo rank |
| D | Azul | Azul | - |
| E | Verde | Verde | - |

### Conceitos Clarificados

#### OBJETIVOS (S e A) - Não dão XP direto
- **Rank S:** Objetivos Sagrados (máximo 3)
  - Os pilares da jornada
  - Conquistas de longo prazo
  
- **Rank A:** Metas Secundárias
  - Objetivos menores que S
  - Ainda são metas/objetivos, não tarefas

#### TAREFAS (C, D, E) - Dão XP
- **Rank C:** Tarefas Importantes (100 XP)
  - Tarefas complexas e impactantes
  
- **Rank D:** Tarefas Médias (50 XP)
  - Tarefas cotidianas regulares
  
- **Rank E:** Tarefas Simples (25 XP)
  - Tarefas rápidas e fáceis

### Impacto em Outros Sistemas

#### Shadow System
- Extração de shadows: Mantido "Complete tarefas Rank A ou objetivos S"
- **Atenção:** Precisa ser atualizado para "Rank C" ao invés de "Rank A" no futuro

#### Daily Quests
- Podem usar ranks C, D, E para tarefas diárias

#### Trophy System
- Conquistas podem estar vinculadas a qualquer rank

### Impacto no Plano Original
⚠️ **Pequeno desvio do plano.** O plano original não especificava rank C. Esta adição:
- Melhora a clareza conceitual (objetivos vs tarefas)
- Cria hierarquia mais completa (S-A-C-D-E)
- Não afeta arquitetura ou funcionalidade existente
- Requer atualização de textos relacionados a ranks

### Próximos Passos
1. ✅ Atualizar enum TaskRank
2. ✅ Atualizar XpValues
3. ✅ Adicionar cor rankC
4. ✅ Atualizar tutorial do onboarding
5. ⚠️ TODO: Atualizar descrição do Shadow System (menciona rank A para tarefas)
6. ⚠️ TODO: Revisar todos os textos que mencionam ranks A, C, D, E
7. ⚠️ TODO: Atualizar UI de criação de tarefas para incluir rank C

### Status
✅ **Código compila sem erros**
✅ **Rank C adicionado ao enum**
✅ **Valores de XP atualizados**
✅ **Cor laranja para rank A**
✅ **Cor vermelha para rank C**
✅ **Tutorial atualizado**
⚠️ **Shadow System precisa atualização**

---

## Checklist de Conformidade

### Enum TaskRank
- ✅ Adicionado rank C
- ✅ Comentários atualizados
- ✅ Ordem correta (s, a, c, d, e)

### XpValues
- ✅ rankA = 0 (é objetivo agora)
- ✅ rankC = 100 (assumiu papel do A)
- ✅ rankD e rankE mantidos

### AppColors
- ✅ rankA: Laranja (#FF6B35)
- ✅ rankC: Vermelho (#FF5252)
- ✅ Comentários descritivos

### Onboarding Tutorial
- ✅ Descrição do rank C adicionada
- ✅ Descrição do rank A atualizada
- ✅ Ordem correta (S, A, C, D, E)

---

## Detalhes Técnicos

### Cor Laranja para Rank A

**Por que Laranja?**
- Está entre Dourado (S) e Vermelho (C) no espectro
- Indica nível intermediário entre objetivos sagrados e tarefas
- Mantém identidade visual distinta

**Hex Code:** #FF6B35
- R: 255 (máximo)
- G: 107 (médio)
- B: 53 (baixo)
- Resultado: Laranja vibrante mas não chocante

### Escala de Cores por Importância

```
S (Dourado)  #FFD700  ████████  Mais importante
    ↓
A (Laranja)  #FF6B35  ████████
    ↓
C (Vermelho) #FF5252  ████████
    ↓
D (Azul)     #2196F3  ████████
    ↓
E (Verde)    #4CAF50  ████████  Menos importante
```

### Quebra de Compatibilidade

**Código Afetado:**
- Qualquer lugar que referencia `TaskRank.a` assumindo que é tarefa
- Queries que filtram por rank A esperando tarefas
- UI que mostra "Tarefas Rank A"

**Solução:**
- Revisar todos os usos de `TaskRank.a`
- Substituir por `TaskRank.c` onde apropriado
- Atualizar textos de UI

---

## Observações Finais

Esta mudança traz maior clareza ao sistema de ranks ao separar explicitamente:

1. **OBJETIVOS (S e A):** Metas de longo prazo que não dão XP direto
2. **TAREFAS (C, D, E):** Ações diárias que dão XP

A adição do rank C preenche uma lacuna na hierarquia e permite que o rank A seja usado apropriadamente para objetivos secundários, alinhando melhor o sistema com a filosofia do app.

**Rank C** se torna o novo ponto de entrada para "tarefas importantes", enquanto **Rank A** assume seu papel natural como objetivos que estão um nível abaixo dos sagrados S.
