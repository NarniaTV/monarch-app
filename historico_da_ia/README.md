# Histórico de Alterações - SYSTEM: AWAKEN

## 📋 Regra de Documentação

**TODAS as alterações feitas no projeto devem ser documentadas neste diretório.**

### Formato dos Arquivos

- Nome: `NN_YYYY-MM-DD_descricao_breve.md`
- Onde `NN` é o número sequencial (01, 02, 03, etc.)
- O primeiro histórico criado deve ter 01, o segundo 02, e assim por diante
- Exemplo: `01_2025-01-14_correcao_firebase.md`

### Estrutura Obrigatória

Cada arquivo de histórico deve conter:

1. **Data da alteração**
2. **Motivo da mudança** - Por que foi necessário fazer essa alteração
3. **Problema identificado** - O que estava quebrado ou precisava melhorar
4. **Solução implementada** - O que foi feito
5. **Arquivos modificados** - Lista completa de arquivos alterados
6. **Impacto no plano original** - Se a mudança desvia do plano, explicar o motivo
7. **Próximos passos** - O que precisa ser feito depois

### Quando Documentar

- ✅ Correções de bugs
- ✅ Ajustes de arquitetura
- ✅ Mudanças que desviam do plano original
- ✅ Otimizações e melhorias
- ✅ Resolução de problemas de configuração
- ✅ Mudanças temporárias ou workarounds

### Objetivo

Este histórico serve para:
- Entender o contexto de cada mudança
- Rastrear desvios do plano original
- Facilitar manutenção futura
- Documentar decisões técnicas
- Evitar repetir problemas já resolvidos

---

## 📚 Arquivos de Histórico

