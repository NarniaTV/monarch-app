# Como Testar o Modo Offline - FASE 3

## 🧪 Guia Completo de Testes

---

## 📋 Pré-requisitos

1. ✅ App instalado no dispositivo/emulador
2. ✅ Usuário logado
3. ✅ Algumas tarefas criadas (para teste)
4. ✅ Permissão de localização/redes (para detectar conectividade)

---

## 🔧 Configuração do Ambiente

### 1. Instalar Dependências

```bash
cd /Users/aislanpontarollo/Desktop/Monarch/monarch
flutter pub get
```

### 2. Gerar Arquivos Isar (se necessário)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Executar o App

```bash
flutter run
```

---

## ✅ Teste 1: Verificar Inicialização do Isar

### Passos:

1. Abra o app
2. Verifique os logs no console

### Resultado Esperado:

```
✅ Isar inicializado com sucesso
✅ ConnectivityService iniciado - sincronização automática ativa
```

### Se aparecer erro:

- Verifique se `path_provider` está instalado: `flutter pub get`
- Verifique se arquivos `.g.dart` foram gerados: `flutter pub run build_runner build`

---

## ✅ Teste 2: Funcionalidade Online (Baseline)

### Passos:

1. **Certifique-se que está online** (WiFi ou dados móveis ativos)
2. Abra o app
3. Vá no **Dashboard**
4. **Crie uma tarefa** (clique no "+" no centro inferior)
5. Preencha: título, data, horário, rank
6. Clique em **"CRIAR TAREFA"**

### Verificações:

- ✅ Tarefa aparece no Dashboard
- ✅ Tarefa aparece na lista de "Tarefas de Hoje"
- ✅ Não aparece indicador de "MODO OFFLINE" no topo
- ✅ Logs mostram: `[TASK SERVICE] Criando tarefa...`

### Logs Esperados:

```
[TASK SERVICE] Criando tarefa...
[SYNC] Salvando tarefa localmente: NomeDaTarefa
```

---

## ✅ Teste 3: Criar Tarefa Offline

### Passos:

1. **Desative internet:**
   - Android: Configurações → WiFi (OFF) → Dados móveis (OFF)
   - iOS: Configurações → WiFi (OFF) → Dados Celulares (OFF)
   - Emulador: Clique no ícone de WiFi na barra superior

2. **Aguarde 5-10 segundos** (para detectar mudança de conectividade)

3. **No app:**
   - Você deve ver o indicador **"MODO OFFLINE"** no topo do Dashboard
   - Cor: Laranja com ícone de nuvem riscada

4. **Crie uma tarefa:**
   - Clique no "+" no centro inferior
   - Preencha: título, data, horário, rank
   - Clique em **"CRIAR TAREFA"**

### Verificações:

- ✅ Indicador "MODO OFFLINE" aparece no topo
- ✅ Tarefa é criada normalmente (aparece no Dashboard)
- ✅ Tarefa é salva apenas localmente (não vai para Firestore ainda)
- ✅ Logs mostram: `[TASK SERVICE] Offline - usando dados locais do Isar`

### Logs Esperados:

```
[CONNECTIVITY] Conexão perdida
[TASK SERVICE] Offline - usando dados locais do Isar
[SYNC] 📱 Tarefa salva localmente (offline): NomeDaTarefa
```

### Onde verificar:

- **Dashboard:** Tarefa deve aparecer em "Tarefas de Hoje"
- **Aba Tarefas:** Tarefa deve aparecer na lista
- **Firebase Console:** Tarefa **NÃO** deve aparecer ainda (está apenas local)

---

## ✅ Teste 4: Ver Tarefas Offline

### Passos:

1. **Mantenha offline** (internet desligada)
2. **No app:**
   - Vá no **Dashboard**
   - Role para baixo até "Tarefas de Hoje"
   - Ou vá na aba **"TAREFAS"** (segundo ícone do bottom nav)

### Verificações:

- ✅ Tarefas aparecem normalmente
- ✅ Tarefas criadas anteriormente (online) aparecem
- ✅ Tarefas criadas offline aparecem
- ✅ Não há erro "Erro ao carregar tarefas"

### Logs Esperados:

```
[TASK SERVICE] Offline - usando dados locais do Isar
[SYNC] Offline - usando dados locais do Isar
```

---

## ✅ Teste 5: Completar Tarefa Offline

### Passos:

1. **Mantenha offline**
2. **No Dashboard ou aba Tarefas:**
   - Clique em uma tarefa para marcar como completa
   - Ou clique no checkbox ao lado da tarefa

### Verificações:

- ✅ Tarefa é marcada como completa
- ✅ Tarefa sai da lista de "Tarefas de Hoje"
- ✅ Tarefa vai para "Tarefas Completadas"
- ✅ Status é salvo localmente (não vai para Firestore ainda)

### Logs Esperados:

```
[TASK SERVICE] Completando tarefa offline
[TASK COMPLETE] Deletando evento do Google Calendar (pode falhar se offline)
[SYNC] 📱 Tarefa atualizada localmente (offline): NomeDaTarefa
```

---

## ✅ Teste 6: Sincronização Automática ao Reconectar

### Passos:

1. **Mantenha offline** com tarefas criadas/modificadas offline
2. **Reative internet:**
   - Android: WiFi ou Dados móveis (ON)
   - iOS: WiFi ou Dados Celulares (ON)
   - Emulador: Clique no ícone de WiFi na barra superior

3. **Aguarde 5-10 segundos** (sincronização automática)

### Verificações:

- ✅ Indicador "MODO OFFLINE" desaparece
- ✅ Logs mostram sincronização em progresso
- ✅ Tarefas criadas offline aparecem no Firestore
- ✅ Tarefas modificadas offline são atualizadas no Firestore

### Logs Esperados:

```
[CONNECTIVITY] ✅ Conexão restabelecida - sincronizando...
[SYNC] Iniciando sincronização completa...
[SYNC] ✅ X tarefas sincronizadas do Firestore
[SYNC] ✅ Tarefa offline sincronizada: NomeDaTarefa
[SYNC] ✅ Sincronização completa finalizada
[CONNECTIVITY] ✅ Sincronização concluída
```

### Onde verificar:

- **Firebase Console:** Tarefas criadas offline devem aparecer agora
- **Dashboard:** Tarefas continuam aparecendo normalmente
- **Logs:** Sem erros de sincronização

---

## ✅ Teste 7: Múltiplas Operações Offline

### Passos:

1. **Desative internet**
2. **Execute várias operações:**
   - Crie 3-5 tarefas diferentes
   - Complete 2 tarefas
   - Atualize 1 tarefa (mude título/descrição)
3. **Reative internet**

### Verificações:

- ✅ Todas as operações são sincronizadas ao reconectar
- ✅ Tarefas criadas aparecem no Firestore
- ✅ Tarefas completadas são atualizadas no Firestore
- ✅ Tarefas modificadas são atualizadas no Firestore

### Logs Esperados:

```
[SYNC] ✅ 3 tarefas criadas offline sincronizadas
[SYNC] ✅ 2 tarefas completadas offline sincronizadas
[SYNC] ✅ 1 tarefa atualizada offline sincronizada
```

---

## ✅ Teste 8: Verificar Persistência Local

### Passos:

1. **Crie tarefas offline**
2. **Feche o app completamente** (remove da memória)
3. **Abra o app novamente** (ainda offline)

### Verificações:

- ✅ Tarefas criadas offline persistem (não são perdidas)
- ✅ Tarefas aparecem normalmente após reabrir o app
- ✅ Dados locais não são limpos ao fechar o app

---

## ✅ Teste 9: Indicador de Status UI

### Passos:

1. **Desative internet**
2. **Abra o Dashboard**

### Verificações:

- ✅ Indicador laranja "MODO OFFLINE" aparece no topo
- ✅ Ícone: nuvem riscada (`cloud_off_outlined`)
- ✅ Texto: "MODO OFFLINE"
- ✅ Subtítulo: "Dados locais - sincronização automática ao reconectar"

### Quando está online:

- ✅ Indicador "MODO OFFLINE" **NÃO** aparece
- ✅ Interface normal

---

## ❌ Problemas Comuns e Soluções

### Problema 1: "Isar não inicializado"

**Sintoma:**
```
⚠️ Erro ao inicializar Isar: ...
```

**Solução:**
1. Verifique se `path_provider` está no `pubspec.yaml`
2. Execute: `flutter pub get`
3. Gere arquivos Isar: `flutter pub run build_runner build --delete-conflicting-outputs`

---

### Problema 2: Não consigo criar tarefas offline / "não está aparecendo nada"

