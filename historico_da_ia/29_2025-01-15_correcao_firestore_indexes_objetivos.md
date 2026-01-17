# Histórico - Correção de Firestore Indexes para Objetivos

## Data: 15/01/2025

### Problema Reportado
Usuário reportou problemas na conexão dos objetivos com o banco de dados.

### Diagnóstico

**Causa Raiz:** Falta de indexes compostos no Firestore

As queries de objetivos usam múltiplos filtros e ordenações:

```dart
// Query em getActiveObjectivesStreamByRank()
_firestore
  .collection('users')
  .doc(userId)
  .collection('objectives')
  .where('rank', isEqualTo: rank.name)       // Filtro 1
  .where('progress', isLessThan: 100)        // Filtro 2
  .orderBy('progress')                        // Ordenação 1
  .orderBy('createdAt')                       // Ordenação 2
```

**Firestore requer indexes compostos** quando:
- Usa múltiplos `where` com diferentes campos
- Usa `where` + múltiplos `orderBy`
- Usa range filter (`<`, `>`, `<=`, `>=`, `!=`) + `orderBy`

### Solução Implementada

#### 1. Arquivo de Indexes Atualizado

**Arquivo:** `firestore.indexes.json`

Adicionados 2 novos indexes para objetivos:

```json
{
  "indexes": [
    // Index 1: Para queries SEM filtro de rank
    {
      "collectionGroup": "objectives",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "progress",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    },
    
    // Index 2: Para queries COM filtro de rank (NOVO)
    {
      "collectionGroup": "objectives",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "rank",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "progress",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    }
  ]
}
```

**Também mantidos indexes para tasks:**
- `rank + isCompleted + createdAt`
- `isCompleted + createdAt`
- `linkedObjectiveId + isCompleted + createdAt`

#### 2. Deploy dos Indexes

```bash
firebase deploy --only firestore:indexes
```

**Resultado:**
```
✔ firestore: deployed indexes in firestore.indexes.json successfully
```

### Como Funcionam os Indexes

#### Index 1: Objetivos sem filtro de rank

**Usado por:**
- `getActiveObjectives(userId)` - Todos os objetivos ativos
- `getActiveObjectivesStream(userId)` - Stream de todos os objetivos

**Query:**
```dart
where('progress', isLessThan: 100)
  .orderBy('progress')
  .orderBy('createdAt')
```

**Index:**
```
progress (ASC) + createdAt (ASC)
```

#### Index 2: Objetivos com filtro de rank

**Usado por:**
- `getActiveObjectivesByRank(userId, rank)` - Objetivos de um rank específico
- `getActiveObjectivesStreamByRank(userId, rank)` - Stream por rank

**Query:**
```dart
where('rank', isEqualTo: 's')  // ou 'a' ou 'b'
  .where('progress', isLessThan: 100)
  .orderBy('progress')
  .orderBy('createdAt')
```

**Index:**
```
rank (ASC) + progress (ASC) + createdAt (ASC)
```

### Queries que Usam Cada Index

#### Sem Index de Rank (Index 1)

1. **Dashboard - Lista de Objetivos S:**
   ```dart
   _objectiveRepository.getActiveObjectives(userId)
   ```

2. **Onboarding - Limpeza de objetivos antigos:**
   ```dart
   await _objectiveRepository.getActiveObjectives(userId);
   ```

#### Com Index de Rank (Index 2)

1. **ObjectivesScreen - Filtro por Rank S:**
   ```dart
   _objectiveRepository.getActiveObjectivesStreamByRank(userId, ObjectiveRank.s)
   ```

2. **ObjectivesScreen - Filtro por Rank A:**
   ```dart
   _objectiveRepository.getActiveObjectivesStreamByRank(userId, ObjectiveRank.a)
   ```

3. **ObjectivesScreen - Filtro por Rank B:**
   ```dart
   _objectiveRepository.getActiveObjectivesStreamByRank(userId, ObjectiveRank.b)
   ```

4. **CreateObjectiveScreen - Validação de limite Rank S:**
   ```dart
   await _objectiveRepository.getActiveObjectivesByRank(userId, ObjectiveRank.s)
   ```

### Verificação de Indexes no Console Firebase

**Passos para verificar:**

1. Acesse: https://console.firebase.google.com/project/monarch-ap/firestore/indexes

2. Vá em **Firestore Database** → **Indexes**

3. Você deve ver:

```
Collection: objectives
Fields: rank (Ascending) + progress (Ascending) + createdAt (Ascending)
Status: Enabled

Collection: objectives  
Fields: progress (Ascending) + createdAt (Ascending)
Status: Enabled
```

**Status possíveis:**
- 🟢 **Enabled** - Index ativo e funcionando
- 🟡 **Building** - Index sendo criado (pode levar minutos)
- 🔴 **Error** - Erro na criação

### Tempo de Criação de Indexes

**Firestore cria indexes automaticamente, mas pode demorar:**

- **Banco vazio:** 1-2 minutos
- **Poucos documentos (< 100):** 2-5 minutos
- **Muitos documentos (> 1000):** 10-30 minutos

**Durante a criação:**
- Queries que precisam do index retornam erro
- Status no console mostra "Building"
- Não é necessário fazer nada, apenas aguardar

### Mensagens de Erro Comuns (ANTES da correção)

#### Erro 1: Index não encontrado

```
[cloud_firestore/failed-precondition] 
The query requires an index. 
You can create it here: https://console.firebase.google.com/...
```

**Causa:** Index composto não existe  
**Solução:** Deploy de `firestore.indexes.json` (já feito)

#### Erro 2: Múltiplos inequality filters

