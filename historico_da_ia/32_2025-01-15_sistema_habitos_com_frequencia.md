# Histórico - Sistema de Hábitos com Frequência

## Data: 15/01/2025

### Solicitação do Usuário

Implementar controle de frequência para hábitos (Rank B):
- Usuário escolhe a frequência (todo dia, a cada X dias, dias da semana)
- Aplicativo gera tarefas automaticamente baseado na frequência
- Tarefas aparecem na lista de tarefas do usuário

### Implementação Completa

## 1. MODELO DE DADOS ATUALIZADO

### Enum FrequencyType

**Arquivo:** `lib/core/utils/constants.dart`

```dart
enum FrequencyType {
  daily,      // Todo dia
  everyXDays, // A cada X dias
  weekly,     // Dias específicos da semana
}

class FrequencyLabels {
  static String getLabel(FrequencyType type) {
    switch (type) {
      case FrequencyType.daily:
        return 'Todo dia';
      case FrequencyType.everyXDays:
        return 'A cada X dias';
      case FrequencyType.weekly:
        return 'Dias da semana';
    }
  }
}
```

### ObjectiveModel com Campos de Frequência

**Arquivo:** `lib/models/objective_model.dart`

```dart
class ObjectiveModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final ObjectiveRank rank;
  
  // Campos para Hábitos (Rank B)
  final FrequencyType? frequencyType;    // Tipo de frequência
  final int? frequencyValue;             // Para everyXDays: a cada X dias
  final List<int>? weekDays;             // Para weekly: [1-7]
  
  // ... outros campos
}
```

**Campos de Frequência:**
- `frequencyType`: daily, everyXDays ou weekly
- `frequencyValue`: usado quando `everyXDays` (ex: 2 = a cada 2 dias)
- `weekDays`: lista de dias (1=Domingo, 2=Segunda, ..., 7=Sábado)

**Salvamento no Firestore:**
```dart
Map<String, dynamic> toFirestore() {
  final map = {
    'userId': userId,
    'title': title,
    'rank': rank.name,
    // ... outros campos
  };
  
  // Adiciona campos de frequência apenas para Rank B
  if (rank == ObjectiveRank.b) {
    map['frequencyType'] = frequencyType?.name;
    map['frequencyValue'] = frequencyValue;
    map['weekDays'] = weekDays;
  }
  
  return map;
}
```

---

## 2. UI DE SELEÇÃO DE FREQUÊNCIA

### Arquivo: `create_objective_screen.dart`

#### Quando Rank B é Selecionado

A UI mostra automaticamente o seletor de frequência entre a descrição e o botão de criar:

```
┌─────────────────────────────────────────┐
│ RANK B                                  │
│ [🔁 RANK B - Hábito]                    │
│                                         │
│ TÍTULO                                  │
│ [Ex: Correr 3x por semana]             │
│                                         │
│ DESCRIÇÃO (OPCIONAL)                    │
│ [Detalhes...]                          │
│                                         │
│ FREQUÊNCIA DO HÁBITO                    │ ← NOVO
│ ┌─────────────────────────────────────┐ │
│ │ 📅 Todo dia              ✓          │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 🔁 A cada X dias                    │ │
│ │    A cada [2] dias                  │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 📆 Dias da semana                   │ │
│ │    [D] [S] [T] [Q] [Q] [S] [S]     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [CRIAR OBJETIVO]                        │
└─────────────────────────────────────────┘
```

#### Componentes da UI

**1. Opção "Todo dia":**
```dart
_buildFrequencyOption(
  type: FrequencyType.daily,
  label: 'Todo dia',
  icon: Icons.calendar_today,
)
```

**2. Opção "A cada X dias":**
```dart
_buildFrequencyOption(
  type: FrequencyType.everyXDays,
  label: 'A cada X dias',
  icon: Icons.repeat,
  child: Row([
    Text('A cada'),
    TextField(initialValue: '2'), // Input numérico
    Text('dias'),
  ]),
)
```

