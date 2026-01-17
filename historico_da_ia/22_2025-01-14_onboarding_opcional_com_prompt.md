# Histórico - Onboarding Opcional com Prompt Inteligente

## Data: 14/01/2025

### Motivo da Mudança
O usuário solicitou que o onboarding se tornasse opcional:
- Quando o usuário se cadastra pela primeira vez, os dados do onboarding devem ficar salvos no banco
- Ao fazer login, o sistema deve verificar se já tem dados salvos (objetivos S)
- Se NÃO tiver objetivos: Mostrar mensagem "Objetivos S não cadastrados, deseja cadastrar? (Não mostrar novamente)"
- Se JÁ tiver objetivos: Não mostrar nada e permitir acesso ao dashboard

### Problema Anterior

O fluxo anterior **forçava** o onboarding:
```
Cadastro → Onboarding (obrigatório) → Dashboard
```

**Problemas:**
- Usuário era forçado a fazer onboarding
- Não havia opção de pular
- Se o usuário não quisesse definir objetivos S inicialmente, ficava preso

### Solução Implementada

#### NOVO FLUXO: ONBOARDING OPCIONAL

```
Cadastro → Dashboard
    ↓
Sistema verifica: Tem objetivos S?
    ↓
┌───────────────┴───────────────┐
│                               │
SIM                           NÃO
│                               │
Usa dashboard                   ↓
normalmente              Verifica: Marcou "não mostrar"?
                                ↓
                         ┌──────────────┬──────────────┐
                         │              │              │
                        SIM           NÃO         AGORA NÃO
                         │              │              │
                    Não mostra    Mostra dialog    Fecha dialog
                      nada         com opções      (pode mostrar
                                        │           depois)
                                        ↓
                        ┌──────────────┬──────────────┐
                        │              │              │
                  "Sim, cadastrar"  "Não mostrar    "Agora não"
                        │            novamente"           │
                        ↓              │                  │
                  [Onboarding]         ↓                  ↓
                        │         Marca flag         Fecha dialog
                        ↓         (não mostra        (pode mostrar
                  [Dashboard]      mais)              na próxima vez)
```

### Mudanças Implementadas

#### 1. ADICIONADO CAMPO `skipOnboardingPrompt`

**Arquivo:** `lib/models/user_profile_model.dart`

**Novo campo:**
```dart
final bool skipOnboardingPrompt; // Se true, não mostra mais o prompt de onboarding
```

**Inicialização:**
```dart
UserProfileModel({
  // ... outros campos
  this.hasCompletedOnboarding = false,
  this.skipOnboardingPrompt = false, // ← NOVO
});
```

**Propósito:**
- Armazena a preferência do usuário de não ser mais perguntado sobre onboarding
- Uma vez marcado como `true`, o dialog nunca mais aparece

#### 2. MODIFICADO ROUTER PARA NÃO FORÇAR ONBOARDING

**Arquivo:** `lib/core/routing/app_router.dart`

**Antes (Forçava onboarding):**
```dart
// Se está logado
final hasCompleted = await ref.read(hasCompletedOnboardingProvider.future);

// Se não completou onboarding
if (!hasCompleted) {
  // FORÇA ir para onboarding
  if (!isGoingToOnboarding) {
    return '/onboarding'; // ← Forçado
  }
  return null;
}
```

**Depois (Permite dashboard sem onboarding):**
```dart
// Se está logado e está tentando acessar telas de auth, redireciona para dashboard
if (isGoingToAuth) {
  return '/';
}

// Permite acesso a qualquer outra rota (incluindo dashboard sem onboarding)
return null; // ← Não força mais
```

**Mudança:**
- Removida verificação forçada de `hasCompletedOnboarding`
- Usuário pode acessar dashboard mesmo sem completar onboarding
- Onboarding se torna **opcional**

#### 3. ADICIONADO VERIFICAÇÃO INTELIGENTE NO DASHBOARD

**Arquivo:** `lib/core/routing/app_router.dart` (classe `_DashboardPlaceholder`)

