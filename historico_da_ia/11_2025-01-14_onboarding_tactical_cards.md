# Histórico - Onboarding: Cards Táticos Estilo Login

## Data: 14/01/2025

### Motivo da Mudança
O usuário solicitou que as boxes (cards) da tela de onboarding fossem iguais ou parecidas com as boxes da tela de login. As boxes atuais tinham design genérico com bordas arredondadas e inputs com bordas completas, desalinhadas com o padrão tático estabelecido nas telas de autenticação.

### Problema Identificado
- **Cards genéricos**: SystemCard com bordas arredondadas padrão
- **Inputs desalinhados**: Bordas completas ao invés de underline
- **Falta de identidade tática**: Sem corner brackets ou micro-detalhes
- **Inconsistência visual**: Completamente diferente das telas de Login/Register

### Solução Implementada

#### 1. TACTICAL OBJECTIVE CARD

**Novo método criado:** `_buildTacticalObjectiveCard(int index)`

**Estrutura:**
```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    Container(
      // Tactical frame
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.rankS),
        borderRadius: BorderRadius.zero, // Sharp corners
        boxShadow: [glow effect],
      ),
      child: Column([inputs]),
    ),
    ..._buildCornerBrackets(), // L-shapes nos cantos
  ],
)
```

**Antes:**
```dart
SystemCard(
  borderColor: AppColors.rankS,
  child: Column([
    TextFormField(...), // Bordas completas
    TextButton.icon(...), // Botão padrão
  ]),
)
```

**Depois:**
```dart
_buildTacticalObjectiveCard(index) // Tactical frame + Corner brackets
```

#### 2. INPUTS UNDERLINE STYLE

**Antes (Bordas completas):**
```dart
TextFormField(
  decoration: const InputDecoration(
    labelText: 'TÍTULO *',
    // Usa border padrão do tema (bordas completas)
  ),
)
```

**Depois (Underline minimalista):**
```dart
TextFormField(
  style: GoogleFonts.shareTechMono(
    color: Colors.white,
    fontSize: 14,
  ),
  cursorColor: AppColors.rankS,
  decoration: InputDecoration(
    labelText: 'TÍTULO *',
    hintText: 'Ex: Formar em Engenharia',
    labelStyle: GoogleFonts.shareTechMono(
      color: AppColors.rankS,
      fontSize: 11,
      letterSpacing: 0.5,
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.rankS.withValues(alpha: 0.5),
        width: 1,
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.rankS,
        width: 2,
      ),
    ),
  ),
)
```

**Características:**
- ✅ Underline apenas (sem bordas laterais)
- ✅ Fonte: Share Tech Mono (monospaced)
- ✅ Label e hint em cor S rank (dourado/amarelo)
- ✅ Texto branco puro
- ✅ Cursor na cor do rank

#### 3. CONTAINER TÁTICO

**Especificações:**
```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.black.withValues(alpha: 0.5), // Glass effect
    border: Border.all(
      color: AppColors.rankS,
      width: 1.5,
    ),
    borderRadius: BorderRadius.zero, // Sharp corners
    boxShadow: [
      BoxShadow(
        color: AppColors.rankS.withValues(alpha: 0.3),
        blurRadius: 20,
        spreadRadius: 2,
      ), // Glow dourado
    ],
  ),
)
```

**Elementos:**
- Fundo: Preto 50% translúcido
- Borda: S rank (dourada) 1.5px
- Cantos: Afiados (zero radius)
- Glow: BoxShadow dourado sutil

#### 4. CORNER BRACKETS

**Implementação:**
```dart
List<Widget> _buildCornerBrackets() {
  const bracketSize = 16.0;
  const bracketThickness = 2.0;
  final bracketColor = AppColors.rankS;

  return [
    // Top Left
    Positioned(
      top: -bracketThickness / 2,
      left: -bracketThickness / 2,
      child: Container(
        width: bracketSize,
        height: bracketSize,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(...),
            left: BorderSide(...),
          ),
        ),
      ),
    ),
    // ... outros 3 cantos
  ];
}
```

**Características:**
- Tamanho: 16x16px (ligeiramente menor que Login/Register)
- Espessura: 2px
- Cor: S rank (dourado)
- Posicionamento: Absoluto nos 4 cantos

#### 5. BOTÃO DEADLINE MINIMALISTA

**Antes (TextButton padrão):**
```dart
TextButton.icon(
  onPressed: (...),
  icon: const Icon(Icons.calendar_today),
  label: Text(...),
)
```

**Depois (Container minimalista):**
```dart
InkWell(
  onTap: (...),
  child: Container(
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      border: Border.all(
        color: AppColors.cyan.withValues(alpha: 0.5),
        width: 1,
      ),
      borderRadius: BorderRadius.zero,
    ),
    child: Row([
      Icon(Icons.calendar_today, color: AppColors.cyan, size: 16),
      Text(..., style: GoogleFonts.shareTechMono(...)),
    ]),
  ),
)
```