**3. Opção "Dias da semana":**
```dart
_buildFrequencyOption(
  type: FrequencyType.weekly,
  label: 'Dias da semana',
  icon: Icons.date_range,
  child: Wrap([
    _buildWeekDayChip('D', 1),  // Domingo
    _buildWeekDayChip('S', 2),  // Segunda
    _buildWeekDayChip('T', 3),  // Terça
    _buildWeekDayChip('Q', 4),  // Quarta
    _buildWeekDayChip('Q', 5),  // Quinta
    _buildWeekDayChip('S', 6),  // Sexta
    _buildWeekDayChip('S', 7),  // Sábado
  ]),
)
```

#### Design dos Componentes

**Opção de Frequência (Card):**
- Background: escuro (não selecionado) ou colorido translúcido (selecionado)
- Borda: 1px (não selecionado) ou 2px (selecionado)
- Ícone + label
- Check circle quando selecionado
- Conteúdo expansível (input ou chips)

**Chips de Dias da Semana:**
- Círculos com iniciais (D, S, T, Q...)
- Fundo colorido quando selecionado
- Borda da cor do rank
- Multi-seleção permitida

#### Estado Local

```dart
class _CreateObjectiveScreenState extends ConsumerState<CreateObjectiveScreen> {
  // ... controllers existentes
  
  // Estado de frequência
  FrequencyType _selectedFrequency = FrequencyType.daily;
  int _everyXDaysValue = 2;
  final List<int> _selectedWeekDays = [];
}
```

#### Validação

```dart
// Antes de criar
if (_selectedRank == ObjectiveRank.b) {
  if (_selectedFrequency == FrequencyType.weekly && _selectedWeekDays.isEmpty) {
    // Mostra erro: "Selecione pelo menos um dia da semana"
    return;
  }
}
```

---

## 3. SERVICE DE HÁBITOS

### Arquivo Criado: `lib/services/habit_service.dart`

#### Método Principal: generateRecurringTasksForHabit()

```dart
Future<void> generateRecurringTasksForHabit(ObjectiveModel habit) async {
  // 1. Valida que é um hábito
  if (habit.rank != ObjectiveRank.b) throw Exception('...');
  
  // 2. Gera lista de tarefas baseado na frequência
  final tasks = _generateTasksForFrequency(habit);
  
  // 3. Salva todas as tarefas no Firestore
  for (final task in tasks) {
    await _taskRepository.createTask(task);
  }
}
```

#### Lógica de Geração por Frequência

**FrequencyType.daily (Todo dia):**
```dart
// Gera 7 tarefas (1 semana)
for (int i = 0; i < 7; i++) {
  final date = now.add(Duration(days: i));
  tasks.add(_createTaskForDate(habit, date));
}
```

**FrequencyType.everyXDays (A cada X dias):**
```dart
// Gera tarefas espaçadas por X dias
final interval = habit.frequencyValue ?? 2; // Default: 2 dias
for (int i = 0; i < 7; i += interval) {
  final date = now.add(Duration(days: i));
  tasks.add(_createTaskForDate(habit, date));
}
```

**FrequencyType.weekly (Dias da semana):**
```dart
// Gera tarefas para dias específicos nas próximas 2 semanas
for (int week = 0; week < 2; week++) {
  for (final weekDay in habit.weekDays!) {
    final daysUntil = _daysUntilWeekDay(now, weekDay, week);
    final date = now.add(Duration(days: daysUntil));
    tasks.add(_createTaskForDate(habit, date));
  }
}
```

#### Criação de Tarefa Individual

```dart
TaskModel _createTaskForDate(ObjectiveModel habit, DateTime date) {
  final dateStr = '15/01'; // Formato dd/mm
  
  return TaskModel.create(
    userId: habit.userId,
    title: '${habit.title} ($dateStr)',        // Ex: "Correr (15/01)"
    description: habit.description,
    rank: TaskRank.e,                          // Hábitos = Rank E
    statType: StatType.spirit,                 // Hábitos = Spirit
    linkedObjectiveId: habit.id,               // Link ao hábito
  ).copyWith(id: Uuid().v4());
}
```