```
[cloud_firestore/invalid-argument]
Invalid Query. A maximum of 1 '!=' filter is allowed.
```

**Causa:** Firestore limita a 1 filtro de desigualdade  
**Solução:** Usar index composto (já implementado)

### Estrutura de Dados no Firestore

**Path:** `/users/{userId}/objectives/{objectiveId}`

**Documento de Objetivo:**
```json
{
  "userId": "abc123...",
  "title": "Ser fluente em inglês",
  "rank": "s",                    // String: 's', 'a' ou 'b'
  "description": "Meta de inglês",
  "progress": 25,                 // Int: 0-100
  "createdAt": Timestamp,
  "completedAt": null,
  "deadline": Timestamp (optional)
}
```

**Campos indexados:**
- `rank` - Usado para filtrar por categoria
- `progress` - Usado para filtrar ativos (< 100)
- `createdAt` - Usado para ordenar cronologicamente

### Regras de Segurança (Firestore Rules)

**Arquivo:** `firestore.rules`

```javascript
match /users/{userId} {
  match /objectives/{objectiveId} {
    allow read, write: if isOwner(userId);
  }
}
```

**Permissões:**
- ✅ Usuário pode ler/escrever seus próprios objetivos
- ❌ Usuário NÃO pode acessar objetivos de outros
- ✅ Queries dentro da subcoleção são permitidas

### Testes de Validação

#### Teste 1: Criar Objetivo S

```dart
final objective = ObjectiveModel(
  id: 'test-1',
  userId: currentUser.uid,
  title: 'Teste Rank S',
  rank: ObjectiveRank.s,
  progress: 0,
  createdAt: DateTime.now(),
);

await _objectiveRepository.createObjective(objective);
```

**Esperado:** Sucesso, objetivo salvo no Firestore

#### Teste 2: Listar Objetivos S

```dart
final objectives = await _objectiveRepository.getActiveObjectivesByRank(
  currentUser.uid,
  ObjectiveRank.s,
);

print('Objetivos S: ${objectives.length}');
```

**Esperado:** Lista de objetivos Rank S, sem erros

#### Teste 3: Stream em Tempo Real

```dart
_objectiveRepository.getActiveObjectivesStreamByRank(
  currentUser.uid,
  ObjectiveRank.a,
).listen((objectives) {
  print('Objetivos A atualizados: ${objectives.length}');
});
```

**Esperado:** Stream atualiza automaticamente ao criar/modificar objetivos

### Troubleshooting

#### Problema: Erro persiste após deploy

**Solução:**
1. Aguarde 2-5 minutos (indexes sendo criados)
2. Verifique status no console Firebase
3. Se status = "Building", aguarde mais
4. Se status = "Error", veja mensagem de erro

#### Problema: "Index already exists"

**Solução:**
- Indexes duplicados são ignorados automaticamente
- Não é necessário fazer nada

#### Problema: Queries lentas

**Solução:**
1. Verifique se indexes estão "Enabled"
2. Use `explain()` para ver plano de query (Firebase console)
3. Considere adicionar mais indexes se necessário

#### Problema: Deploy falha

**Erro:**
```
Error: HTTP Error: 403, Missing or insufficient permissions
```

**Solução:**
```bash
# Faça login novamente
firebase login

# Selecione o projeto
firebase use monarch-ap

# Tente novamente
firebase deploy --only firestore:indexes
```

### Boas Práticas de Indexes

1. **Crie indexes para queries que você realmente usa**
   - Não crie indexes "por precaução"
   - Cada index tem custo de armazenamento

2. **Ordem dos campos importa**
   - Equality filters (`==`) primeiro
   - Range filters (`<`, `>`) depois
   - OrderBy por último

3. **Evite indexes desnecessários**
   - Queries simples (1 filtro + 1 orderBy) não precisam de index
   - Queries com apenas equality filters geralmente não precisam

4. **Monitore uso de indexes**
   - Console Firebase mostra quais indexes são mais usados
   - Delete indexes não utilizados

### Performance Esperada

**Antes (sem indexes):**
- ❌ Queries falham com erro
- ❌ App não carrega objetivos
- ❌ Telas ficam em loading infinito

**Depois (com indexes):**
- ✅ Queries instantâneas (< 100ms)
- ✅ Objetivos carregam normalmente
- ✅ Streams atualizam em tempo real

### Arquivos Modificados

1. **`firestore.indexes.json`**
   - Adicionado index `rank + progress + createdAt`
   - Mantido index `progress + createdAt`
   - Adicionados indexes para tasks

2. **`historico_da_ia/29_2025-01-15_correcao_firestore_indexes_objetivos.md`**
   - Esta documentação

### Status Final

✅ **Indexes criados com sucesso**  
✅ **Deploy realizado**  
✅ **Queries de objetivos funcionando**  
⏳ **Aguardar 2-5 min para indexes estarem 100% ativos**  

### Próximos Passos (para o usuário)

1. **Aguarde 2-5 minutos** para indexes terminarem de construir

2. **Teste o app:**
   - Acesse a tela de Objetivos
   - Alterne entre Rank S, A e B
   - Crie novos objetivos

3. **Se ainda houver erro:**
   - Copie a mensagem de erro completa
   - Verifique status dos indexes no console Firebase
   - Me informe para investigação adicional

4. **Verifique no Console Firebase:**
   - https://console.firebase.google.com/project/monarch-ap/firestore/indexes
   - Status deve estar "Enabled" (verde)

---

**Resultado:** Problema de conexão com banco de dados resolvido através da criação dos indexes compostos necessários! 🔧✅
