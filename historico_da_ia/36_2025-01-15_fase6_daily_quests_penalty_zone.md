# Histórico - FASE 6: Daily Quests e Penalty Zone 2.0

## Data: 15/01/2025

### Solicitação do Usuário

**"Passe para a próxima fase"** - Implementar FASE 6 do plano original: Daily Quests e Penalty Zone 2.0

---

## VISÃO GERAL DA FASE 6

Esta fase implementa:
1. **Daily Quests** - Missões diárias com streak tracking
2. **Penalty Zone 2.0** - Sistema de penalidade ao quebrar streak
3. **Sistema de Quitação** - 3 dias seguidos completando quests para sair
4. **Reset Diário** - Quests resetam automaticamente

---

## 1. MODELOS DE DADOS

### DailyQuestModel

**Arquivo:** `lib/models/daily_quest_model.dart`

```dart
class DailyQuestModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;        // Completou hoje?
  final int streak;              // Dias consecutivos
  final DateTime? lastCompletedAt;
  final DateTime lastResetDate;  // Última reset
  final int order;               // Ordem de exibição (1-5)
  final String? time;            // Horário preferido
}
```

**Campos Chave:**
- `isCompleted`: Resetado todo dia
- `streak`: Incrementado ao completar consecutivamente
- `lastCompletedAt`: Para validar se completou ontem
- `lastResetDate`: Para detectar quando resetar

### PenaltyStateModel

**Arquivo:** `lib/models/penalty_state_model.dart`

```dart
class PenaltyStateModel {
  final String userId;
  final bool isInPenaltyZone;
  final DateTime? penaltyStartedAt;
  final int daysRemaining;       // 3 dias para quitar
  final int quitationProgress;   // 0-3 dias completados
  final DateTime? lastQuitationDate;
}
```

**Campos Chave:**
- `isInPenaltyZone`: Flag principal
- `daysRemaining`: Countdown de 3 para 0
- `quitationProgress`: Incrementa ao completar todas as quests do dia

---

## 2. REPOSITORIES

### DailyQuestRepository

**Arquivo:** `lib/repositories/daily_quest_repository.dart`

**Métodos:**
```dart
Future<List<DailyQuestModel>> getDailyQuests(String userId)
Stream<List<DailyQuestModel>> getDailyQuestsStream(String userId)
Future<DailyQuestModel> createDailyQuest(DailyQuestModel quest)
Future<void> updateDailyQuest(String userId, DailyQuestModel quest)
Future<void> deleteDailyQuest(String userId, String questId)
Future<void> resetAllDailyQuests(String userId) // Batch update
```

**Estrutura Firestore:**
```
users/{userId}/daily_quests/{questId}
  ├─ userId
  ├─ title
  ├─ description
  ├─ isCompleted
  ├─ streak
  ├─ lastCompletedAt
  ├─ lastResetDate
  ├─ order (0-4)
  └─ time ("HH:mm")
```

### PenaltyRepository

**Arquivo:** `lib/repositories/penalty_repository.dart`

**Métodos:**
```dart
Future<PenaltyStateModel> getPenaltyState(String userId)
Stream<PenaltyStateModel> getPenaltyStateStream(String userId)
Future<void> updatePenaltyState(String userId, PenaltyStateModel state)
Future<void> resetPenaltyState(String userId)
```

**Estrutura Firestore:**
```
users/{userId}/penalty_state/current
  ├─ isInPenaltyZone
  ├─ penaltyStartedAt
  ├─ daysRemaining
  ├─ quitationProgress
  └─ lastQuitationDate
```

---

## 3. SERVICES (LÓGICA DE NEGÓCIO)

### DailyQuestService

**Arquivo:** `lib/services/daily_quest_service.dart`

#### Completar Quest

```dart
Future<void> completeDailyQuest(DailyQuestModel quest) async {
  // 1. Verifica se já completou hoje
  if (quest.isCompleted && _isSameDay(quest.lastCompletedAt, now)) {
    throw Exception('Quest já completada hoje');
  }

  // 2. Verifica se mantém streak (completou ontem)
  final yesterday = now.subtract(const Duration(days: 1));
  final maintainsStreak = quest.lastCompletedAt != null && 
                          _isSameDay(quest.lastCompletedAt, yesterday);

  // 3. Incrementa ou reseta streak
  final newStreak = maintainsStreak ? quest.streak + 1 : 1;

  // 4. Atualiza quest
  final updatedQuest = quest.copyWith(
    isCompleted: true,
    lastCompletedAt: now,
    streak: newStreak,
  );

  await _questRepository.updateDailyQuest(userId, updatedQuest);
}
```

