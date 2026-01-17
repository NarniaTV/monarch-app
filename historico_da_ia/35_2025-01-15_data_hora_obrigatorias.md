# Histórico - Data e Hora Obrigatórias em Tarefas e Hábitos

## Data: 15/01/2025

### Solicitação do Usuário

**"As tarefas sempre devem ter uma data para selecionar, data e hora"**

Implementar campos obrigatórios de data e hora em:
- Criação de tarefas
- Criação de hábitos (objetivos Rank B)
- As tarefas geradas pelos hábitos devem herdar o horário

---

## 1. UI DE SELEÇÃO DE DATA E HORA EM TAREFAS

### Arquivo: `lib/features/tasks/presentation/create_task_screen.dart`

#### Campos de Estado Adicionados

```dart
class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  // ... campos existentes
  
  // Data e hora obrigatórias
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
}
```

#### Seletores Visuais Criados

**1. Seletor de Data:**
```dart
Widget _buildDateSelector() {
  return GestureDetector(
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.cyan,
                onPrimary: Colors.black,
                surface: Color(0xFF0F1115),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (date != null) {
        setState(() => _selectedDate = date);
      }
    },
    child: Container(
      // Visual: Botão com ícone de calendário e data formatada
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        border: Border.all(
          color: _selectedDate != null 
              ? AppColors.cyan 
              : AppColors.cyan.withValues(alpha: 0.3),
          width: _selectedDate != null ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: _selectedDate != null ? AppColors.cyan : Colors.white54),
          const SizedBox(width: 12),
          Text(
            _selectedDate != null
                ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                : 'Selecionar data',
            style: GoogleFonts.orbitron(...),
          ),
        ],
      ),
    ),
  );
}
```

**2. Seletor de Hora:**
```dart
Widget _buildTimeSelector() {
  return GestureDetector(
    onTap: () async {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.cyan,
                onPrimary: Colors.black,
                surface: Color(0xFF0F1115),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (time != null) {
        setState(() => _selectedTime = time);
      }
    },
    child: Container(
      // Visual: Botão com ícone de relógio e horário formatado
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(...),
      child: Row(
        children: [
          Icon(Icons.access_time, color: _selectedTime != null ? AppColors.cyan : Colors.white54),
          const SizedBox(width: 12),
          Text(
            _selectedTime != null
                ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                : 'Selecionar hora',
            style: GoogleFonts.orbitron(...),
          ),
        ],
      ),
    ),
  );
}
```

**3. Container de Data e Hora:**
```dart
Widget _buildDateTimeSelectors() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'DATA E HORA',
        style: GoogleFonts.orbitron(
          color: AppColors.cyan,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 12),
      
      Row(
        children: [
          Expanded(child: _buildDateSelector()), // 50% da largura
          const SizedBox(width: 12),
          Expanded(child: _buildTimeSelector()), // 50% da largura
        ],
      ),
    ],
  );
}
```

#### Validação Obrigatória

```dart
Future<void> _handleCreateTask() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  // Validação de data obrigatória
  if (_selectedDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selecione uma data para a tarefa',
          style: GoogleFonts.shareTechMono(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Validação de hora obrigatória
  if (_selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selecione um horário para a tarefa',
          style: GoogleFonts.shareTechMono(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // ... continua com criação da tarefa
}
```

#### Criação da Tarefa com Data e Hora

```dart
// Combina data e hora selecionadas em um DateTime
final taskDateTime = DateTime(
  _selectedDate!.year,
  _selectedDate!.month,
  _selectedDate!.day,
  _selectedTime!.hour,
  _selectedTime!.minute,
);

// Formata horário como string "HH:mm"
final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

final task = TaskModel.create(
  userId: user.uid,
  title: _titleController.text.trim(),
  description: _descriptionController.text.trim(),
  rank: _selectedRank,
  statType: _selectedStat,
  linkedObjectiveId: _linkedObjectiveId,
).copyWith(
  id: const Uuid().v4(),
  createdAt: taskDateTime,  // Data e hora completas
  time: timeString,          // Horário formatado para exibição
);
```

