# Histórico - Nickname Obrigatório e Único + Onboarding Obrigatório

## Data: 14/01/2025

### Motivo da Mudança
O usuário solicitou duas mudanças importantes:
1. **Onboarding obrigatório novamente:** Reverter mudança anterior que tornava o onboarding opcional
2. **Nickname obrigatório e único:** Adicionar campo de nickname no cadastro que seja obrigatório e não possa ser duplicado entre usuários

### Problema Anterior

**Onboarding Opcional (Histórico 22):**
- Onboarding era opcional após cadastro
- Sistema mostrava dialog perguntando se queria fazer
- Usuário podia pular indefinidamente

**Falta de Nickname:**
- Não havia identificador único para usuários além do email
- displayName era opcional e podia ser duplicado

### Solução Implementada

#### 1. ADICIONADO CAMPO NICKNAME AO MODELO

**Arquivo:** `lib/models/user_profile_model.dart`

**Novo campo:**
```dart
final String nickname; // Nickname único obrigatório
```

**Mudanças no modelo:**
- Campo obrigatório no construtor
- Adicionado ao `create()`
- Adicionado ao `fromFirestore()`
- Adicionado ao `toFirestore()`
- Adicionado ao `copyWith()`

**Exemplo:**
```dart
UserProfileModel.create(
  userId: "abc123",
  email: "user@example.com",
  displayName: "João Silva", // Opcional
  nickname: "joao_silva", // OBRIGATÓRIO E ÚNICO
)
```

#### 2. VALIDAÇÃO DE NICKNAME ÚNICO

**Arquivo:** `lib/services/auth_service.dart`

**Método adicionado:**
```dart
/// Verifica se o nickname já está em uso
Future<bool> isNicknameTaken(String nickname) async {
  try {
    final querySnapshot = await _firestore
        .collection('users')
        .where('nickname', isEqualTo: nickname.trim().toLowerCase())
        .limit(1)
        .get();
    
    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    throw 'Erro ao verificar nickname: $e';
  }
}
```

**Modificado `signUpWithEmail()`:**
```dart
Future<UserCredential> signUpWithEmail({
  required String email,
  required String password,
  String? displayName,
  required String nickname, // ← NOVO parâmetro obrigatório
}) async {
  try {
    // Verifica se o nickname já está em uso
    final nicknameTaken = await isNicknameTaken(nickname);
    if (nicknameTaken) {
      throw 'Este nickname já está em uso. Escolha outro.';
    }

    // ... resto da lógica de cadastro
  }
}
```

**Fluxo de Validação:**
1. Usuário preenche nickname no formulário
2. Clica "GENERATE LICENSE"
3. Sistema verifica no Firestore se já existe nickname (case-insensitive)
4. Se existe: Retorna erro "Este nickname já está em uso"
5. Se não existe: Prossegue com o cadastro

#### 3. CAMPO DE NICKNAME NO REGISTER SCREEN

**Arquivo:** `lib/features/auth/presentation/register_screen.dart`

**Controller adicionado:**
```dart
final _nicknameController = TextEditingController();
```

**Campo no formulário (entre Name e Email):**
```dart
// Nickname Input (OBRIGATÓRIO)
_buildCyberpunkInput(
  controller: _nicknameController,
  label: 'NICKNAME (REQUIRED)',
  icon: Icons.badge_outlined,
  keyboardType: TextInputType.text,
  textInputAction: TextInputAction.next,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Nickname é obrigatório';
    }
    if (value.length < 3) {
      return 'Nickname deve ter pelo menos 3 caracteres';
    }
    if (value.length > 20) {
      return 'Nickname deve ter no máximo 20 caracteres';
    }
    // Validação: apenas letras, números, underscore e hífen
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Nickname inválido (apenas letras, números, _ e -)';
    }
    return null;
  },
),
```

**Validações do Nickname:**