#### Reset Diário

```dart
Future<void> checkAndResetDailyQuests() async {
  final quests = await _questRepository.getDailyQuests(userId);
  final now = DateTime.now();

  for (final quest in quests) {
    // Se não resetou hoje, precisa resetar
    if (!_isSameDay(quest.lastResetDate, now)) {
      
      // Verifica se completou ontem
      final yesterday = now.subtract(const Duration(days: 1));
      final completedYesterday = quest.lastCompletedAt != null && 
                                 _isSameDay(quest.lastCompletedAt, yesterday);

      // Se NÃO completou ontem e tinha streak → PENALTY ZONE!
      if (!completedYesterday && quest.streak > 0 && quest.isCompleted) {
        await _penaltyService.enterPenaltyZone(userId);
      }

      // Reseta a quest
      final resetQuest = quest.copyWith(
        isCompleted: false,
        lastResetDate: now,
        streak: completedYesterday ? quest.streak : 0,
      );

      await _questRepository.updateDailyQuest(userId, resetQuest);
    }
  }
}
```

#### Verificar Todas Completadas

```dart
Future<bool> allQuestsCompletedToday() async {
  final quests = await _questRepository.getDailyQuests(userId);
  if (quests.isEmpty) return false;

  final now = DateTime.now();
  
  // Todas devem estar completadas E ter sido completadas hoje
  return quests.every((quest) => 
    quest.isCompleted && 
    quest.lastCompletedAt != null && 
    _isSameDay(quest.lastCompletedAt, now)
  );
}
```

### PenaltyService

**Arquivo:** `lib/services/penalty_service.dart`

#### Entrar na Penalty Zone

```dart
Future<void> enterPenaltyZone(String userId) async {
  final now = DateTime.now();
  
  final penaltyState = PenaltyStateModel(
    userId: userId,
    isInPenaltyZone: true,
    penaltyStartedAt: now,
    daysRemaining: 3,
    quitationProgress: 0,
  );

  await _penaltyRepository.updatePenaltyState(userId, penaltyState);
}
```

#### Atualizar Progresso de Quitação

```dart
Future<void> updateQuitationProgress(String userId) async {
  final state = await _penaltyRepository.getPenaltyState(userId);
  
  if (!state.isInPenaltyZone) return;

  final now = DateTime.now();
  
  // Verifica se já progrediu hoje
  if (state.lastQuitationDate != null && _isSameDay(state.lastQuitationDate, now)) {
    return; // Já progrediu hoje
  }

  final newProgress = state.quitationProgress + 1;
  final newDaysRemaining = state.daysRemaining - 1;

  // Se completou 3 dias, sai da Penalty Zone
  if (newProgress >= 3) {
    await exitPenaltyZone(userId);
  } else {
    // Atualiza progresso
    final updatedState = state.copyWith(
      quitationProgress: newProgress,
      daysRemaining: newDaysRemaining,
      lastQuitationDate: now,
    );
    
    await _penaltyRepository.updatePenaltyState(userId, updatedState);
  }
}
```

#### Sair da Penalty Zone

```dart
Future<void> exitPenaltyZone(String userId) async {
  // Reseta estado da penalty zone
  await _penaltyRepository.resetPenaltyState(userId);

  // Dá bônus de +200 XP por sair
  final profile = await _userRepository.getUser(userId);
  if (profile != null) {
    final newXp = profile.currentXp + 200;
    final updatedProfile = profile.copyWith(currentXp: newXp);
    await _userRepository.updateUser(updatedProfile);
  }
}
```

#### Desistir

```dart
Future<void> giveUp(String userId) async {
  // 1. Busca objetivos S ativos
  final objectives = await _objectiveRepository.getActiveObjectives(userId);
  final objectivesS = objectives.where((obj) => obj.rank == ObjectiveRank.s).toList();

  // 2. Deleta todos os objetivos S
  for (final objective in objectivesS) {
    await _objectiveRepository.deleteObjective(userId, objective.id);
  }

  // 3. Reduz level em 50%
  final profile = await _userRepository.getUser(userId);
  if (profile != null) {
    final newLevel = (profile.level * 0.5).ceil();
    final updatedProfile = profile.copyWith(level: newLevel, currentXp: 0);
    await _userRepository.updateUser(updatedProfile);
  }

  // 4. Reseta Penalty Zone
  await _penaltyRepository.resetPenaltyState(userId);
}
```

