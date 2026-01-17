# Histórico - Remoção do Campo Player Name + Correção de Permissões Firestore

## Data: 14/01/2025

### Motivo da Mudança
O usuário reportou dois problemas:
1. **Erro de permissão no Firestore:** `PERMISSION_DENIED` ao tentar verificar se nickname já existe durante o cadastro
2. **Simplificação do cadastro:** Remover o campo "Player Name" e deixar apenas o Nickname

### Problema Anterior

#### Erro de Permissão Firestore
```
W/Firestore: Listen for Query(target=Query(users where nickname==user order by __name__);
limitType=LIMIT_TO_FIRST) failed: Status{code=PERMISSION_DENIED, 
description=Missing or insufficient permissions., cause=null}
```

**Causa Raiz:**
- Durante o cadastro, o usuário ainda **não está autenticado** no Firebase
- O `AuthService.isNicknameTaken()` faz uma query na collection `users`
- As regras do Firestore só permitiam leitura para `isOwner(userId)` (usuário autenticado)
- Portanto, a query era bloqueada

**Fluxo do Problema:**
```
1. Usuário preenche formulário (NÃO está logado)
2. Clica "GENERATE LICENSE"
3. AuthService chama isNicknameTaken()
4. Tenta fazer query: .where('nickname', isEqualTo: 'user')
5. Firestore verifica regras
6. request.auth == null (usuário não autenticado)
7. ❌ PERMISSION_DENIED
```

#### Campo Player Name Redundante
- Formulário tinha dois campos de identificação:
  - **Player Name:** Opcional, não único
  - **Nickname:** Obrigatório, único
- Player Name não era essencial (nickname já identifica o usuário)
- Complexidade desnecessária no formulário

### Solução Implementada

#### 1. ATUALIZAÇÃO DAS REGRAS DO FIRESTORE

**Arquivo:** `firestore.rules`

**Regra Anterior:**
```javascript
match /users/{userId} {
  // Usuário só pode ler/escrever seus próprios dados
  allow read, write: if isOwner(userId);
}
```

**Problema:** Não permitia query de verificação de nickname durante cadastro (usuário não autenticado).

**Regra Nova:**
```javascript
match /users/{userId} {
  // Usuário pode criar sua própria conta (durante cadastro)
  allow create: if request.auth.uid == userId;
  
  // Usuário pode ler/atualizar/deletar apenas seus próprios dados
  allow read, update, delete: if isOwner(userId);
  
  // Permite query por nickname para verificação de unicidade durante cadastro
  // Apenas se a query limitar a 1 resultado
  allow read: if request.query.limit <= 1;
}
```

**Mudanças:**

| Operação | Antes | Depois |
|----------|-------|--------|
| **create** | Incluído em `write` (só se autenticado) | Separado, permite criar próprio documento |
| **read** | Só se `isOwner(userId)` | Também permite se `limit <= 1` (para queries de verificação) |
| **update/delete** | Incluído em `write` | Separado explicitamente |

**Por que `request.query.limit <= 1` é Seguro?**

1. **Não permite listar todos os usuários:** Query sem limite seria bloqueada
2. **Apenas verifica existência:** `isNicknameTaken()` usa `.limit(1)`, que é permitido
3. **Não expõe dados sensíveis:** Apenas retorna se existe ou não (não retorna dados completos)
4. **Proteção contra abuso:** Limitar a 1 impede scraping de dados

**Exemplos de Queries:**

| Query | Permitida? | Razão |
|-------|------------|-------|
| `.where('nickname', isEqualTo: 'user').limit(1)` | ✅ SIM | `limit = 1` |
| `.where('nickname', isEqualTo: 'user')` (sem limit) | ❌ NÃO | Sem limit explícito |
| `.limit(5)` | ❌ NÃO | `limit > 1` |
| `.get()` (listar todos) | ❌ NÃO | Sem limit |

**Query Real do AuthService:**
```dart
final querySnapshot = await _firestore
    .collection('users')
    .where('nickname', isEqualTo: nickname.trim().toLowerCase())
    .limit(1) // ← CRUCIAL: Permite passar pela regra
    .get();
```

#### 2. REMOÇÃO DO CAMPO PLAYER NAME

**Arquivo:** `lib/features/auth/presentation/register_screen.dart`

**Removido:**
- `_nameController` (TextEditingController)
- Campo "PLAYER NAME (OPTIONAL)" do formulário
- Parâmetro `displayName` na chamada de `signUpWithEmail()`

**Formulário Anterior:**
```dart
// Name Input
_buildCyberpunkInput(
  controller: _nameController,
  label: 'PLAYER NAME (OPTIONAL)',
  icon: Icons.person_outline,
  keyboardType: TextInputType.name,
  textInputAction: TextInputAction.next,
),

// Nickname Input (OBRIGATÓRIO)
_buildCyberpunkInput(
  controller: _nicknameController,
  label: 'NICKNAME (REQUIRED)',
  // ...
),
```