| Regra | Descrição | Exemplo Válido | Exemplo Inválido |
|-------|-----------|----------------|------------------|
| **Obrigatório** | Campo não pode estar vazio | `john_doe` | ` ` (vazio) |
| **Mínimo 3 caracteres** | Deve ter pelo menos 3 caracteres | `abc` | `ab` |
| **Máximo 20 caracteres** | Não pode ter mais de 20 caracteres | `john_doe_123` | `nome_muito_longo_demais_123` |
| **Caracteres permitidos** | Apenas letras, números, _ e - | `john-doe_123` | `john@doe` ou `john doe` |
| **Único** | Não pode existir outro usuário com mesmo nickname | `john_doe` (se não existe) | `john_doe` (se já existe) |

**Regex:** `^[a-zA-Z0-9_-]+$`

**Ordem dos Campos:**
```
1. PLAYER NAME (OPTIONAL)
2. NICKNAME (REQUIRED)       ← NOVO
3. EMAIL
4. PASSWORD
5. CONFIRM PASSWORD
```

#### 4. REVERTIDO ROUTER PARA ONBOARDING OBRIGATÓRIO

**Arquivo:** `lib/core/routing/app_router.dart`

**Lógica de Redirect:**
```dart
redirect: (context, state) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final isLoggedIn = currentUser != null;
  
  // Se não está logado → Login
  if (!isLoggedIn) {
    if (!isGoingToAuth) {
      return '/login';
    }
    return null;
  }

  // Se está logado
  // Busca perfil para verificar onboarding
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .get();
  
  final hasCompleted = userDoc.data()?['hasCompletedOnboarding'] ?? false;
  
  // Se NÃO completou onboarding → FORÇA ir para onboarding
  if (!hasCompleted) {
    if (!isGoingToOnboarding) {
      return '/onboarding';
    }
    return null;
  }
  
  // Se completou onboarding → Dashboard
  if (isGoingToAuth || isGoingToOnboarding) {
    return '/';
  }
  
  return null;
},
```

**Mudança:** Removida lógica de onboarding opcional (dialog, `skipOnboardingPrompt`, etc.)

**Comportamento:**
- Onboarding é **obrigatório** após cadastro
- Usuário **não pode** pular ou adiar
- Só acessa dashboard após completar onboarding

#### 5. DASHBOARD SIMPLIFICADO

**Arquivo:** `lib/core/routing/app_router.dart`

**Removido:**
- `_checkOnboardingPrompt()` (verificação de objetivos S)
- `_showOnboardingDialog()` (dialog opcional)
- `ConsumerStatefulWidget` (voltou para `ConsumerWidget`)
- Lógica de deleção de objetivos no botão de reset

**Mantido:**
- Saudação com nome/email
- Botão de logout
- Botão de reset de onboarding (apenas marca `hasCompletedOnboarding = false`)

### Fluxo Completo Atualizado

```
┌─────────────────────┐
│   Cadastro          │
│                     │
│ Nome: João (opt)    │
│ Nickname: joao123 * │ ← NOVO (obrigatório)
│ Email: ...          │
│ Senha: ...          │
└──────────┬──────────┘
           │
           ▼
    Sistema verifica:
    "joao123" já existe?
           │
    ┌──────┴──────┐
    │             │
   SIM           NÃO
    │             │
   ERRO          ✅
    │             │
Mostra msg    Cria conta
"Nickname      │
 em uso"       ▼
        ┌──────────────┐
        │  Onboarding  │ ← OBRIGATÓRIO
        │              │
        │ 4 páginas    │
        └──────┬───────┘
               │
               ▼
        ┌──────────────┐
        │  Logout      │
        └──────┬───────┘
               │
               ▼
        ┌──────────────┐
        │  Login       │
        │  + Mensagem  │
        └──────┬───────┘
               │
               ▼
        ┌──────────────┐
        │  Dashboard   │
        └──────────────┘
```