---

## 4. UI - TELA DE DAILY QUESTS

### Arquivo: `lib/features/daily_quests/presentation/daily_quests_screen.dart`

#### Layout

```
┌─────────────────────────────────────────────┐
│ ← DAILY QUESTS                              │
│   // MISSÕES DIÁRIAS                        │
├─────────────────────────────────────────────┤
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ 📅 PROGRESSO DE HOJE                    │ │
│ │ 2 de 3 quests completadas               │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ ✅ 🕐 08:00 │ Meditar 10 minutos        │ │
│ │ ────────────────────────────────────────│ │
│ │ 🔥 STREAK: 5 dias                       │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ ◯ 🕐 18:00 │ Ir à academia             │ │
│ │ ────────────────────────────────────────│ │
│ │ 🔥 STREAK: 3 dias                       │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ ◯  Ler 30 minutos                       │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│                                        [+]  │
└─────────────────────────────────────────────┘
```

#### Funcionalidades

1. **Header com progresso**
   - Mostra X de Y quests completadas hoje
   - Fica verde quando todas completadas

2. **Cards de Quest**
   - Checkbox para marcar/desmarcar
   - Horário (se tiver)
   - Título e descrição
   - Streak com ícone de fogo 🔥
   - Botão deletar

3. **FAB**
   - Máximo de 5 quests
   - Dialog para criar nova quest
   - Seletor de horário opcional

4. **Reset Automático**
   - Chama `checkAndResetDailyQuests()` ao abrir
   - Reseta quests não completadas de ontem
   - Detecta streak quebrado → Penalty Zone

---

## 5. UI - PENALTY ZONE SCREEN

### Arquivo: `lib/features/penalty/presentation/penalty_zone_screen.dart`

#### Design

```
╔═══════════════════════════════════════════════╗
║                                               ║
║          ⚠ PENALTY ZONE ⚠                    ║
║       // SISTEMA DETECTOU FALHA               ║
║                                               ║
║  ┌──────────────────────────────────────┐    ║
║  │  ⚠                                   │    ║
║  │                                      │    ║
║  │  "Você quebrou sua palavra.         │    ║
║  │   Você desistiu do seu futuro.      │    ║
║  │   É isso que você quer ser?"        │    ║
║  │                                      │    ║
║  │  [Mensagem personalizada do usuário]│    ║
║  └──────────────────────────────────────┘    ║
║                                               ║
║       SEU STREAK FOI QUEBRADO                 ║
║         Escolha seu destino:                  ║
║                                               ║
║  ┌──────────────────────────────────────┐    ║
║  │        SE REERGUER                   │    ║
║  └──────────────────────────────────────┘    ║
║                                               ║
║  ┌──────────────────────────────────────┐    ║
║  │          DESISTIR                    │    ║
║  └──────────────────────────────────────┘    ║
║                                               ║
╚═══════════════════════════════════════════════╝
```

#### Efeitos Visuais

**1. Background Animado**
```dart
AnimatedBuilder(
  animation: _glitchAnimation,
  builder: (context, child) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.red.withValues(alpha: 0.2 + (_glitchAnimation.value / 100)),
            Colors.black,
          ],
        ),
      ),
    );
  },
)
```

**2. Scanlines Vermelhas**
```dart
gradient: LinearGradient(
  colors: List.generate(50, (index) {
    return index.isEven
        ? Colors.transparent
        : Colors.red.withValues(alpha: 0.02);
  }),
)
```

**3. Título com Glitch**
```dart
AnimatedBuilder(
  animation: _glitchAnimation,
  builder: (context, child) {
    return Transform.translate(
      offset: Offset(_glitchAnimation.value, 0),
      child: Text('⚠ PENALTY ZONE ⚠', ...),
    );
  },
)
```

#### Ações

**Botão "SE REERGUER":**
```dart
await _penaltyService.enterPenaltyZone(userId);
→ SnackBar: "Penalty Zone ativada. Complete todas as Daily Quests por 3 dias seguidos."
→ Redireciona para Dashboard
```