**Lógica de Verificação:**
```dart
Future<void> _checkOnboardingPrompt() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || !mounted) return;

  try {
    // 1. Busca perfil do usuário
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final data = userDoc.data()!;
    final skipPrompt = data['skipOnboardingPrompt'] ?? false;
    final hasCompleted = data['hasCompletedOnboarding'] ?? false;
    
    // 2. Se já completou OU marcou para não mostrar, não mostra dialog
    if (hasCompleted || skipPrompt) return;
    
    // 3. Verifica se tem objetivos S cadastrados
    final objectivesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('objectives')
        .limit(1)
        .get();
    
    // 4. Se tem objetivos, não mostra dialog
    if (objectivesSnapshot.docs.isNotEmpty) return;
    
    // 5. Se chegou aqui: Não tem objetivos E não marcou skip
    //    Mostra dialog perguntando sobre onboarding
    if (mounted) {
      _showOnboardingDialog();
    }
  } catch (e) {
    // Em caso de erro, não mostra dialog (fail silently)
    debugPrint('Erro ao verificar onboarding: $e');
  }
}
```

**Condições para Mostrar Dialog:**
1. ✅ Usuário está logado
2. ✅ `hasCompletedOnboarding = false`
3. ✅ `skipOnboardingPrompt = false`
4. ✅ Não tem nenhum objetivo S cadastrado

**Condições para NÃO Mostrar:**
- ❌ `hasCompletedOnboarding = true`
- ❌ `skipOnboardingPrompt = true`
- ❌ Já tem objetivos S cadastrados
- ❌ Erro ao verificar (fail silently)

#### 4. CRIADO DIALOG DE ONBOARDING

**Arquivo:** `lib/core/routing/app_router.dart`

**Design do Dialog:**
```dart
AlertDialog(
  backgroundColor: Color(0xFF1A1D24), // Escuro
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(0), // Bordas retas
    side: BorderSide(color: Color(0xFF00F0FF), width: 1), // Borda cyan
  ),
  title: Row(
    children: [
      Icon(Icons.info_outline, color: Color(0xFF00F0FF)),
      Text('OBJETIVOS S NÃO CADASTRADOS'),
    ],
  ),
  content: Text(
    'Você ainda não cadastrou seus 3 Objetivos Sagrados.\n\n'
    'Deseja cadastrá-los agora? Isso ajudará a definir suas metas e acompanhar seu progresso.',
  ),
  actions: [
    TextButton('Não mostrar novamente'), // Cinza
    TextButton('Agora não'),             // Branco
    ElevatedButton('Sim, cadastrar'),    // Cyan
  ],
)
```

**Opções do Dialog:**

**1. "Sim, cadastrar" (Botão principal - Cyan)**
```dart
ElevatedButton(
  onPressed: () {
    Navigator.of(context).pop();
    context.go('/onboarding'); // ← Vai para onboarding
  },
  child: Text('Sim, cadastrar'),
)
```

**2. "Não mostrar novamente" (Texto cinza)**
```dart
TextButton(
  onPressed: () async {
    Navigator.of(context).pop();
    // Marca para não mostrar novamente
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'skipOnboardingPrompt': true}); // ← Marca flag
    }
  },
  child: Text('Não mostrar novamente'),
)
```

**3. "Agora não" (Texto branco)**
```dart
TextButton(
  onPressed: () {
    Navigator.of(context).pop(); // ← Apenas fecha
  },
  child: Text('Agora não'),
)
```

### Cenários de Uso

#### Cenário 1: Novo Usuário (Aceita Onboarding)
```
1. Usuário se cadastra
2. Vai para dashboard
3. Dialog aparece: "Objetivos S não cadastrados..."
4. Clica "Sim, cadastrar"
5. Vai para onboarding
6. Completa onboarding
7. Objetivos são salvos
8. hasCompletedOnboarding = true
9. Faz logout e login novamente
10. ✅ Não mostra dialog (tem objetivos)
```

#### Cenário 2: Novo Usuário (Pula Onboarding Temporariamente)
```
1. Usuário se cadastra
2. Vai para dashboard
3. Dialog aparece
4. Clica "Agora não"
5. Dialog fecha
6. Usa dashboard normalmente
7. Faz logout e login novamente
8. ✅ Dialog aparece novamente (pode cadastrar depois)
```

#### Cenário 3: Novo Usuário (Não Quer Ver Mais)
```
1. Usuário se cadastra
2. Vai para dashboard
3. Dialog aparece
4. Clica "Não mostrar novamente"
5. skipOnboardingPrompt = true é salvo
6. Dialog fecha
7. Usa dashboard normalmente (sem objetivos S)
8. Faz logout e login novamente
9. ✅ Não mostra dialog (marcou para não mostrar)
```