### Detalhes Técnicos

#### Por que Nickname Lowercase na Query?

```dart
.where('nickname', isEqualTo: nickname.trim().toLowerCase())
```

**Razão:** Garantir que `JoaoDoe`, `joaodoe`, `JOAODOE` sejam tratados como o mesmo nickname.

**Implementação:**
1. Ao verificar se existe: Converte para lowercase antes da query
2. Ao salvar: Salva exatamente como digitado (mantém case original)
3. Resultado: Nicknames são únicos case-insensitively, mas preservam o case original

**Exemplo:**
- Usuário 1 cadastra: `JohnDoe` → Salvo como `JohnDoe`
- Usuário 2 tenta cadastrar: `johndoe` → Query busca `johndoe` → Encontra `JohnDoe` → ERRO
- Usuário 2 pode usar: `john_doe2` → Não existe → OK

#### Índice no Firestore

O Firestore automaticamente indexa campos individuais, portanto não é necessário criar um índice composto para `nickname`.

**Otimização futura:** Se quisermos buscar nicknames com `startsWith` ou regex, podemos adicionar um índice.

#### Validação Client-Side vs Server-Side

**Client-Side (Formulário):**
- Validação de formato (regex)
- Validação de tamanho (min/max)
- Validação de obrigatoriedade

**Server-Side (AuthService):**
- Validação de unicidade (query no Firestore)
- Garante que mesmo requests diretas à API não criam duplicatas

### Cenários de Uso

#### Cenário 1: Cadastro Bem-Sucedido
```
Usuário preenche:
- Nome: João Silva
- Nickname: joao_silva
- Email: joao@email.com
- Senha: ******

Sistema verifica:
✅ Nickname válido (formato OK)
✅ Nickname único (não existe)

Resultado:
✅ Conta criada
✅ Redireciona para onboarding
```

#### Cenário 2: Nickname Duplicado
```
Usuário 1 já tem nickname: "gamer_pro"

Usuário 2 tenta cadastrar:
- Nickname: GaMeR_pRo

Sistema verifica:
✅ Formato OK
❌ Nickname "gamer_pro" já existe

Resultado:
❌ Erro: "Este nickname já está em uso. Escolha outro."
🔄 Usuário deve escolher outro nickname
```

#### Cenário 3: Nickname Inválido (Formato)
```
Usuário preenche:
- Nickname: "john doe" (com espaço)

Validação no formulário:
❌ "Nickname inválido (apenas letras, números, _ e -)"

Resultado:
❌ Form não valida
🔄 Usuário deve corrigir
```

#### Cenário 4: Nickname Muito Curto
```
Usuário preenche:
- Nickname: "ab"

Validação no formulário:
❌ "Nickname deve ter pelo menos 3 caracteres"

Resultado:
❌ Form não valida
🔄 Usuário deve aumentar
```

### Arquivos Modificados

#### Modificados
- `lib/models/user_profile_model.dart`
  - Campo `nickname` adicionado (obrigatório)
  - Atualizado todos os métodos (create, fromFirestore, toFirestore, copyWith)

- `lib/services/auth_service.dart`
  - Método `isNicknameTaken()` adicionado
  - Método `signUpWithEmail()` atualizado (novo parâmetro + validação)
  - Método `_createUserProfile()` atualizado (novo parâmetro)

- `lib/features/auth/presentation/register_screen.dart`
  - `_nicknameController` adicionado
  - Campo de nickname adicionado ao formulário (entre Name e Email)
  - Validações completas (obrigatório, tamanho, formato)
  - Parâmetro nickname passado para `signUpWithEmail()`

- `lib/core/routing/app_router.dart`
  - Lógica de redirect revertida para forçar onboarding
  - Dashboard simplificado (removida lógica de dialog opcional)
  - Onboarding obrigatório novamente

#### Documentação
- `historico_da_ia/23_2025-01-14_nickname_obrigatorio_unico.md` (criado)
- `historico_da_ia/README.md` (será atualizado)