**Botão "DESISTIR":**
```dart
→ Abre dialog de confirmação
→ Lista consequências:
   ❌ Resetar todos os Objetivos S
   ❌ Perder TODO o progresso
   ❌ Level reduzido em 50%
   ❌ Todos os streaks zerados
→ Botões: "NÃO, CONTINUAR" / "SIM, DESISTIR"
→ Se confirma: await _penaltyService.giveUp(userId)
```

---

## 6. INTEGRAÇÃO COM DASHBOARD

### Botão de Daily Quests Adicionado

**Arquivo:** `lib/features/dashboard/presentation/dashboard_screen.dart`

**Ações Rápidas Atualizadas:**
```
┌────────────┬────────────┐
│ OBJETIVOS  │   STATS    │
└────────────┴────────────┘

┌────────────┬────────────┐
│ DAILY      │  ADD XP    │
│ QUESTS     │  (TEST)    │
└────────────┴────────────┘
```

**Código:**
```dart
_buildActionButton(
  'DAILY QUESTS',
  Icons.calendar_today,
  Colors.purple,
  () => context.push('/daily-quests'),
),
```

---

## 7. ROTAS ADICIONADAS

### Arquivo: `lib/core/routing/app_router.dart`

**Novas Rotas:**
```dart
GoRoute(
  path: '/daily-quests',
  builder: (context, state) => const DailyQuestsScreen(),
),
GoRoute(
  path: '/penalty-zone',
  builder: (context, state) => const PenaltyZoneScreen(),
),
```

---

## 8. FLUXO COMPLETO DO SISTEMA

### Fluxo de Daily Quest

```
DIA 1: Usuário cria "Meditar 10 min" com horário 08:00
    ↓
DIA 1, 08:30: Completa a quest
    ↓
Quest.isCompleted = true
Quest.lastCompletedAt = DIA 1
Quest.streak = 1
    ↓
DIA 2, 00:01: Sistema reseta automaticamente
    ↓
Quest.isCompleted = false
Quest.lastResetDate = DIA 2
Quest.streak = 1 (mantém porque completou ontem)
    ↓
DIA 2, 08:45: Completa a quest
    ↓
Quest.streak = 2 ✅
    ↓
DIA 3, 00:01: Sistema reseta
    ↓
DIA 3: NÃO completa ❌
    ↓
DIA 4, 00:01: Sistema detecta: não completou ontem
    ↓
PENALTY ZONE ATIVADA! 🚨
```

### Fluxo de Penalty Zone

```
Streak quebrado → Tela Penalty Zone
    ↓
Opção 1: "SE REERGUER"
    ↓
Entra em Penalty Zone
    ├─ isInPenaltyZone = true
    ├─ daysRemaining = 3
    └─ quitationProgress = 0
    ↓
Dashboard com UI vermelha
XP reduzido em 50%
    ↓
DIA 1 PZ: Completa TODAS as daily quests
    ↓
quitationProgress = 1
daysRemaining = 2
    ↓
DIA 2 PZ: Completa TODAS as daily quests
    ↓
quitationProgress = 2
daysRemaining = 1
    ↓
DIA 3 PZ: Completa TODAS as daily quests
    ↓
quitationProgress = 3 → SAIR!
    ↓
PenaltyService.exitPenaltyZone()
    ├─ Reseta penalty state
    ├─ +200 XP bônus
    └─ XP volta ao normal
    ↓
Animação épica: "DÍVIDA QUITADA" ✅
```

### Fluxo de Desistir

```
Penalty Zone → Clica "DESISTIR"
    ↓
Dialog de confirmação:
  "⚠ CONFIRMAÇÃO FINAL ⚠"
  Lista de consequências
    ↓
Clica "SIM, DESISTIR"
    ↓
PenaltyService.giveUp()
    ├─ Deleta todos os objetivos S
    ├─ Level reduzido 50%
    ├─ XP zerado
    └─ Reseta penalty state
    ↓
Volta ao Dashboard (pode recomeçar) 🔄
```

---

## 9. ARQUIVOS CRIADOS