#### Cenário 4: Usuário com Objetivos S
```
1. Usuário faz login
2. Sistema verifica: Tem objetivos S? SIM
3. ✅ Não mostra dialog
4. Vai direto para dashboard
```

#### Cenário 5: Cadastra Objetivos Manualmente Depois
```
1. Usuário pula onboarding (clica "Agora não")
2. Usa app sem objetivos S
3. Decide cadastrar depois
4. Clica botão "Ir para Onboarding" (se houver)
5. Ou: faz logout e login → dialog aparece de novo
6. Clica "Sim, cadastrar"
7. Completa onboarding
8. ✅ Na próxima vez, não mostra dialog
```

### Detalhes Técnicos

#### Por que Verificar Objetivos e Não Apenas `hasCompletedOnboarding`?

**Motivo:** Flexibilidade

- `hasCompletedOnboarding`: Indica que o usuário **passou** pelo onboarding uma vez
- **Ter objetivos S**: Indica que o usuário **tem dados** cadastrados

**Caso especial:**
- Usuário pode completar onboarding mas depois deletar todos os objetivos S
- Nesse caso, `hasCompletedOnboarding = true`, mas não tem objetivos
- A verificação de objetivos garante que o prompt só aparece se realmente não tiver dados

#### Diferença entre `hasCompletedOnboarding` e `skipOnboardingPrompt`

| Campo | Propósito | Quando é `true` |
|-------|-----------|-----------------|
| `hasCompletedOnboarding` | Indica que passou pelo onboarding | Ao completar o onboarding |
| `skipOnboardingPrompt` | Indica que não quer mais ver o prompt | Ao clicar "Não mostrar novamente" |

**Comportamento:**
- Se `hasCompletedOnboarding = true`: Não mostra prompt (tem objetivos)
- Se `skipOnboardingPrompt = true`: Não mostra prompt (não quer ver)
- Ambos podem ser `true` ou `false` independentemente

#### Fluxo de Estados

```
Estado Inicial:
hasCompletedOnboarding = false
skipOnboardingPrompt = false
objetivos = []

↓ (Login)

Mostra dialog? SIM (todas condições são false/empty)

↓ (Usuário clica "Não mostrar novamente")

Estado após click:
hasCompletedOnboarding = false (ainda não completou)
skipOnboardingPrompt = true  (marcou para não mostrar)
objetivos = []               (ainda não tem)

↓ (Login novamente)

Mostra dialog? NÃO (skipOnboardingPrompt = true)
```

### Arquivos Modificados

#### Modificados
- `lib/models/user_profile_model.dart`
  - Adicionado campo `skipOnboardingPrompt`
  - Atualizado `create()`, `fromFirestore()`, `toFirestore()`, `copyWith()`

- `lib/core/routing/app_router.dart`
  - Removida lógica forçada de onboarding no router
  - Mudado `_DashboardPlaceholder` de `ConsumerWidget` para `ConsumerStatefulWidget`
  - Adicionado método `_checkOnboardingPrompt()` com verificação inteligente
  - Adicionado método `_showOnboardingDialog()` com dialog customizado
  - Atualizado botão "Resetar Onboarding" para incluir reset de `skipOnboardingPrompt` e deleção de objetivos

#### Documentação
- `historico_da_ia/22_2025-01-14_onboarding_opcional_com_prompt.md` (criado)
- `historico_da_ia/README.md` (será atualizado)

### Vantagens da Nova Abordagem

#### 1. Flexibilidade para o Usuário
- ✅ Pode escolher quando fazer onboarding
- ✅ Pode usar o app sem objetivos S (se preferir)
- ✅ Pode decidir não ver mais o prompt

#### 2. UX Não-Intrusiva
- ✅ Prompt aparece uma vez na primeira vez
- ✅ Usuário controla se quer ver novamente
- ✅ Não bloqueia acesso ao app

#### 3. Persistência de Preferências
- ✅ Escolha do usuário é salva no Firestore
- ✅ Funciona em múltiplos dispositivos
- ✅ Não perde preferência após logout/login