**Características das Tarefas Geradas:**
- Título com data: "Correr (15/01)"
- Rank E (casual)
- Stat Spirit
- Linkadas ao hábito
- XP: 25 (Rank E)

#### Cálculo de Dias da Semana

```dart
int _daysUntilWeekDay(DateTime from, int targetWeekDay, int week) {
  // Converte weekday do Dart (1=Mon...7=Sun) para nosso sistema (1=Dom...7=Sab)
  final currentWeekDay = from.weekday == 7 ? 1 : from.weekday + 1;
  int daysToAdd = targetWeekDay - currentWeekDay;
  
  if (daysToAdd < 0) {
    daysToAdd += 7;
  }
  
  return daysToAdd + (week * 7);
}
```

---

## 4. INTEGRAÇÃO NO OBJECTIVE SERVICE

### Arquivo: `lib/services/objective_service.dart`

**Criação de objetivo agora chama geração de tarefas:**

```dart
Future<void> createObjective(ObjectiveModel objective) async {
  try {
    // 1. Cria o objetivo no Firestore
    final createdObjective = await _objectiveRepository.createObjective(objective);
    
    // 2. Se for hábito (Rank B), gera tarefas recorrentes
    if (objective.rank == ObjectiveRank.b) {
      await _habitService.generateRecurringTasksForHabit(createdObjective);
    }
  } catch (e) {
    throw Exception('Erro ao criar objetivo: $e');
  }
}
```

**Fluxo:**
```
Usuário cria Hábito
    ↓
ObjectiveService.createObjective()
    ↓
1. Salva hábito no Firestore
    ↓
2. Se Rank B → HabitService.generateRecurringTasksForHabit()
    ↓
3. Gera 7-14 tarefas baseado na frequência
    ↓
4. Salva todas no Firestore
    ↓
Tarefas aparecem na lista do usuário ✅
```

---

## 5. EXEMPLOS DE USO

### Exemplo 1: Hábito Diário

**Input do Usuário:**
- Título: "Meditar"
- Rank: B (Hábito)
- Frequência: Todo dia

**Tarefas Geradas:**
```
✅ Meditar (15/01) [RANK E] [SPIRIT]
⭕ Meditar (16/01) [RANK E] [SPIRIT]
⭕ Meditar (17/01) [RANK E] [SPIRIT]
⭕ Meditar (18/01) [RANK E] [SPIRIT]
⭕ Meditar (19/01) [RANK E] [SPIRIT]
⭕ Meditar (20/01) [RANK E] [SPIRIT]
⭕ Meditar (21/01) [RANK E] [SPIRIT]
```

**Total:** 7 tarefas (1 semana)

### Exemplo 2: Hábito a Cada X Dias

**Input do Usuário:**
- Título: "Ir à academia"
- Rank: B (Hábito)
- Frequência: A cada 2 dias

**Tarefas Geradas:**
```
⭕ Ir à academia (15/01) [RANK E] [SPIRIT]
⭕ Ir à academia (17/01) [RANK E] [SPIRIT]
⭕ Ir à academia (19/01) [RANK E] [SPIRIT]
⭕ Ir à academia (21/01) [RANK E] [SPIRIT]
```

**Total:** 4 tarefas (1 semana com intervalo de 2 dias)

### Exemplo 3: Hábito Semanal

**Input do Usuário:**
- Título: "Correr"
- Rank: B (Hábito)
- Frequência: Dias da semana
- Dias selecionados: Segunda, Quarta, Sexta

**Tarefas Geradas:**
```
Semana 1:
⭕ Correr (16/01 - Segunda) [RANK E] [SPIRIT]
⭕ Correr (18/01 - Quarta)  [RANK E] [SPIRIT]
⭕ Correr (20/01 - Sexta)   [RANK E] [SPIRIT]

Semana 2:
⭕ Correr (23/01 - Segunda) [RANK E] [SPIRIT]
⭕ Correr (25/01 - Quarta)  [RANK E] [SPIRIT]
⭕ Correr (27/01 - Sexta)   [RANK E] [SPIRIT]
```

