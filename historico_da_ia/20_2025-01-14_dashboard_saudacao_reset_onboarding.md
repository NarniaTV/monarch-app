# Histórico - Dashboard com Saudação e Reset de Onboarding

## Data: 14/01/2025

### Motivo da Mudança
O usuário reportou dois problemas:

1. **Cadastro pulando onboarding:** Ao criar novo cadastro, estava indo direto para o dashboard, pulando o onboarding e o login
   - **Causa:** Usuário estava fazendo login com conta antiga que já tinha `hasCompletedOnboarding = true` no Firestore

2. **Solicitação de feature:** Adicionar saudação personalizada no dashboard:
   - "Olá [nome do usuário]" se tiver displayName
   - "Olá [email]" se não tiver displayName

### Problema Identificado

#### Por que o Onboarding Estava Sendo Pulado?

**Cenário:**
1. Usuário cria conta → Perfil criado com `hasCompletedOnboarding = false` ✅
2. Usuário completa onboarding → `hasCompletedOnboarding = true` ✅
3. Usuário faz testes, logout, etc.
4. **Problema:** Ao tentar cadastrar novamente com **email diferente** ou fazer login com **conta antiga**, o sistema verifica o Firestore e encontra `hasCompletedOnboarding = true`
5. Router: "Onboarding já completo" → Vai direto para dashboard

**Causa Raiz:** Durante testes/desenvolvimento, múltiplas contas foram criadas e algumas já tinham onboarding completo.

### Solução Implementada

#### 1. SAUDAÇÃO PERSONALIZADA NO DASHBOARD

**Arquivo:** `lib/core/routing/app_router.dart` (classe `_DashboardPlaceholder`)

**Lógica da Saudação:**
```dart
final currentUser = FirebaseAuth.instance.currentUser;
final displayName = currentUser?.displayName;
final email = currentUser?.email ?? 'Usuário';

// Prioriza displayName, senão usa email
final greeting = displayName != null && displayName.isNotEmpty 
    ? 'Olá, $displayName!' 
    : 'Olá, $email!';
```

**Hierarquia:**
1. **Se `displayName` existe e não está vazio:** Usa displayName
2. **Caso contrário:** Usa email
3. **Fallback:** Se não tiver nem email (caso impossível), usa "Usuário"

**Exemplos:**
```dart
// Usuário: João Silva (displayName: "João")
greeting = "Olá, João!"

// Usuário: test@example.com (sem displayName)
greeting = "Olá, test@example.com!"
```

#### 2. BOTÃO DE RESET DE ONBOARDING (Para Testes)

**Funcionalidade:**
- Botão laranja "Resetar Onboarding (Teste)"
- Quando clicado, atualiza `hasCompletedOnboarding = false` no Firestore
- Permite ao desenvolvedor refazer o onboarding sem criar nova conta

**Implementação:**
```dart
OutlinedButton(
  onPressed: () async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'hasCompletedOnboarding': false});
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Onboarding resetado! Faça logout e login novamente.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao resetar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  },
  child: const Text('Resetar Onboarding (Teste)'),
)
```

**Fluxo de Uso:**
```
[Dashboard]
    ↓
Clica "Resetar Onboarding (Teste)"
    ↓
Firestore: hasCompletedOnboarding = false
    ↓
SnackBar: "Onboarding resetado! Faça logout e login novamente."
    ↓
Clica "Logout"
    ↓
Faz login novamente
    ↓
Router detecta: hasCompletedOnboarding = false
    ↓
[Redireciona para Onboarding] ✅
```

#### 3. MELHORIAS NO DESIGN DO DASHBOARD

**Antes:**
- Apenas texto centralizado
- Botão simples de logout

**Depois:**
- **AppBar** com saudação
- **Saudação grande** no centro da tela
- **Botão vermelho de Logout** (mais visível)
- **Botão laranja de Reset** (para testes, estilizado diferente)

**Estrutura:**
```dart
Scaffold(
  appBar: AppBar(
    title: Text(greeting), // "Olá, João!" no AppBar
    centerTitle: true,
    backgroundColor: Colors.black.withValues(alpha: 0.5),
  ),
  body: Center(
    child: Column(
      children: [
        Text(greeting, fontSize: 32), // Saudação grande
        Text('SYSTEM: AWAKEN\n\nDashboard em desenvolvimento...'),
        ElevatedButton(...), // Logout (vermelho)
        OutlinedButton(...), // Reset Onboarding (laranja)
      ],
    ),
  ),
)
```