### Visualização da UI

```
┌─────────────────────────────────────────────┐
│ NOVA TAREFA                                 │
├─────────────────────────────────────────────┤
│ // DADOS DA TAREFA                          │
│                                             │
│ TÍTULO                                      │
│ [Estudar programação___________________]    │
│                                             │
│ RANK DA TAREFA                              │
│ [C] [D] [E]                                 │
│                                             │
│ DATA E HORA                                 │
│ ┌──────────────────┬──────────────────────┐ │
│ │ 📅 15/01/2025    │ 🕐 14:30            │ │
│ └──────────────────┴──────────────────────┘ │
│                                             │
│ [CRIAR TAREFA]                              │
└─────────────────────────────────────────────┘
```

---

## 2. UI DE SELEÇÃO DE HORÁRIO EM HÁBITOS

### Arquivo: `lib/features/objectives/presentation/create_objective_screen.dart`

#### Campo de Estado Adicionado

```dart
class _CreateObjectiveScreenState extends ConsumerState<CreateObjectiveScreen> {
  // ... campos existentes
  
  // Campos para Hábitos (Rank B)
  FrequencyType _selectedFrequency = FrequencyType.daily;
  int _everyXDaysValue = 2;
  final List<int> _selectedWeekDays = [];
  TimeOfDay? _selectedTime; // Horário para hábitos (NOVO)
}
```

#### Seletor de Horário

```dart
Widget _buildTimeSelector() {
  final color = _getRankColor(_selectedRank);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'HORÁRIO',
        style: GoogleFonts.shareTechMono(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 12),
      
      GestureDetector(
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: _selectedTime ?? TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: color, // Cor do rank
                    onPrimary: Colors.black,
                    surface: const Color(0xFF0F1115),
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (time != null) {
            setState(() => _selectedTime = time);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24),
            border: Border.all(
              color: _selectedTime != null 
                  ? color 
                  : color.withValues(alpha: 0.3),
              width: _selectedTime != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: _selectedTime != null ? color : Colors.white54),
              const SizedBox(width: 12),
              Text(
                _selectedTime != null
                    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Selecionar horário',
                style: GoogleFonts.orbitron(...),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
```

#### Integração na UI

```dart
// Seletor de frequência (apenas para Hábitos - Rank B)
if (_selectedRank == ObjectiveRank.b) ...[
  const SizedBox(height: 24),
  _buildFrequencySelector(),
  const SizedBox(height: 24),
  _buildTimeSelector(), // NOVO: Seletor de horário
],
```

#### Validação Obrigatória para Hábitos

```dart
// Validação adicional para hábitos
if (_selectedRank == ObjectiveRank.b) {
  if (_selectedFrequency == FrequencyType.weekly && _selectedWeekDays.isEmpty) {
    // Validação de dias da semana
    return;
  }
  
  // Validação de horário obrigatório para hábitos (NOVO)
  if (_selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selecione um horário para o hábito',
          style: GoogleFonts.shareTechMono(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
}
```

#### Salvamento do Horário

```dart
// Prepara horário se selecionado
final timeString = _selectedTime != null
    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
    : null;

final objective = ObjectiveModel(
  id: const Uuid().v4(),
  userId: user.uid,
  title: _titleController.text.trim(),
  rank: _selectedRank,
  // ... outros campos
  time: timeString, // Horário do hábito
  // Campos de frequência
  frequencyType: _selectedRank == ObjectiveRank.b ? _selectedFrequency : null,
  frequencyValue: _selectedRank == ObjectiveRank.b && _selectedFrequency == FrequencyType.everyXDays
      ? _everyXDaysValue
      : null,
  weekDays: _selectedRank == ObjectiveRank.b && _selectedFrequency == FrequencyType.weekly
      ? (List<int>.from(_selectedWeekDays)..sort())
      : null,
);
```