**Características:**
- Borda cyan fina (50% alpha)
- Cantos afiados
- Ícone e texto cyan
- Fonte monospaced
- Tamanho compacto

#### 6. HEADER DO CARD

**Antes:**
```dart
Text(
  'OBJETIVO ${index + 1}',
  style: Theme.of(context).textTheme.titleSmall?.copyWith(
    color: AppColors.rankS,
  ),
)
```

**Depois:**
```dart
Text(
  'OBJETIVO ${index + 1}',
  style: GoogleFonts.shareTechMono(
    color: AppColors.rankS,
    fontSize: 12,
    letterSpacing: 1,
    fontWeight: FontWeight.bold,
  ),
)
```

**Mudanças:**
- Fonte: Share Tech Mono (technical)
- Tamanho: 12px (menor, mais compacto)
- Letter spacing: 1 (espaçado)
- Bold para destaque

### Arquivos Modificados

#### Modificados
- `lib/features/onboarding/presentation/onboarding_screen.dart`
  - Adicionado import: `google_fonts`
  - Método `_buildObjectivesPage()`: Substituído SystemCard por `_buildTacticalObjectiveCard()`
  - Criado método: `_buildTacticalObjectiveCard(int index)` - Card tático completo
  - Criado método: `_buildCornerBrackets()` - L-shapes nos cantos

#### Documentação
- `historico_da_ia/11_2025-01-14_onboarding_tactical_cards.md` (criado)
- `historico_da_ia/README.md` (atualizado)

### Comparação Visual

| Elemento | Antes | Depois |
|----------|-------|--------|
| **Container** | SystemCard (bordas arredondadas) | Tactical frame (cantos afiados) |
| **Bordas** | Arredondadas | **Sharp (zero radius)** |
| **Inputs** | Bordas completas | **Underline apenas** |
| **Fonte Inputs** | Padrão do tema | **Share Tech Mono** |
| **Corner Brackets** | ❌ Ausentes | **✅ L-shapes dourados** |
| **Botão Deadline** | TextButton padrão | **Container minimalista cyan** |
| **Header** | Fonte padrão | **Share Tech Mono bold** |
| **Glow** | Sem glow | **BoxShadow dourado** |

### Detalhes Técnicos

#### Estrutura do Card

```dart
Widget _buildTacticalObjectiveCard(int index) {
  return Stack(
    clipBehavior: Clip.none, // Permite brackets fora do container
    children: [
      // Layer 1: Main Container
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(...),
        child: Column([
          // Header
          Text('OBJETIVO ${index + 1}', ...),
          
          // Title Input (underline)
          TextFormField(...),
          
          // Description Input (underline, multiline)
          TextFormField(maxLines: 3, ...),
          
          // Deadline Button (minimalist)
          InkWell(child: Container(...)),
        ]),
      ),
      
      // Layer 2: Corner Brackets (4x Positioned)
      ..._buildCornerBrackets(),
    ],
  );
}
```

#### Corner Brackets vs Login/Register