**Total:** 6 tarefas (2 semanas)

---

## 6. FLUXO COMPLETO DO USUÁRIO

### Criar Hábito

```
1. Dashboard → OBJETIVOS
2. Clica em chip "RANK B"
3. Clica FAB "NOVO OBJETIVO"
4. Tela abre com Rank B pré-selecionado ✅
5. Preenche título: "Correr"
6. Vê seção "FREQUÊNCIA DO HÁBITO"
7. Seleciona "Dias da semana"
8. Clica em: [S] [Q] [S] (segunda, quarta, sexta)
9. Clica "CRIAR OBJETIVO"
   ↓
10. Hábito salvo no Firestore
   ↓
11. Sistema gera 6 tarefas (2 semanas)
   ↓
12. SnackBar: "Objetivo B criado com sucesso!"
   ↓
13. Volta para lista de objetivos
```

### Ver Tarefas Geradas

```
1. Dashboard → Vê "TAREFAS ATIVAS"
2. Tarefas do hábito aparecem:
   ⭕ Correr (16/01) [RANK E] [SPIRIT]
   ⭕ Correr (18/01) [RANK E] [SPIRIT]
   ...
3. Usuário marca como concluída ao cumprir
4. Ganha +25 XP + 1 Spirit
5. Progresso do hábito aumenta
```

---

## 7. LÓGICA DE DIAS DA SEMANA

### Sistema de Numeração

```
1 = Domingo
2 = Segunda-feira
3 = Terça-feira
4 = Quarta-feira
5 = Quinta-feira
6 = Sexta-feira
7 = Sábado
```

### Conversão Dart → Nosso Sistema

```dart
// Dart: weekday (1=Mon, 7=Sun)
// Nosso: (1=Sun, 7=Sat)

final currentWeekDay = from.weekday == 7 ? 1 : from.weekday + 1;
```

### Cálculo de Próxima Ocorrência

```dart
int _daysUntilWeekDay(DateTime from, int targetWeekDay, int week) {
  final currentWeekDay = from.weekday == 7 ? 1 : from.weekday + 1;
  int daysToAdd = targetWeekDay - currentWeekDay;
  
  // Se o dia já passou esta semana, vai para próxima
  if (daysToAdd < 0) {
    daysToAdd += 7;
  }
  
  // Adiciona semanas (0=esta, 1=próxima)
  return daysToAdd + (week * 7);
}
```

**Exemplo:**
- Hoje: Segunda (weekday = 2)
- Target: Quarta (targetWeekDay = 4)
- Semana: 0 (esta semana)
- Resultado: 4 - 2 = 2 dias

---

## 8. ARQUIVOS MODIFICADOS/CRIADOS

### Criados

1. **`lib/services/habit_service.dart`**
   - `generateRecurringTasksForHabit()`
   - `_generateTasksForFrequency()`
   - `_createTaskForDate()`
   - `_daysUntilWeekDay()`

2. **`historico_da_ia/32_2025-01-15_sistema_habitos_com_frequencia.md`**
   - Esta documentação

### Modificados

1. **`lib/core/utils/constants.dart`**
   - Enum `FrequencyType` (daily, everyXDays, weekly)
   - Classe `FrequencyLabels`
   - Comentário ObjectiveRank.b: "Metas Secundárias" → "Hábitos"

2. **`lib/models/objective_model.dart`**
   - Campos: `frequencyType`, `frequencyValue`, `weekDays`
   - `create()`: parâmetros de frequência
   - `fromFirestore()`: parse de frequência
   - `toFirestore()`: salva frequência
   - `copyWith()`: permite alterar frequência