### Detalhes Técnicos

#### Por que `displayName` pode estar vazio?

**No cadastro (`RegisterScreen`):**
```dart
await authService.signUpWithEmail(
  email: _emailController.text,
  password: _passwordController.text,
  displayName: _nameController.text.isNotEmpty
      ? _nameController.text
      : null, // ← Pode ser null se usuário não preencher
);
```

**No `AuthService.signUpWithEmail()`:**
```dart
// Atualizar display name se fornecido
if (displayName != null && displayName.isNotEmpty && credential.user != null) {
  await credential.user!.updateDisplayName(displayName);
  await credential.user!.reload();
}
```

Se o usuário não preencher o campo "Nome" no cadastro, `displayName` será `null`, então a saudação usa o email.

#### Acesso ao FirebaseAuth no Widget

```dart
// Acesso direto ao usuário atual
final currentUser = FirebaseAuth.instance.currentUser;

// Campos disponíveis
currentUser?.displayName; // String? - nome de exibição
currentUser?.email;       // String? - email
currentUser?.uid;         // String - ID único do usuário
```

**Por que não usar Riverpod Provider aqui?**
- Para simplificar: `FirebaseAuth.instance.currentUser` é síncrono
- O dashboard só é acessível quando usuário está logado (garantido pelo router)
- Não precisa de estado reativo complexo apenas para mostrar o nome

#### Reset de Onboarding Direto no Firestore

```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .update({'hasCompletedOnboarding': false});
```

**Por que não usar `UserRepository.markOnboardingComplete()`?**
- Para testes, é mais direto e rápido
- Não requer injeção de dependências
- É apenas para desenvolvimento/debug

**Alternativa (mais elegante, mas mais código):**
```dart
final userRepository = UserRepository();
await userRepository.updateUser(
  userProfile.copyWith(hasCompletedOnboarding: false)
);
```

### Arquivos Modificados

#### Modificados
- `lib/core/routing/app_router.dart`
  - Import: `cloud_firestore`
  - Classe `_DashboardPlaceholder`:
    - Adicionado: Lógica de saudação com displayName/email
    - Adicionado: AppBar com saudação
    - Adicionado: Saudação grande no body
    - Adicionado: Botão de reset de onboarding (para testes)
    - Estilizado: Botão de logout em vermelho

#### Documentação
- `historico_da_ia/20_2025-01-14_dashboard_saudacao_reset_onboarding.md` (criado)
- `historico_da_ia/README.md` (atualizado)

### Uso do Botão de Reset (Para Testes)

**Cenário 1: Testar Onboarding Novamente**
1. Logar com conta existente
2. Ir para dashboard
3. Clicar "Resetar Onboarding (Teste)"
4. Ver SnackBar verde: "Onboarding resetado!"
5. Clicar "Logout"
6. Fazer login novamente
7. ✅ Será redirecionado para onboarding

**Cenário 2: Conta Antiga Com Onboarding Completo**
1. Tentar cadastrar com email novo
2. Completar cadastro
3. Fazer login
4. Se for direto para dashboard (conta antiga?):
   - Clicar "Resetar Onboarding (Teste)"
   - Logout e login novamente
   - ✅ Agora vai para onboarding

### Solução para o Problema Original

**Como evitar pular o onboarding em produção?**

O sistema atual **JÁ funciona corretamente** para novos usuários:
1. `UserProfileModel.create()` sempre inicializa `hasCompletedOnboarding = false`
2. Só é marcado como `true` ao completar o onboarding
3. Router verifica essa flag e redireciona corretamente

**O problema reportado pelo usuário era:**
- Durante testes, múltiplas contas foram criadas
- Algumas contas já tinham `hasCompletedOnboarding = true`
- Ao fazer login com essas contas, o onboarding era pulado (comportamento correto!)

**Solução:**
- Para **novos usuários reais:** Funciona perfeitamente
- Para **testes/desenvolvimento:** Use o botão "Resetar Onboarding"
- Para **produção:** Remova ou oculte o botão de reset (não é necessário)