| Aspecto | Login/Register | Onboarding |
|---------|----------------|------------|
| Tamanho | 20x20px | 16x16px (menor) |
| Espessura | 2.5px | 2px (mais fina) |
| Cor | Cyan (#00F0FF) | S Rank (dourado) |
| Contexto | Autenticação | Objetivos sagrados |

**Razão:** Cards de objetivos são múltiplos na mesma tela, por isso brackets menores para não poluir visualmente.

#### Input Decoration Pattern

**Padrão estabelecido para inputs underline:**
```dart
decoration: InputDecoration(
  labelStyle: GoogleFonts.shareTechMono(
    color: [cor temática],
    fontSize: 11,
    letterSpacing: 0.5,
  ),
  enabledBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      color: [cor temática].withValues(alpha: 0.5),
      width: 1,
    ),
  ),
  focusedBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      color: [cor temática],
      width: 2,
    ),
  ),
)
```

### Impacto no Plano Original
✅ Não desvia do plano. Melhoria de UI/UX que alinha a tela de onboarding com o padrão visual estabelecido nas telas de autenticação, mantendo consistência em todo o app.

### Próximos Passos
1. Considerar aplicar o mesmo padrão em `_buildPenaltyMessagePage()` (opcional)
2. Avaliar se outras telas com formulários devem seguir o mesmo padrão
3. Testar usabilidade dos inputs underline em telas com muitos campos

### Status
✅ **Código compila sem erros**
✅ **Cards táticos implementados**
✅ **Inputs underline estilo Login**
✅ **Corner brackets adicionados**
✅ **Botão deadline minimalista**
✅ **Fonte Share Tech Mono aplicada**
✅ **Glow effect S rank**
✅ **Consistência visual com Login/Register**

---

## Checklist de Conformidade

### Estrutura
- ✅ Stack com clipBehavior: Clip.none
- ✅ Container tático com glass effect
- ✅ Corner brackets posicionados

### Estilo Visual
- ✅ BorderRadius.zero (cantos afiados)
- ✅ Border S rank 1.5px
- ✅ BoxShadow glow dourado
- ✅ Fundo preto translúcido (50%)

### Inputs
- ✅ UnderlineInputBorder apenas
- ✅ Fonte: Share Tech Mono
- ✅ Label S rank
- ✅ Hint translúcido
- ✅ Cursor S rank

### Botão Deadline
- ✅ Container com borda cyan
- ✅ Cantos afiados
- ✅ Ícone e texto cyan
- ✅ Fonte monospaced

### Corner Brackets
- ✅ 4 L-shapes posicionados
- ✅ Tamanho: 16x16px
- ✅ Espessura: 2px
- ✅ Cor: S rank

### Consistência
- ✅ Alinhado com Login/Register
- ✅ Mantém hierarquia visual
- ✅ Identidade tática reforçada

---

## Código Completo dos Métodos Criados

### _buildTacticalObjectiveCard()

```dart
Widget _buildTacticalObjectiveCard(int index) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      // Main Container
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(
            color: AppColors.rankS,
            width: 1.5,
          ),
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: AppColors.rankS.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'OBJETIVO ${index + 1}',
              style: GoogleFonts.shareTechMono(
                color: AppColors.rankS,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Title Input (Underline style)
            TextFormField(
              controller: _objectiveTitleControllers[index],
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.shareTechMono(
                color: Colors.white,
                fontSize: 14,
              ),
              cursorColor: AppColors.rankS,
              decoration: InputDecoration(
                labelText: 'TÍTULO *',
                hintText: 'Ex: Formar em Engenharia',
                labelStyle: GoogleFonts.shareTechMono(
                  color: AppColors.rankS,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                hintStyle: GoogleFonts.shareTechMono(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.rankS.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.rankS,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description Input (Underline style)
            TextFormField(
              controller: _objectiveDescriptionControllers[index],
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              style: GoogleFonts.shareTechMono(
                color: Colors.white,
                fontSize: 13,
              ),
              cursorColor: AppColors.rankS,
              decoration: InputDecoration(
                labelText: 'DESCRIÇÃO (OPCIONAL)',
                hintText: 'Detalhes sobre este objetivo...',
                labelStyle: GoogleFonts.shareTechMono(
                  color: AppColors.rankS.withValues(alpha: 0.7),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                hintStyle: GoogleFonts.shareTechMono(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.rankS.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.rankS,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Deadline Button (Minimalist style)
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (date != null) {
                  setState(() {
                    _objectiveDeadlines[index] = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.cyan,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _objectiveDeadlines[index] != null
                          ? 'Deadline: ${_objectiveDeadlines[index]!.day}/${_objectiveDeadlines[index]!.month}/${_objectiveDeadlines[index]!.year}'
                          : 'DEFINIR DEADLINE (OPCIONAL)',
                      style: GoogleFonts.shareTechMono(
                        color: AppColors.cyan,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Corner Brackets (L-shapes)
      ..._buildCornerBrackets(),
    ],
  );
}
```

### _buildCornerBrackets()

```dart
List<Widget> _buildCornerBrackets() {
  const bracketSize = 16.0;
  const bracketThickness = 2.0;
  final bracketColor = AppColors.rankS;

  return [
    // Top Left
    Positioned(
      top: -bracketThickness / 2,
      left: -bracketThickness / 2,
      child: Container(
        width: bracketSize,
        height: bracketSize,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: bracketColor, width: bracketThickness),
            left: BorderSide(color: bracketColor, width: bracketThickness),
          ),
        ),
      ),
    ),
    // Top Right
    Positioned(
      top: -bracketThickness / 2,
      right: -bracketThickness / 2,
      child: Container(
        width: bracketSize,
        height: bracketSize,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: bracketColor, width: bracketThickness),
            right: BorderSide(color: bracketColor, width: bracketThickness),
          ),
        ),
      ),
    ),
    // Bottom Left
    Positioned(
      bottom: -bracketThickness / 2,
      left: -bracketThickness / 2,
      child: Container(
        width: bracketSize,
        height: bracketSize,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: bracketColor, width: bracketThickness),
            left: BorderSide(color: bracketColor, width: bracketThickness),
          ),
        ),
      ),
    ),
    // Bottom Right
    Positioned(
      bottom: -bracketThickness / 2,
      right: -bracketThickness / 2,
      child: Container(
        width: bracketSize,
        height: bracketSize,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: bracketColor, width: bracketThickness),
            right: BorderSide(color: bracketColor, width: bracketThickness),
          ),
        ),
      ),
    ),
  ];
}
```

---

## Observações Finais

Esta refatoração traz a tela de onboarding para o mesmo nível de polish visual das telas de autenticação. Os cards agora:

1. **Mantém identidade tática**: Corner brackets, cantos afiados, glow effect
2. **Seguem padrão de inputs**: Underline minimalista, Share Tech Mono
3. **Reforçam hierarquia**: S rank dourado para objetivos sagrados
4. **Melhoram consistência**: Todo o app segue o mesmo design language

A mudança é puramente visual e não afeta funcionalidade ou arquitetura.
