# Histórico - Refatoração Dashboard + FAB Fixo

## Data: 15/01/2025

### Mudanças Solicitadas pelo Usuário

1. **Dashboard:** Mostrar tarefas ao invés de objetivos (tarefas são mais usadas)
2. **FAB Fixo:** Botão "+" fixo no centro inferior para criar tarefas
3. **Remover botão TAREFAS:** Das ações rápidas (manter só OBJETIVOS e STATS)
4. **Renomear Rank B:** De "Metas Secundárias" para "Hábitos"
5. **Hábitos com frequência:** Sistema automático de repetição
6. **Objetivos A com tarefas:** Permitir adicionar tarefas linkadas ao criar Objetivo A
7. **Nova semântica clara:**
   - S → Metas de vida grandes (comprar carro, abrir empresa)
   - A → Metas a serem alcançadas (com tarefas menores)
   - B → Hábitos (com frequência: diário, 2 em 2 dias, etc)
   - C → Tarefas importantes
   - D → Tarefas normais
   - E → Tarefas casuais

## Mudanças Implementadas (Parte 1)

### 1. Dashboard - Tarefas ao Invés de Objetivos

**Antes:**
- Mostrava seção "OBJETIVOS SAGRADOS" com objetivos Rank S
- Botão "VER MAIS" para ir à tela de objetivos

**Depois:**
- Mostra seção "TAREFAS ATIVAS" com tarefas C, D, E
- Botão "VER TODAS" para ir à tela de tarefas
- Mostra as 5 primeiras tarefas ativas
- Com checkbox para marcar como concluída
- Tags de rank e stat type

**Código implementado:**
```dart
Widget _buildTasksSection() {
  final activeTasksAsync = ref.watch(activeTasksProvider);

  return Container(
    // ... design tático
    child: Column(
      children: [
        // Header com "TAREFAS ATIVAS"
        Container(...),
        
        // Lista de tarefas (5 primeiras)
        activeTasksAsync.when(
          loading: () => CircularProgressIndicator(),
          error: (e, s) => Text('Erro'),
          data: (tasks) {
            final displayTasks = tasks.take(5).toList();
            return Column(
              children: displayTasks.map(_buildTaskCard).toList(),
            );
          },
        ),
      ],
    ),
  );
}
```

**Card de Tarefa:**
- Checkbox circular para completar
- Título da tarefa
- Tags: Rank (C/D/E) + Stat (Power/Mind/Spirit)
- Ao completar: SnackBar com "+X XP"

### 2. FAB Fixo no Centro Inferior

**Implementação:**
```dart
// No Scaffold, dentro de um Stack
Positioned(
  left: 0,
  right: 0,
  bottom: 20,
  child: Center(
    child: _buildFixedFAB(),
  ),
),

Widget _buildFixedFAB() {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.cyan.withValues(alpha: 0.4),
          blurRadius: 20,
          spreadRadius: 5,
        ),
      ],
    ),
    child: FloatingActionButton(
      onPressed: () => context.push('/tasks/create'),
      backgroundColor: AppColors.cyan,
      child: const Icon(Icons.add, color: Colors.black, size: 32),
    ),
  );
}
```

**Características:**
- Sempre visível (sobrepõe conteúdo)
- Posicionado no centro inferior (20px do bottom)
- Glow cyan ao redor
- Navega para `/tasks/create`
- Ícone `+` grande (32px)

### 3. Remoção do Botão TAREFAS

**Antes:**
```dart
_buildQuickActions() {
  Row([
    _buildActionButton('OBJETIVOS'),
    _buildActionButton('TAREFAS'),  // ← REMOVIDO
  ]);
  Row([
    _buildActionButton('STATS'),
  ]);
}
```

**Depois:**
```dart
_buildQuickActions() {
  Row([
    _buildActionButton('OBJETIVOS'),
    _buildActionButton('STATS'),
  ]);
}
```

**Motivo:** FAB fixo já permite criar tarefas, e a seção do dashboard mostra tarefas

### Arquivos Modificados (Parte 1)

1. **`lib/features/dashboard/presentation/dashboard_screen.dart`**
   - Método `_buildObjectivesSection` substituído por `_buildTasksSection`
   - Adicionado método `_buildTaskCard` para cards de tarefas
   - Adicionado `_buildFixedFAB` com posicionamento absoluto
   - Removido botão "TAREFAS" das ações rápidas
   - Imports atualizados (TaskModel, task_provider)
   - Métodos auxiliares: `_getTaskRankColor`, `_getStatColor`, `_buildTaskTag`, `_toggleTaskCompletion`

