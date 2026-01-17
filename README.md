# SYSTEM: AWAKEN

Aplicativo de produtividade com sistema de ranks, stats, penalty zone e shadow system.

## Stack

- **Flutter** + **Dart**
- **Firebase** (Firestore, Auth)
- **Riverpod** (State Management)
- **GoRouter** (Navigation)
- **Google Fonts** (Orbitron, Share Tech Mono)

## Estrutura do Projeto

```
monarch/
├── lib/
│   ├── core/           # Tema, routing, widgets base, utils
│   ├── features/       # Features organizadas por domínio
│   ├── models/         # Modelos de dados
│   ├── repositories/   # Acesso aos dados (Firestore)
│   ├── services/       # Lógica de negócio
│   └── main.dart
├── assets/
│   └── images/
└── test/
```

## Arquitetura de Acesso a Dados

### ⚠️ Importante: Repository Pattern

Este projeto utiliza o **Repository Pattern** para acesso a dados, não um `DatabaseService` centralizado.

**Por quê?**
- ✅ **Separação de responsabilidades**: Cada repository é responsável por um domínio específico (Tasks, Shadows, Objectives, etc.)
- ✅ **Manutenibilidade**: Código mais organizado e fácil de manter
- ✅ **Testabilidade**: Repositories podem ser facilmente mockados para testes
- ✅ **Streams em tempo real**: Cada repository fornece streams para atualizações automáticas
- ✅ **Padrão Firestore**: Usa subcollections (`users/{userId}/tasks`) conforme boas práticas

**Estrutura:**
- `repositories/task_repository.dart` - Operações com tarefas
- `repositories/shadow_repository.dart` - Operações com sombras
- `repositories/objective_repository.dart` - Operações com objetivos S
- `repositories/daily_quest_repository.dart` - Operações com daily quests
- `repositories/trophy_repository.dart` - Operações com troféus
- `repositories/penalty_repository.dart` - Operações com Penalty Zone
- `repositories/user_repository.dart` - Operações com perfil do usuário

**Nota**: Se você encontrar referências a um `database_service.dart` em código antigo ou documentação, saiba que ele foi **removido** e substituído pelos repositories acima. Não recrie um `DatabaseService` - use os repositories específicos.

## 📝 Histórico de Alterações

**⚠️ REGRA IMPORTANTE**: Todas as alterações feitas no projeto devem ser documentadas em `historico_da_ia/`.

### Por quê?

- Rastrear mudanças que desviam do plano original
- Entender o contexto de cada decisão técnica
- Facilitar manutenção e debugging futuro
- Documentar workarounds e soluções temporárias

### Como documentar?

1. Crie um arquivo em `historico_da_ia/` com formato: `YYYY-MM-DD_descricao.md`
2. Documente: problema, solução, arquivos modificados, impacto no plano
3. Adicione referências no código quando necessário

**Ver**: `historico_da_ia/README.md` para mais detalhes sobre o formato.

**Arquivos de histórico existentes:**
- `2025-01-14_melhoria_design.md` - Melhorias visuais e substituição de cores
- `2025-01-14_correcao_firebase.md` - Correção de inicialização do Firebase

## Fase 1 - Concluída ✅

- [x] Projeto Flutter criado
- [x] Dependências configuradas
- [x] Estrutura de pastas criada
- [x] Tema cyberpunk implementado
- [x] Main.dart configurado com ProviderScope

## Fase 2 - Concluída ✅

- [x] Modelo de usuário criado (UserProfileModel)
- [x] AuthService implementado (login, registro, logout)
- [x] Telas de Login e Registro criadas
- [x] Routing configurado com guards de autenticação
- [x] Firebase inicializado no main.dart
- [ ] **Pendente**: Configurar Firebase no projeto (ver FIREBASE_SETUP.md)

## Fase 3 - Concluída ✅

- [x] Modelo ObjectiveModel (Rank S)
- [x] Modelo TrophyModel
- [x] Modelo TaskModel (Rank A/D/E)
- [x] Modelo DailyQuestModel
- [x] Modelo ShadowModel
- [x] Modelo PenaltyStateModel
- [x] UserRepository
- [x] ObjectiveRepository
- [x] TrophyRepository
- [x] TaskRepository
- [x] DailyQuestRepository
- [x] ShadowRepository
- [x] PenaltyRepository
- [x] Firestore Security Rules
- [x] firestore.indexes.json

**Nota sobre arquitetura**: Esta fase implementa o **Repository Pattern**. Não existe um `DatabaseService` centralizado - cada domínio tem seu próprio repository. Ver seção "Arquitetura de Acesso a Dados" acima para mais detalhes.

## Fase 4 - Concluída ✅

- [x] OnboardingService criado
- [x] Providers Riverpod para onboarding
- [x] Tela de Onboarding completa (4 etapas: bem-vindo, objetivos S, mensagem penalty, tutorial)
- [x] Routing atualizado com verificação de onboarding
- [x] Tela de Objetivos S (visualização e edição)

## Próximas Fases

- **Fase 5**: Sistema de Tarefas e Stats
- **Fase 6**: Daily Quests e Penalty Zone 2.0
- **Fase 7**: Shadow System e Troféus
- **Fase 8**: Dashboard e Polimento Final

## Como Executar

```bash
cd monarch
flutter pub get
flutter run
```

**⚠️ IMPORTANTE**: Antes de executar, configure o Firebase seguindo as instruções em [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

## Tema Cyberpunk

O aplicativo usa um tema dark cyberpunk com:
- **Cores principais**: Preto, Cyan (#00FFFF), Amarelo (#FFFF00)
- **Fontes**: Orbitron (títulos), Share Tech Mono (dados)
- **Estilo**: Bordas neon, efeitos glitch, UI futurista

---

**Status**: Fase 4 concluída - Pronto para Fase 5

**Nota**: Para testar a autenticação, onboarding e usar os repositories, é necessário configurar o Firebase primeiro (ver FIREBASE_SETUP.md)
# monarch-app