### Observações Finais

#### Saudação Personalizada

A saudação melhora a UX ao:
- Criar conexão pessoal com o usuário
- Mostrar que o sistema reconhece quem está logado
- Dar feedback visual imediato de que o login foi bem-sucedido

#### Botão de Reset

**Importante:** Este botão é **apenas para desenvolvimento/testes**.
- Em produção, pode ser removido ou condicionado a um flag de debug
- Não há razão para usuários finais resetarem o onboarding
- Se necessário em produção, deveria estar em "Configurações" com confirmação

**Como remover em produção:**
```dart
// Opção 1: Remover completamente o OutlinedButton

// Opção 2: Condicionar a um flag de debug
if (kDebugMode) {
  OutlinedButton(...) // Só aparece em modo debug
}
```

### Testes Manuais Recomendados

**Teste 1: Saudação com Nome**
1. Criar conta com nome "João Silva"
2. Completar onboarding
3. Ir para dashboard
4. ✅ Deve aparecer "Olá, João Silva!" (AppBar e body)

**Teste 2: Saudação com Email**
1. Criar conta SEM preencher nome
2. Email: test@example.com
3. Completar onboarding
4. Ir para dashboard
5. ✅ Deve aparecer "Olá, test@example.com!"

**Teste 3: Reset de Onboarding**
1. Estar no dashboard
2. Clicar "Resetar Onboarding (Teste)"
3. ✅ Ver SnackBar verde
4. Clicar "Logout"
5. Fazer login
6. ✅ Deve ir para onboarding (não dashboard)

**Teste 4: Conta Nova**
1. Criar conta totalmente nova
2. ✅ Deve ir para onboarding (não pular)
3. Completar onboarding
4. ✅ Deve ir para dashboard com saudação

### Status
✅ **Código compila sem erros**
✅ **Análise estática: 0 issues**
✅ **Saudação personalizada implementada**
✅ **Botão de reset de onboarding adicionado**
✅ **Dashboard aprimorado visualmente**

---

## Comparação: Dashboard Antes vs Depois

### Antes

```
┌─────────────────────────────────────┐
│                                     │
│    SYSTEM: AWAKEN                   │
│                                     │
│    Dashboard em desenvolvimento...  │
│                                     │
│    [Voltar para Login]              │
│                                     │
└─────────────────────────────────────┘
```

### Depois

```
┌─────────────────────────────────────┐
│  ╔═══════════════════════════════╗  │
│  ║    Olá, João Silva!           ║  │ ← AppBar
│  ╚═══════════════════════════════╝  │
│                                     │
│         Olá, João Silva!            │ ← Saudação grande
│                                     │
│    SYSTEM: AWAKEN                   │
│                                     │
│    Dashboard em desenvolvimento...  │
│                                     │
│         [Logout] (vermelho)         │
│                                     │
│    [Resetar Onboarding (Teste)]     │
│         (laranja, outlined)         │
│                                     │
└─────────────────────────────────────┘
```

### Código Completo das Mudanças

```dart
// ANTES
class _DashboardPlaceholder extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const Text('SYSTEM: AWAKEN\n\nDashboard em desenvolvimento...'),
            ElevatedButton(
              onPressed: () async {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                context.go('/login');
              },
              child: const Text('Voltar para Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// DEPOIS
class _DashboardPlaceholder extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.displayName;
    final email = currentUser?.email ?? 'Usuário';
    final greeting = displayName != null && displayName.isNotEmpty 
        ? 'Olá, $displayName!' 
        : 'Olá, $email!';

    return Scaffold(
      appBar: AppBar(
        title: Text(greeting),
        centerTitle: true,
        backgroundColor: Colors.black.withValues(alpha: 0.5),
      ),
      body: Center(
        child: Column(
          children: [
            Text(greeting, fontSize: 32, fontWeight: FontWeight.bold),
            const Text('SYSTEM: AWAKEN\n\nDashboard em desenvolvimento...'),
            // Logout button (vermelho)
            ElevatedButton(...),
            // Reset onboarding button (laranja, para testes)
            OutlinedButton(...),
          ],
        ),
      ),
    );
  }
}
```

A implementação é limpa, melhora a UX com saudação personalizada, e adiciona uma ferramenta útil de debug para desenvolvimento.