- `01_2025-01-14_correcao_firebase.md` - Correção de inicialização do Firebase
- `02_2025-01-14_melhoria_design.md` - Melhorias visuais e substituição de cores (amarelo → magenta)
- `03_2025-01-14_login_portal_hexagonal.md` - LoginScreenV2 com portal hexagonal animado
- `04_2025-01-14_melhorias_portal_login.md` - Melhorias no design do portal hexagonal
- `05_2025-01-14_login_tactical_hud.md` - LoginScreenV3 com design HUD tático
- `06_2025-01-14_login_final_tactical.md` - Versão final com imagem real desfocada
- `07_2025-01-14_login_refinamento_hud.md` - Level 2 Detail: Vignette, Scanlines, Corner Brackets, Ícones com glow
- `08_2025-01-14_aplicacao_design_todas_telas.md` - Remoção de ícones + TacticalBackground em todas as telas
- `09_2025-01-14_refatoracao_register_screen.md` - RegisterScreen: Player Registration com checkbox hexagonal
- `10_2025-01-14_aplicacao_padrao_login_register.md` - Glow effect nos ícones da RegisterScreen (consistência)
- `11_2025-01-14_onboarding_tactical_cards.md` - Cards táticos na Onboarding: Underline inputs + Corner brackets
- `12_2025-01-14_onboarding_militar_futurista.md` - Onboarding: Design Militar Futurista com BeveledRectangleBorder
- `13_2025-01-14_onboarding_todas_paginas_militar.md` - Penalty e Tutorial com design militar completo
- `14_2025-01-14_adicao_rank_c.md` - Adição do Rank C e reorganização da hierarquia (S→A→C→D→E)
- `15_2025-01-14_adicao_rank_b.md` - Adição do Rank B para Metas Secundárias (S→A→B→C→D→E)
- `16_2025-01-14_correcao_back_button_register.md` - Correção do botão de voltar na tela de cadastro (PopScope)
- `17_2025-01-14_correcao_limite_objetivos_onboarding.md` - Correção do erro de limite de objetivos no onboarding
- `18_2025-01-14_fluxo_logout_pos_onboarding.md` - Fluxo de logout após onboarding com mensagem de sucesso (SUPERSEDED by 19)
- `19_2025-01-14_correcao_loop_infinito_onboarding.md` - Correção do loop infinito usando SharedPreferences
- `20_2025-01-14_dashboard_saudacao_reset_onboarding.md` - Dashboard com saudação personalizada e botão de reset
- `21_2025-01-14_fluxo_cadastro_direto_onboarding.md` - Fluxo simplificado: Cadastro → Onboarding direto (sem logout intermediário)
- `22_2025-01-14_onboarding_opcional_com_prompt.md` - Onboarding opcional com verificação inteligente e dialog de escolha (SUPERSEDED by 23)
- `23_2025-01-14_nickname_obrigatorio_unico.md` - Nickname obrigatório e único + Onboarding obrigatório novamente
- `24_2025-01-14_remocao_player_name_correcao_firestore.md` - Remoção do campo Player Name + Correção de permissões Firestore para query de nickname
- `25_2025-01-15_fase5_tarefas_e_stats.md` - **FASE 5 COMPLETA:** Sistema de Tarefas (C/D/E), Stats (Power/Mind/Spirit), XP/Level
- `26_2025-01-15_redesign_dashboard_tactical_hud.md` - Redesign profissional do Dashboard com padrão Tactical HUD completo
- `27_2025-01-15_tela_objetivos_e_melhoria_filtros_tarefas.md` - Tela de gerenciamento de Objetivos S + melhorias nos filtros de tarefas (todas por padrão)
- `28_2025-01-15_suporte_objetivos_a_e_b.md` - Suporte completo para Objetivos A (Metas) e B (Secundárias) com filtros e seletor de rank
- `29_2025-01-15_correcao_firestore_indexes_objetivos.md` - Correção de indexes do Firestore para queries de objetivos com múltiplos filtros
- `30_2025-01-15_refatoracao_dashboard_e_fab_fixo.md` - Dashboard mostra tarefas + FAB fixo no centro inferior + remoção botão tarefas (Parte 1)
- `31_2025-01-15_rank_b_habitos_e_rank_context.md` - Rank B renomeado para Hábitos + navegação contextual (abre tela com rank correto)
- `32_2025-01-15_sistema_habitos_com_frequencia.md` - Sistema completo de hábitos com seletor de frequência + geração automática de tarefas recorrentes
- `33_2025-01-15_refinamento_habitos_horarios_streak.md` - Hábitos Rank D + geração 30 dias + streak + horários + dashboard tarefas diárias ordenadas
- `34_2025-01-15_sistema_avancado_habitos.md` - Exclusão em cascata + geração incremental (20+5+5) + monitoramento automático com DateTime
- `35_2025-01-15_data_hora_obrigatorias.md` - Data e hora obrigatórias em tarefas + horário obrigatório em hábitos + herança de horário nas tarefas geradas
- `36_2025-01-15_fase6_daily_quests_penalty_zone.md` - FASE 6: Daily Quests com streak + Penalty Zone 2.0 + sistema de quitação (3 dias)
- `37_2025-01-15_melhorias_tela_stats.md` - Atributos clicáveis com dialogs informativos + gráfico triangular (radar chart) usando CustomPainter
- `38_2025-01-15_correcao_consistencia_xp.md` - Correção de inconsistência na exibição de XP entre Dashboard e Stats (métodos centralizados no StatsService)
- `39_2025-01-15_reset_completo_e_botao_teste.md` - Reset Service completo + botão de teste no Dashboard (level, XP, stats, objetivos, tarefas, daily quests, penalty zone)
- `40_2025-01-15_correcao_xp_negativo_level1.md` - Correção de XP negativo no Level 1 (xpForLevel(1) agora retorna 0) + centralização completa de cálculos no StatsService
- `41_2025-01-15_dialog_level_up_comemorativo.md` - Dialog comemorativo de Level Up com animações (escala, rotação, glow) + mensagens motivacionais + integração automática em todos os pontos de ganho de XP
- `42_2025-01-15_fase7_shadow_system_trophies_parte1.md` - FASE 7 Parte 1: Modelos, Repositories, Services e Telas (Shadow System e Troféus)
- `43_2025-01-15_fase7_shadow_system_trophies_completo.md` - FASE 7 COMPLETA: Integrações automáticas, Dashboard atualizado, animações suaves, seleção de atributo em hábitos
- `44_2025-01-15_fase8_dashboard_polimento_final_completo.md` - FASE 8 COMPLETA: Tela de Perfil, Bottom Navigation em todas as telas, Dashboard polido, navegação final
- `45_2025-01-15_correcao_erro_carregamento_tarefas.md` - Correção de erro ao carregar tarefas: tratamento robusto de erros, validação de dados, mensagens de erro melhoradas
- `46_2025-01-15_fase1_notificacoes_push_completo.md` - **FASE 1 COMPLETA:** Sistema de Notificações Push (FCM + Local Notifications) integrado em todos os services
- `47_2025-01-15_fase2_google_calendar_completo.md` - **FASE 2 COMPLETA:** Integração Google Calendar (sincronização automática de tarefas e hábitos, OAuth, eventos recorrentes)