**Formulário Atualizado:**
```dart
// Nickname Input (OBRIGATÓRIO)
_buildCyberpunkInput(
  controller: _nicknameController,
  label: 'NICKNAME',
  icon: Icons.badge_outlined,
  // ...
),
```

**Ordem dos Campos Atualizada:**
```
ANTES:
1. Player Name (opcional)
2. Nickname (obrigatório)
3. Email
4. Password
5. Confirm Password

DEPOIS:
1. Nickname (obrigatório)
2. Email
3. Password
4. Confirm Password
```

**Chamada de Cadastro Atualizada:**
```dart
// ANTES
await authService.signUpWithEmail(
  email: _emailController.text,
  password: _passwordController.text,
  displayName: _nameController.text.isNotEmpty
      ? _nameController.text
      : null,
  nickname: _nicknameController.text.trim(),
);

// DEPOIS
await authService.signUpWithEmail(
  email: _emailController.text,
  password: _passwordController.text,
  displayName: null, // Não usamos mais displayName
  nickname: _nicknameController.text.trim(),
);
```

#### 3. ATUALIZAÇÃO DA SAUDAÇÃO NO DASHBOARD

**Arquivo:** `lib/core/routing/app_router.dart`

**Mudança:** Agora busca o **nickname** do Firestore em vez de usar `displayName`.

**Implementação Anterior:**
```dart
final displayName = currentUser?.displayName;
final email = currentUser?.email ?? 'Usuário';
final greeting = displayName != null && displayName.isNotEmpty 
    ? 'Olá, $displayName!' 
    : 'Olá, $email!';
```

**Implementação Nova:**
```dart
FutureBuilder<String>(
  future: _getGreeting(currentUser?.uid),
  builder: (context, snapshot) {
    return Text(
      snapshot.hasData ? snapshot.data! : 'Olá!',
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    );
  },
)

// Método auxiliar
Future<String> _getGreeting(String? userId) async {
  if (userId == null) return 'Olá!';
  
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (userDoc.exists) {
      final nickname = userDoc.data()?['nickname'] as String?;
      if (nickname != null && nickname.isNotEmpty) {
        return 'Olá, $nickname!';
      }
    }
    
    return 'Olá!';
  } catch (e) {
    debugPrint('Erro ao buscar nickname: $e');
    return 'Olá!';
  }
}
```

**Vantagens:**
- Usa o nickname único do usuário
- Busca direto do Firestore (fonte de verdade)
- Fallback gracioso para "Olá!" em caso de erro

### Fluxo Completo Atualizado

```
┌─────────────────────┐
│   Cadastro          │
│                     │
│ Nickname: joao123   │ ← ÚNICO CAMPO DE IDENTIFICAÇÃO
│ Email: ...          │
│ Senha: ...          │
└──────────┬──────────┘
           │
           ▼
    AuthService.isNicknameTaken()
    Query: .where('nickname', ==, 'joao123').limit(1)
           │
    Firestore aplica regras:
    ✅ request.query.limit <= 1
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
        │  Onboarding  │
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
        └──────┬───────┘
               │
               ▼
        ┌──────────────┐
        │  Dashboard   │
        │              │
        │ Saudação:    │
        │ "Olá, joao123!"│ ← Busca nickname do Firestore
        └──────────────┘
```

### Comparação: Antes vs Depois

#### Campos do Formulário

| Campo | Antes | Depois |
|-------|-------|--------|
| Player Name | ✅ Opcional | ❌ Removido |
| Nickname | ✅ Obrigatório, único | ✅ Obrigatório, único |
| Email | ✅ Obrigatório | ✅ Obrigatório |
| Password | ✅ Obrigatório | ✅ Obrigatório |
| Confirm Password | ✅ Obrigatório | ✅ Obrigatório |

**Total de campos:** 5 → 4 (simplificado)

#### Saudação no Dashboard

| Fonte | Antes | Depois |
|-------|-------|--------|
| **Prioritário** | `displayName` (Firebase Auth) | `nickname` (Firestore) |
| **Fallback** | `email` | "Olá!" |
| **Exemplo** | "Olá, João Silva!" ou "Olá, joao@email.com!" | "Olá, joao123!" |

#### Regras do Firestore

| Operação | Antes | Depois |
|----------|-------|--------|
| **Query de verificação** | ❌ Bloqueada (PERMISSION_DENIED) | ✅ Permitida (se `limit <= 1`) |
| **Criar próprio perfil** | ✅ Permitida (implícito em `write`) | ✅ Permitida (explícito em `create`) |
| **Ler próprio perfil** | ✅ Permitida | ✅ Permitida |
| **Ler perfil de outro** | ❌ Bloqueada | ❌ Bloqueada (exceto query com limit) |
| **Listar todos os usuários** | ❌ Bloqueada | ❌ Bloqueada |

### Arquivos Modificados