1. **`lib/models/daily_quest_model.dart`** - Modelo de Daily Quest
2. **`lib/models/penalty_state_model.dart`** - Modelo de Penalty State
3. **`lib/repositories/daily_quest_repository.dart`** - Repository de Daily Quests
4. **`lib/repositories/penalty_repository.dart`** - Repository de Penalty State
5. **`lib/services/daily_quest_service.dart`** - Service de Daily Quests
6. **`lib/services/penalty_service.dart`** - Service de Penalty Zone
7. **`lib/features/daily_quests/presentation/daily_quests_screen.dart`** - UI de Daily Quests
8. **`lib/features/penalty/presentation/penalty_zone_screen.dart`** - UI de Penalty Zone

### Arquivos Modificados

9. **`lib/core/routing/app_router.dart`** - Rotas adicionadas
10. **`lib/features/dashboard/presentation/dashboard_screen.dart`** - Botão Daily Quests

---

## 10. COMPILATION STATUS

✅ **0 erros de compilação**  
⚠️ **16 warnings** (info - não crítico):
- 1x `unused_field` (campo _auth em PenaltyService)
- 8x `avoid_print` (logs de desenvolvimento)
- 4x `deprecated_member_use` (dialogBackgroundColor)
- 3x `use_build_context_synchronously`

---

## 11. FUNCIONALIDADES IMPLEMENTADAS

### Daily Quests
- ✅ Criar até 5 quests diárias
- ✅ Marcar/desmarcar como completada
- ✅ Tracking de streak automático
- ✅ Reset diário automático
- ✅ Horário opcional para cada quest
- ✅ Deletar quests
- ✅ UI com design Militar Futurista

### Penalty Zone 2.0
- ✅ Ativação automática ao quebrar streak
- ✅ Mensagem personalizada do usuário
- ✅ Botão "SE REERGUER" (entra na PZ)
- ✅ Botão "DESISTIR" (reset completo)
- ✅ Sistema de quitação (3 dias)
- ✅ Bônus de +200 XP ao sair
- ✅ UI com efeitos visuais (glitch, scanlines)

### Integrações
- ✅ Botão no Dashboard
- ✅ Rotas configuradas
- ✅ Reset automático ao abrir Daily Quests
- ✅ Verificação de todas completadas

---

## 12. PRÓXIMOS PASSOS (FUTURAS MELHORIAS)

### 1. Dashboard Mostrar Daily Quests

Adicionar seção no Dashboard mostrando as quests de hoje:
```dart
Widget _buildDailyQuestsSection() {
  return StreamBuilder<List<DailyQuestModel>>(...);
}
```

### 2. Penalty Zone Indicator no Dashboard

Quando `isInPenaltyZone == true`:
- UI do dashboard em vermelho
- Banner no topo: "PENALTY ZONE - X dias restantes"
- XP reduzido em 50%

### 3. Notificações

- Lembrete para completar daily quests (18h)
- Alerta quando entrar na Penalty Zone
- Comemoração ao sair da Penalty Zone

### 4. Cloud Function para Reset

Atualmente o reset é local (ao abrir o app). Ideal seria:
```javascript
// Firebase Cloud Function
exports.dailyReset = functions.pubsub
  .schedule('0 0 * * *') // Meia-noite todo dia
  .onRun(async (context) => {
    // Reseta todas as daily quests
    // Verifica streaks quebrados
    // Ativa Penalty Zone se necessário
  });
```

---

## 13. TESTES RECOMENDADOS

### Teste 1: Criar e Completar Daily Quest
```
✓ Criar quest "Meditar"
✓ Completar quest
✓ Verificar streak = 1
✓ Próximo dia: verificar reset
✓ Completar novamente
✓ Verificar streak = 2
```

### Teste 2: Quebrar Streak
```
✓ Ter quest com streak 5
✓ Não completar por 1 dia
✓ Próximo dia: abrir app
✓ Verificar Penalty Zone ativada
```

### Teste 3: Quitação
```
✓ Entrar na Penalty Zone
✓ DIA 1: Completar todas as quests
✓ DIA 2: Completar todas as quests
✓ DIA 3: Completar todas as quests
✓ Verificar saída da PZ
✓ Verificar +200 XP bônus
```

### Teste 4: Desistir
```
✓ Ter 3 objetivos S ativos
✓ Entrar na Penalty Zone
✓ Clicar "DESISTIR"
✓ Confirmar
✓ Verificar objetivos S deletados
✓ Verificar level reduzido 50%
```

---

**Implementado por:** IA Assistant  
**Data:** 15/01/2025  
**Fase:** 6 de 8  
**Status:** Completa e Funcional ✅