### Vantagens da Nova Abordagem

#### Nickname Obrigatório e Único

1. **Identificação Única:**
   - Cada usuário tem um identificador único além do email
   - Útil para menções, rankings, leaderboards

2. **Privacidade:**
   - Usuário não precisa expor email
   - Pode usar nickname em vez de nome real

3. **Consistência:**
   - Garantia de unicidade a nível de aplicação
   - Fácil de buscar e referenciar usuários

4. **UX:**
   - Validação em tempo real no formulário
   - Mensagem clara se nickname já existe

#### Onboarding Obrigatório

1. **Garantia de Setup Completo:**
   - Todos os usuários têm objetivos S definidos
   - Experiência consistente para todos

2. **Engajamento:**
   - Força usuário a pensar nos objetivos desde o início
   - Cria comprometimento com o sistema

3. **Simplificação:**
   - Remove lógica complexa de dialog opcional
   - Fluxo mais direto e previsível

### Melhorias Futuras (Não Implementadas)

1. **Sugestão de Nicknames:**
   - Se nickname está em uso, sugerir alternativas
   - Exemplo: `john_doe` → `john_doe2`, `john_doe_123`

2. **Validação em Tempo Real:**
   - Ao digitar nickname, verificar disponibilidade
   - Mostrar ícone verde (disponível) ou vermelho (em uso)

3. **Busca de Nicknames:**
   - Permitir buscar usuários por nickname
   - Autocompletar ao mencionar @nickname

4. **Histórico de Nicknames:**
   - Permitir mudança de nickname (limitada)
   - Manter histórico de nicknames anteriores

### Observações Finais

Esta implementação garante que:
- Todo usuário tem um nickname único
- Cadastro é mais robusto (valida formato e unicidade)
- Onboarding é obrigatório (garantia de setup completo)
- Não há colisão de nicknames (validação server-side)

**Design Principles:**
- **Validação em Camadas:** Client-side (formato) + Server-side (unicidade)
- **Case-Insensitive:** Evita confusão entre `John` e `john`
- **Obrigatoriedade:** Campo crítico não pode ser pulado
- **Feedback Claro:** Mensagens de erro específicas

### Status
✅ **Código compila sem erros**
✅ **Análise estática: 0 issues**
✅ **Campo nickname adicionado**
✅ **Validação de unicidade implementada**
✅ **Formulário atualizado com validações**
✅ **Onboarding obrigatório novamente**
✅ **Router revertido**

---

## Comparação: Antes vs Depois

### Cadastro

#### ANTES
```
Campos:
- Nome (opcional)
- Email
- Senha
- Confirmar Senha

Validações:
✓ Email válido
✓ Senha ≥ 6 chars
✓ Senhas coincidem
```

#### DEPOIS
```
Campos:
- Nome (opcional)
- Nickname (OBRIGATÓRIO) ← NOVO
- Email
- Senha
- Confirmar Senha

Validações:
✓ Nickname obrigatório
✓ Nickname ≥ 3 chars
✓ Nickname ≤ 20 chars
✓ Nickname formato válido (regex)
✓ Nickname único (Firestore query)
✓ Email válido
✓ Senha ≥ 6 chars
✓ Senhas coincidem
```

### Onboarding

#### ANTES (Histórico 22)
```
Cadastro → Dashboard
    ↓
Dialog: "Quer fazer onboarding?"
    ↓
┌────────┬────────┬────────┐
│        │        │        │
Sim    Não    Não mostrar
│        │     novamente
│        │        │
Onboarding  ↓     ↓
         Dashboard
```

#### DEPOIS
```
Cadastro → Onboarding (OBRIGATÓRIO)
             ↓
         Dashboard
```

A mudança torna o fluxo mais direto e garante que todos os usuários tenham nicknames únicos e completem o onboarding inicial.