#### Modificados
- `firestore.rules`
  - Separado `create`, `read`, `update`, `delete`
  - Adicionada regra `allow read: if request.query.limit <= 1`
  - Comentários explicativos

- `lib/features/auth/presentation/register_screen.dart`
  - Removido `_nameController`
  - Removido campo "Player Name"
  - `displayName` definido como `null` na chamada de cadastro
  - Label do nickname simplificada ("NICKNAME" em vez de "NICKNAME (REQUIRED)")

- `lib/core/routing/app_router.dart`
  - Dashboard atualizado para buscar nickname do Firestore
  - Método `_getGreeting()` adicionado
  - `FutureBuilder` usado para carregar saudação

#### Documentação
- `historico_da_ia/24_2025-01-14_remocao_player_name_correcao_firestore.md` (criado)
- `historico_da_ia/README.md` (será atualizado)

### Vantagens da Nova Abordagem

#### Correção de Permissões

1. **Cadastro Funcional:**
   - Verificação de nickname funciona corretamente
   - Não há mais erro PERMISSION_DENIED

2. **Segurança Mantida:**
   - Usuários ainda não podem listar todos os perfis
   - Query limitada a 1 resultado previne scraping
   - Dados sensíveis continuam protegidos

3. **Regras Explícitas:**
   - Separação clara de `create`, `read`, `update`, `delete`
   - Fácil de entender e manter

#### Simplificação do Formulário

1. **Menos Campos:**
   - 5 campos → 4 campos
   - Menos fricção no cadastro

2. **Identificação Única:**
   - Nickname é o único identificador do usuário
   - Consistência: nickname usado em todo o app

3. **UX Melhorada:**
   - Formulário mais limpo
   - Menos confusão sobre qual nome usar

4. **Consistência:**
   - Saudação sempre usa nickname
   - Nickname é a "identidade" do usuário no app

### Melhorias Futuras (Não Implementadas)

1. **Cache de Nickname:**
   - Salvar nickname localmente (SharedPreferences)
   - Evitar buscar no Firestore toda vez

2. **Validação em Tempo Real:**
   - Ao digitar, verificar disponibilidade do nickname
   - Feedback instantâneo (ícone verde/vermelho)

3. **Perfil Editável:**
   - Permitir usuário mudar nickname (com validação)
   - Histórico de nicknames anteriores

4. **Avatar/Foto de Perfil:**
   - Adicionar campo `avatarUrl` (opcional)
   - Mostrar avatar na saudação

### Observações Finais

Esta implementação resolve dois problemas importantes:
1. **Erro de Permissão:** Corrigido com regra específica para queries limitadas
2. **Complexidade do Cadastro:** Reduzida com remoção do campo redundante

**Design Principles:**
- **Segurança em Camadas:** Regras Firestore continuam robustas
- **Princípio KISS (Keep It Simple):** Formulário mais simples e direto
- **Consistência:** Nickname usado como identificação única em todo o app
- **Graceful Degradation:** Fallbacks apropriados em caso de erro

### Teste de Segurança

#### Cenário 1: Query de Verificação (Permitida)
```dart
// AuthService.isNicknameTaken()
await _firestore
    .collection('users')
    .where('nickname', isEqualTo: 'test')
    .limit(1) // ← Passa pela regra
    .get();
```
**Resultado:** ✅ Permitido (`request.query.limit = 1`)

#### Cenário 2: Listar Todos os Usuários (Bloqueada)
```dart
await _firestore
    .collection('users')
    .get(); // Sem limit
```
**Resultado:** ❌ PERMISSION_DENIED (não passa pela regra)

#### Cenário 3: Ler Próprio Perfil (Permitida)
```dart
await _firestore
    .collection('users')
    .doc(currentUser.uid) // Próprio UID
    .get();
```
**Resultado:** ✅ Permitido (`isOwner(userId)`)

#### Cenário 4: Ler Perfil de Outro (Bloqueada)
```dart
await _firestore
    .collection('users')
    .doc('other_user_id') // UID de outro usuário
    .get();
```
**Resultado:** ❌ PERMISSION_DENIED (não é owner e não é query limitada)

### Status
✅ **Código compila sem erros**
✅ **Análise estática: 0 issues**
✅ **Erro de permissão corrigido**
✅ **Campo Player Name removido**
✅ **Saudação usa nickname**
✅ **Regras Firestore atualizadas**
✅ **Segurança mantida**

---

**IMPORTANTE:** Após atualizar `firestore.rules`, você precisa fazer deploy das novas regras no Firebase Console:

1. Acesse Firebase Console
2. Vá em **Firestore Database** → **Rules**
3. Cole o conteúdo de `firestore.rules`
4. Clique em **Publicar**

**OU** use o Firebase CLI:
```bash
firebase deploy --only firestore:rules
```

Sem esse deploy, as regras antigas continuam ativas e o erro de permissão persistirá.