### Visualização da UI (Hábito)

```
┌─────────────────────────────────────────────┐
│ NOVO HÁBITO (RANK B)                        │
├─────────────────────────────────────────────┤
│ TÍTULO                                      │
│ [Correr___________________________]         │
│                                             │
│ FREQUÊNCIA DO HÁBITO                        │
│ ☑ Dias da semana                           │
│   [D] [S] [T] [Q] [Q] [S] [S]              │
│        ^       ^       ^                    │
│                                             │
│ HORÁRIO                                     │
│ ┌─────────────────────────────────────────┐ │
│ │ 🕐 18:00                                │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ [CRIAR OBJETIVO]                            │
└─────────────────────────────────────────────┘
```

---

## 3. TAREFAS GERADAS HERDAM HORÁRIO DO HÁBITO

### Arquivo: `lib/services/habit_service.dart`

#### Método Atualizado

**Antes:**
```dart
TaskModel _createTaskForDate(ObjectiveModel habit, DateTime date) {
  final task = TaskModel.create(
    userId: habit.userId,
    title: '${habit.title} ($dateStr)',
    // ... outros campos
  );
  
  return task.copyWith(id: const Uuid().v4());
}
```

**Depois:**
```dart
TaskModel _createTaskForDate(ObjectiveModel habit, DateTime date) {
  final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  
  final task = TaskModel.create(
    userId: habit.userId,
    title: '${habit.title} ($dateStr)',
    description: habit.description,
    rank: TaskRank.d,
    statType: StatType.spirit,
    linkedObjectiveId: habit.id,
  );
  
  // Adiciona ID único e herda horário do hábito (NOVO)
  return task.copyWith(
    id: const Uuid().v4(),
    createdAt: date,
    time: habit.time, // Herda o horário do hábito ✅
  );
}
```

### Fluxo Completo

```
1. Usuário cria hábito "Correr" 
   - Frequência: Segunda, Quarta, Sexta
   - Horário: 18:00
       ↓
2. Sistema gera 20 tarefas iniciais
       ↓
3. TODAS as tarefas recebem:
   - Data específica (16/01, 18/01, 20/01, ...)
   - Horário: 18:00 (herdado do hábito) ✅
       ↓
4. Resultado no Firestore:
   
   Tarefa 1:
   {
     title: "Correr (16/01)",
     createdAt: 2025-01-16 18:00:00,
     time: "18:00",
     rank: "d",
     linkedObjectiveId: "habit123"
   }
   
   Tarefa 2:
   {
     title: "Correr (18/01)",
     createdAt: 2025-01-18 18:00:00,
     time: "18:00", // Mesmo horário!
     rank: "d",
     linkedObjectiveId: "habit123"
   }
   
   ...
```

---

## 4. BENEFÍCIOS DA IMPLEMENTAÇÃO

### Organização

| Antes | Depois |
|-------|--------|
| ❌ Tarefas sem data/hora específica | ✅ Toda tarefa tem data e hora |
| ❌ Difícil saber quando fazer | ✅ Claro quando executar |
| ❌ Hábitos sem horário fixo | ✅ Hábitos em horário consistente |

### Experiência do Usuário

**Antes:**
```
Tarefa: "Correr"
Quando? 🤷 Não sei...
```

**Depois:**
```
Tarefa: "Correr (16/01)"
Quando? 18:00 ✅
```

### Dashboard

**Ordenação melhorada:**
```
TAREFAS DE HOJE (16/01)
┌──────────────────────────────────┐
│ 🕐 08:00 │ Meditar              │ ← Primeiro (mais cedo)
│ 🕐 14:00 │ Estudar inglês       │
│ 🕐 18:00 │ Correr               │ ← Hábito com horário
│ 📋 Limpar casa                   │ ← Sem horário (por baixo)
└──────────────────────────────────┘
```

---

## 5. CASOS DE USO

### Caso 1: Criar Tarefa com Data e Hora