#### 4. Verificação Inteligente
- ✅ Checa se realmente precisa do prompt (não tem objetivos)
- ✅ Respeita preferências do usuário
- ✅ Fail silently em caso de erro (não trava o app)

### Melhorias Futuras (Não Implementadas Agora)

1. **Botão no Dashboard para Ir ao Onboarding**
   - Adicionar botão "Cadastrar Objetivos S" no dashboard
   - Apenas visível se não tiver objetivos

2. **Badge/Notificação Visual**
   - Mostrar badge no ícone de Objetivos se não tiver cadastrado
   - Lembrete visual sutil

3. **Onboarding Parcial**
   - Permitir salvar apenas 1 ou 2 objetivos (não forçar 3)
   - Mais flexível para usuários indecisos

4. **Tutorial Inline**
   - Em vez de tela separada de onboarding
   - Tutorial contextual dentro do dashboard

### Testes Manuais Recomendados

**Teste 1: Novo Usuário - Aceita Onboarding**
1. Criar conta nova
2. ✅ Ir para dashboard
3. ✅ Ver dialog "Objetivos S não cadastrados"
4. Clicar "Sim, cadastrar"
5. ✅ Ir para onboarding
6. Completar onboarding
7. ✅ Salvar objetivos
8. Logout e login
9. ✅ NÃO ver dialog (tem objetivos)

**Teste 2: Novo Usuário - Pula Temporariamente**
1. Criar conta nova
2. Ver dialog
3. Clicar "Agora não"
4. ✅ Dialog fecha
5. Usar dashboard
6. Logout e login
7. ✅ Ver dialog novamente

**Teste 3: Novo Usuário - Não Quer Ver Mais**
1. Criar conta nova
2. Ver dialog
3. Clicar "Não mostrar novamente"
4. ✅ Dialog fecha
5. Logout e login
6. ✅ NÃO ver dialog (marcou skip)

**Teste 4: Reset de Onboarding (Teste)**
1. Ir para dashboard
2. Clicar "Resetar Onboarding (Teste)"
3. ✅ Ver mensagem "Onboarding resetado"
4. Reiniciar app (ou logout/login)
5. ✅ Ver dialog novamente

### Observações Finais

Esta implementação torna o onboarding **opcional e inteligente**, respeitando a escolha do usuário enquanto oferece a funcionalidade de cadastrar objetivos S quando ele quiser.

**Design Principles:**
- **Não-intrusivo:** Pergunta uma vez, depois respeita a escolha
- **Reversível:** Usuário pode sempre ir para onboarding depois
- **Persistente:** Preferências são salvas e sincronizadas
- **Robusto:** Fail silently em caso de erro

**Impacto em Produção:**
- Onboarding deixa de ser obrigatório
- Usuários têm mais controle sobre quando configurar objetivos
- App pode ser usado imediatamente após cadastro
- Não quebra funcionalidades existentes (quem já tem objetivos não vê mudança)

### Status
✅ **Código compila sem erros**
✅ **Análise estática: 0 issues**
✅ **Campo `skipOnboardingPrompt` adicionado**
✅ **Router não força mais onboarding**
✅ **Verificação inteligente implementada**
✅ **Dialog customizado criado**
✅ **Onboarding agora é opcional**

---

## Comparação: Fluxo Antes vs Depois

### ANTES (Onboarding Obrigatório)

```
[Cadastro]
    ↓
[Dashboard acessa]
    ↓
Router verifica: hasCompletedOnboarding?
    ↓
┌─────────────┴─────────────┐
│                           │
SIM                        NÃO
│                           │
[Dashboard]            ❌ FORÇA ir para
                          [Onboarding]
                               │
                          Usuário PRESO
                          (deve completar)
```

### DEPOIS (Onboarding Opcional)

```
[Cadastro]
    ↓
[Dashboard acessa]
    ↓
Verifica: Tem objetivos S?
    ↓
┌─────────────┴─────────────┐
│                           │
SIM                        NÃO
│                           │
[Dashboard]            Verifica: skipOnboardingPrompt?
                            ↓
                    ┌───────────┴───────────┐
                    │                       │
                   SIM                     NÃO
                    │                       │
               [Dashboard]          ✨ Mostra Dialog
                (sem prompt)               │
                                     Usuário ESCOLHE
```

A mudança fundamental: **De obrigação para convite.**