**Sintoma:**
- Tarefas não aparecem quando offline
- Erros do Firestore: "Unable to resolve host firestore.googleapis.com"
- Não consegue criar tarefas offline

**Solução:**
1. ✅ **CORRIGIDO:** `createTask()` agora verifica se está online antes de criar no Firestore
2. ✅ **CORRIGIDO:** Se offline, cria apenas no Isar (marca `needsSync: true`)
3. Verifique logs:
   - `[TASK SERVICE] Criando tarefa offline: NomeDaTarefa`
   - `[SYNC] 📱 Tarefa salva localmente (offline): NomeDaTarefa`
4. Verifique se indicador "MODO OFFLINE" aparece no topo do Dashboard

**Se ainda não funcionar:**
- Aguarde 5-10 segundos após desativar internet (tempo de detecção)
- Verifique se `_isOnline` está sendo atualizado (indicator no AppBar deve mudar para "OFFLINE")
- Verifique logs para erros no Isar

---

### Problema 3: Tarefas não aparecem offline (já criadas)

**Sintoma:**
- Tarefas criadas online aparecem, mas novas tarefas offline não aparecem

**Solução:**
1. Verifique logs: `[TASK SERVICE] Offline - usando dados locais do Isar`
2. Verifique se Isar está inicializado: `✅ Isar inicializado com sucesso`
3. O stream agora usa polling quando offline (atualiza a cada 3 segundos)
4. Se erro no stream, usa fallback para dados locais automaticamente

---

### Problema 4: Sincronização não funciona ao reconectar

**Sintoma:**
- Tarefas criadas offline não aparecem no Firestore após reconectar

**Solução:**
1. Verifique logs: `[CONNECTIVITY] ✅ Conexão restabelecida - sincronizando...`
2. Verifique se `ConnectivityService.startListening()` foi chamado no `main.dart`
3. Verifique se tarefas têm `needsSync: true` no Isar
4. ✅ **CORRIGIDO:** SyncService agora cria tarefas no Firestore com ID específico (não apenas atualiza)

---

### Problema 5: Indicador offline não aparece

**Sintoma:**
- Está offline mas indicador "MODO OFFLINE" não aparece

**Solução:**
1. Aguarde 5-10 segundos após desativar internet (tempo de detecção)
2. Verifique se timer de conectividade está ativo (a cada 5 segundos)
3. Verifique logs: `[TASK SERVICE] Offline - usando dados locais do Isar`
4. ✅ **CORRIGIDO:** AppBar agora mostra "OFFLINE" dinamicamente

---

## 📊 Checklist de Testes

- [ ] **Teste 1:** Isar inicializa corretamente
- [ ] **Teste 2:** Criar tarefa online funciona
- [ ] **Teste 3:** Criar tarefa offline funciona
- [ ] **Teste 4:** Ver tarefas offline funciona
- [ ] **Teste 5:** Completar tarefa offline funciona
- [ ] **Teste 6:** Sincronização automática ao reconectar funciona
- [ ] **Teste 7:** Múltiplas operações offline são sincronizadas
- [ ] **Teste 8:** Dados persistem após fechar app
- [ ] **Teste 9:** Indicador UI aparece corretamente

---

## 🔍 Como Verificar Logs

### No Terminal (Flutter Run):

```bash
# Execute o app
flutter run

# Procure por:
# - [SYNC] - Sincronização
# - [TASK SERVICE] - Operações de tarefas
# - [CONNECTIVITY] - Conectividade
# - [ISAR] - Operações do Isar
```

### No Android Studio / VS Code:

1. Abra a aba **Debug Console**
2. Filtre por: `[SYNC]`, `[TASK]`, `[CONNECTIVITY]`
3. Observe mensagens de sucesso/erro

---

## 🎯 Resumo do Fluxo

1. **Online:** Firestore → Isar (cache) → UI
2. **Offline:** Isar (local) → UI
3. **Reconectar:** Isar → Firestore (sincronização automática)

---

## ✅ Resultado Final Esperado

- ✅ App funciona completamente offline
- ✅ Todas as operações são salvas localmente
- ✅ Sincronização automática ao reconectar
- ✅ UI mostra status de conectividade
- ✅ Dados persistem após fechar app
- ✅ Sem perda de dados

---

**Boa sorte com os testes!** 🚀

Se encontrar problemas, verifique os logs e compare com os resultados esperados acima.