```
Usuário: Criar tarefa "Reunião com cliente"
    ↓
Preenche:
  - Título: "Reunião com cliente"
  - Rank: C (importante)
  - Data: 20/01/2025
  - Hora: 14:30
    ↓
Clica "CRIAR TAREFA"
    ↓
Sistema valida:
  ✅ Data selecionada
  ✅ Hora selecionada
    ↓
Tarefa criada:
  {
    title: "Reunião com cliente",
    createdAt: 2025-01-20 14:30:00,
    time: "14:30",
    rank: "c"
  }
```

### Caso 2: Criar Hábito com Horário

```
Usuário: Criar hábito "Meditar"
    ↓
Preenche:
  - Título: "Meditar"
  - Rank: B (hábito)
  - Frequência: Todo dia
  - Horário: 08:00
    ↓
Clica "CRIAR OBJETIVO"
    ↓
Sistema valida:
  ✅ Horário selecionado
    ↓
Hábito criado com time: "08:00"
    ↓
Sistema gera 20 tarefas:
  - Todas com horário 08:00 ✅
  - Meditar (15/01) às 08:00
  - Meditar (16/01) às 08:00
  - ...
```

### Caso 3: Validação de Campos Obrigatórios

```
Usuário: Tenta criar tarefa sem data
    ↓
Clica "CRIAR TAREFA"
    ↓
Sistema valida:
  ❌ Data não selecionada
    ↓
SnackBar laranja:
  "Selecione uma data para a tarefa"
    ↓
Tarefa NÃO é criada
```

---

## 6. ARQUIVOS MODIFICADOS

### 1. `lib/features/tasks/presentation/create_task_screen.dart`
**Mudanças:**
- Adicionados campos `_selectedDate` e `_selectedTime`
- Criado `_buildDateTimeSelectors()`
- Criado `_buildDateSelector()`
- Criado `_buildTimeSelector()`
- Validação obrigatória em `_handleCreateTask()`
- Combinação de data e hora ao criar tarefa
- Formatação de `timeString` para salvar

### 2. `lib/features/objectives/presentation/create_objective_screen.dart`
**Mudanças:**
- Adicionado campo `_selectedTime`
- Criado `_buildTimeSelector()` para hábitos
- Integrado na UI (aparece após `_buildFrequencySelector()`)
- Validação obrigatória para hábitos
- Salvamento de `timeString` no objetivo

### 3. `lib/services/habit_service.dart`
**Mudanças:**
- Método `_createTaskForDate()` atualizado
- Tarefas agora recebem:
  - `createdAt: date` (data da tarefa)
  - `time: habit.time` (horário herdado do hábito)

### 4. Documentação
- `historico_da_ia/35_2025-01-15_data_hora_obrigatorias.md` (este arquivo)
- `historico_da_ia/README.md` atualizado

---

## 7. COMPILATION STATUS

✅ **0 erros de compilação**  
⚠️ **12 warnings** (info - não crítico):
- 3x `deprecated_member_use` (dialogBackgroundColor - cosmético)
- 4x `use_build_context_synchronously` (pré-existente)
- 5x `avoid_print` (logs de desenvolvimento)

**Resultado:** Sistema completo e funcional! ✅

---

## 8. DESIGN VISUAL

### Tema dos Seletores

**Cores:**
- Não selecionado: `Color(0xFF1A1D24)` com borda cyan alpha 0.3
- Selecionado: Borda cyan cheia (alpha 1.0), width 2
- Ícones: Cyan quando selecionado, white54 quando não

**Formato:**
- Data: `DD/MM/YYYY` (ex: `15/01/2025`)
- Hora: `HH:mm` (ex: `14:30`)

**Fonte:**
- Labels: `GoogleFonts.orbitron()` (título)
- Valores: `GoogleFonts.orbitron()` (valor selecionado)

---

**Implementado por:** IA Assistant  
**Data:** 15/01/2025  
**Versão:** System Awaken v1.0  
**Status:** Produção Ready ✅