2. **`historico_da_ia/30_2025-01-15_refatoracao_dashboard_e_fab_fixo.md`**
   - Esta documentação (Parte 1)

## Próximos Passos (Parte 2 - Pendente)

### 4. Renomear Rank B para "Hábitos"

**Arquivos a modificar:**
- `lib/features/objectives/presentation/objectives_screen.dart`
  - "Metas Secundárias" → "Hábitos"
  - "Secundárias" → "Hábitos"
  - Subtitle: "Secundárias" → "Hábitos"
  
- `lib/features/objectives/presentation/create_objective_screen.dart`
  - Labels e placeholders contextuais
  - Info card: "Metas B complementam..." → "Hábitos são ações repetidas regularmente..."

### 5. Adicionar Sistema de Frequência para Hábitos

**Modelo:**
```dart
class ObjectiveModel {
  final ObjectiveRank rank;
  final FrequencyType? frequency; // Para Rank B (hábitos)
  final int? frequencyValue;     // Ex: a cada X dias
}

enum FrequencyType {
  daily,      // Todo dia
  everyXDays, // A cada X dias
  weekly,     // Semanal (escolher dias da semana)
  monthly,    // Mensal
}
```

**Tela de Criação (quando B selecionado):**
- Mostrar seletor de frequência
- Opções: Diário, A cada X dias, Semanal, Mensal
- Se "A cada X dias": mostrar input numérico
- Se "Semanal": mostrar checkboxes de dias da semana

**Sistema de Geração Automática:**
- Service para gerar tarefas recorrentes baseado na frequência
- Tarefa automática linkada ao hábito
- Checkbox diário para marcar como cumprido

### 6. Objetivos A com Tarefas Linkadas

**Fluxo:**
1. Usuário cria Objetivo A
2. Após salvar, perguntar: "Deseja adicionar tarefas para esta meta?"
3. Se sim, abrir modal ou navegar para tela de adicionar tarefas
4. Permitir adicionar múltiplas tarefas (C, D, E) linkadas ao objetivo A

**Alternativa (mais simples):**
- Ao criar Objetivo A, mostrar seção "TAREFAS PARA ESTA META (OPCIONAL)"
- Botão "+ ADICIONAR TAREFA"
- Inputs inline para adicionar 1-N tarefas

### 7. Atualizar Semântica em Toda a UI

**Labels a atualizar:**

**Objetivos S:**
- "Objetivos Sagrados" → "METAS DE VIDA"
- Descrição: "Suas metas mais importantes" → "Suas grandes conquistas de vida"
- Placeholder: "Ser fluente em inglês" → "Comprar carro dos sonhos"

**Objetivos A:**
- "Metas Principais" → "METAS A ALCANÇAR"
- Descrição: "Objetivos principais..." → "Metas com tarefas menores para alcançar"
- Placeholder: "Concluir curso de Flutter" → "Conquistar promoção no trabalho"

**Objetivos B:**
- "Metas Secundárias" → "HÁBITOS"
- Descrição: "Complementam..." → "Ações repetidas regularmente para melhorar sua vida"
- Placeholder: "Ler 1 livro por mês" → "Correr 3x por semana"

**Tarefas C/D/E:**
- C: "Tarefas Importantes" → Mantém
- D: "Tarefas Médias" → "Tarefas Normais"
- E: "Tarefas Simples" → "Tarefas Casuais"

## Status Atual

✅ **Dashboard com tarefas** - Implementado
✅ **FAB fixo no centro** - Implementado
✅ **Botão TAREFAS removido** - Implementado
⏳ **Renomear B para Hábitos** - Pendente
⏳ **Sistema de frequência** - Pendente
⏳ **Objetivos A com tarefas** - Pendente
⏳ **Atualizar semântica** - Pendente

## Observações

1. **Performance:** Stream de tarefas é eficiente (provider cacheado)
2. **UX:** FAB fixo permite criar tarefas de qualquer lugar do dashboard
3. **Design:** Mantém padrão Tactical HUD consistente
4. **Feedback:** SnackBar ao completar tarefa informa XP ganho

---

**Resultado (Parte 1):** Dashboard agora destaca tarefas (mais usadas) com acesso rápido via FAB fixo! 🎯✨

**Próxima fase:** Implementar sistema de hábitos com frequência e nova semântica completa.