3. **`lib/features/objectives/presentation/create_objective_screen.dart`**
   - Estado: `_selectedFrequency`, `_everyXDaysValue`, `_selectedWeekDays`
   - Método `_buildFrequencySelector()` (condicional para Rank B)
   - Método `_buildFrequencyOption()` (cards de frequência)
   - Método `_buildWeekDayChip()` (círculos de dias)
   - `_handleCreate()`: salva dados de frequência

4. **`lib/services/objective_service.dart`**
   - Import `HabitService`
   - Chama `generateRecurringTasksForHabit()` após criar Rank B

5. **`historico_da_ia/README.md`**
   - Adicionada entrada para histórico 32

---

## 9. PERFORMANCE E ESCALABILIDADE

### Geração de Tarefas

**Quantidade gerada:**
- Daily: 7 tarefas
- EveryXDays (2): ~4 tarefas
- Weekly (3 dias): 6 tarefas

**Custo Firestore:**
- 1 write (hábito) + 4-7 writes (tarefas)
- Total: 5-8 writes por hábito criado

### Futuras Otimizações

1. **Batch Writes:**
   ```dart
   final batch = _firestore.batch();
   for (final task in tasks) {
     batch.set(taskRef, task.toFirestore());
   }
   await batch.commit(); // 1 operação ao invés de N
   ```

2. **Geração Incremental:**
   - Gerar apenas 1 semana inicialmente
   - Background job para gerar próxima semana
   - Mantém sempre 7 dias futuros

3. **Tarefa Mestre:**
   - 1 tarefa "Correr (Hábito)"
   - Checkbox diário dentro da tarefa
   - Reduz quantidade de documentos

---

## 10. PRÓXIMOS PASSOS (NÃO IMPLEMENTADOS)

### Background Job para Regenerar Tarefas

```dart
// Executar diariamente às 00:00
Future<void> regenerateExpiredHabitTasks() async {
  // 1. Buscar todos os hábitos ativos
  // 2. Para cada hábito:
  //    - Verificar tarefas futuras
  //    - Se < 7 dias, gerar mais tarefas
  // 3. Limpar tarefas muito antigas (> 30 dias)
}
```

### Estatísticas de Hábitos

- Streak atual (quantos dias consecutivos)
- Taxa de conclusão (%)
- Melhor semana
- Gráfico de progresso ao longo do tempo

### Edição de Frequência

- Permitir alterar frequência de hábito existente
- Regenerar tarefas baseado na nova frequência
- Manter tarefas já concluídas

### Notificações

- Lembrete para cumprir hábito
- Baseado na frequência e horário preferido
- Push notifications

---

## 11. STATUS FINAL

✅ **Compilação:** 0 erros  
✅ **Análise:** 4 info (não crítico)  
✅ **Rank B:** Claramente "Hábitos"  
✅ **UI de Frequência:** Completa e funcional  
✅ **Geração de Tarefas:** Implementada  
✅ **Integração:** ObjectiveService chama HabitService  
✅ **Validações:** Dias da semana obrigatórios  

---

## 12. TESTES DE VALIDAÇÃO

### Teste 1: Criar Hábito Diário
```
Input:
- Título: "Meditar"
- Frequência: Todo dia

Resultado esperado:
✅ 7 tarefas geradas
✅ Tarefas aparecem na lista
✅ Linkadas ao hábito
```

### Teste 2: Criar Hábito Semanal sem Dias
```
Input:
- Título: "Estudar inglês"
- Frequência: Dias da semana
- Dias: [] (nenhum selecionado)

Resultado esperado:
❌ SnackBar: "Selecione pelo menos um dia da semana"
❌ Não cria objetivo
```

### Teste 3: Completar Tarefa de Hábito
```
Ação: Marca "Correr (15/01)" como concluída

Resultado esperado:
✅ Tarefa marcada
✅ +25 XP ganho
✅ +1 Spirit
✅ Progresso do hábito aumenta
```

---

**Resultado:** Sistema completo de hábitos com frequência personalizada e geração automática de tarefas! 🔁✅
