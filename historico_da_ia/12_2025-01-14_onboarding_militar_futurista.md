# Histórico - Onboarding: Design Militar Futurista

## Data: 14/01/2025

### Motivo da Mudança
O usuário solicitou refatoração completa do design da tela de onboarding para abandonar o estilo "Arcade/Neon" e adotar um estilo "Militar Futurista/Sério" (System: Awaken), focando em alta legibilidade e sobriedade visual característica de HUDs táticos militares avançados.

### Problema Identificado
- **Estilo Arcade/Neon**: Cards com glow excessivo e cores vibrantes
- **Baixa legibilidade**: Contraste insuficiente em alguns elementos
- **Bordas arredondadas**: Não condizem com estética militar/tática
- **Falta de seriedade**: Visual muito lúdico para um sistema de "condições de vitória"

### Solução Implementada

#### 1. HEADER (TEXTOS)

**Título Principal:**
```dart
Text(
  'SUAS 3 CONDIÇÕES DE VITÓRIA',
  style: GoogleFonts.orbitron(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w900, // Extra bold
    letterSpacing: 1.5,
  ),
  textAlign: TextAlign.center,
)
```

**Características:**
- Fonte: Orbitron w900 (peso máximo)
- Cor: Branco puro (#FFFFFF)
- Tamanho: 24px (impactante)
- Letter spacing: 1.5 (espaçamento militar)
- Texto: "CONDIÇÕES DE VITÓRIA" (linguagem tática)

**Subtítulo (Diretriz Primária):**
```dart
Text(
  '// DIRETRIZ PRIMÁRIA\nDefina os alicerces da sua nova realidade. Estes são os objetivos pelos quais você lutará quando a exaustão e o fracasso tentarem te parar.',
  style: GoogleFonts.shareTechMono(
    color: const Color(0xFFB0BEC5), // Blue Grey 200
    fontSize: 14,
    height: 1.5,
  ),
  textAlign: TextAlign.center,
)
```

**Características:**
- Prefixo: `// DIRETRIZ PRIMÁRIA` (comentário de código)
- Fonte: Share Tech Mono (monospaced)
- Cor: #B0BEC5 (Blue Grey 200 - alta legibilidade)
- Tamanho: 14px
- Line height: 1.5 (respiração do texto)
- Padding: 16px horizontal

**Antes vs Depois:**

| Elemento | Antes | Depois |
|----------|-------|--------|
| Título | "CONQUISTAS SAGRADAS" | "CONDIÇÕES DE VITÓRIA" |
| Fonte Título | Theme padrão | Orbitron w900 |
| Cor Título | Cyan | Branco puro |
| Subtítulo | Genérico | "// DIRETRIZ PRIMÁRIA" + texto tático |
| Cor Subtítulo | textSecondary (escuro) | #B0BEC5 (legível) |

#### 2. CARDS DOS OBJETIVOS (DESIGN TECH)

**Estrutura:**
```dart
Card(
  elevation: 2,
  shadowColor: Colors.black.withValues(alpha: 0.5),
  shape: BeveledRectangleBorder(
    borderRadius: BorderRadius.circular(10.0), // Cantos chanfrados
    side: BorderSide(
      color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
      width: 1,
    ),
  ),
  color: const Color(0xFF0F1115), // Gunmetal Dark
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column([...]),
  ),
)
```

**Mudanças Críticas:**

1. **Shape: BeveledRectangleBorder**
   - Cantos chanfrados (não arredondados)
   - Radius: 10.0
   - Efeito: Cortes diagonais nos cantos

2. **Cor de Fundo: Gunmetal Dark**
   - De: Preto translúcido (#000000 50% alpha)
   - Para: #0F1115 (Gunmetal Dark - cinza escuro azulado)
   - Razão: Tom sóbrio e militar

3. **Borda: Cyan translúcido**
   - Cor: #2DD4BF (Teal/Cyan)
   - Alpha: 0.3 (30% opacidade)
   - Width: 1px (linha fina e precisa)

4. **Sombra: Sutil e seca**
   - Elevation: 2 (mínima)
   - ShadowColor: Preto 50% alpha
   - Removido: Glow excessivo anterior

**Header do Card:**
```dart
Text(
  'OBJETIVO ${index + 1}',
  style: GoogleFonts.orbitron(
    color: const Color(0xFF2DD4BF), // Cyan
    fontSize: 14,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w700,
  ),
)
```

**Antes vs Depois:**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| Container | Stack com Positioned | Card simples |
| Shape | BorderRadius.zero | BeveledRectangleBorder |
| Cor fundo | Preto 50% | Gunmetal Dark (#0F1115) |
| Borda | S rank dourado | Cyan translúcido |
| Glow | BoxShadow intenso | Elevation 2 (sutil) |
| Corner Brackets | ✅ Presente | ❌ Removido |

#### 3. INPUTS DE TEXTO (MILITAR STYLE)

**Novo método:** `_buildMilitaryInput()`

```dart
Widget _buildMilitaryInput({
  required TextEditingController controller,
  required String label,
  required String hint,
  int maxLines = 1,
  TextCapitalization textCapitalization = TextCapitalization.none,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1D24), // Mais claro que o card
      borderRadius: BorderRadius.circular(4), // Levemente arredondado
      border: Border.all(
        color: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    child: TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      style: GoogleFonts.orbitron(
        color: Colors.white,
        fontSize: 16,
      ),
      cursorColor: const Color(0xFF2DD4BF),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.shareTechMono(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.7),
          fontSize: 12,
          letterSpacing: 0.5,
        ),
        hintStyle: GoogleFonts.shareTechMono(
          color: Colors.white.withValues(alpha: 0.5), // 50% alpha
          fontSize: 14,
        ),
        border: InputBorder.none, // Sem bordas internas
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    ),
  );
}
```

**Características:**

1. **Fundo do Input:**
   - Cor: #1A1D24 (cinza escuro levemente mais claro que o card)
   - Contraste: Sutil mas visível

2. **Borda Externa:**
   - Cor: Cyan 20% alpha
   - Width: 1px
   - Radius: 4px (levemente arredondado para suavidade)

3. **Texto Digitado:**
   - Fonte: Orbitron (não monospaced)
   - Cor: Branco puro
   - Tamanho: 16px (legível)

4. **Placeholder (Hint):**
   - Fonte: Share Tech Mono
   - Cor: Branco 50% alpha (alta legibilidade)
   - Antes: 30% alpha (muito escuro)

5. **Label:**
   - Fonte: Share Tech Mono
   - Cor: Cyan 70% alpha
   - Tamanho: 12px

6. **Cursor:**
   - Cor: Cyan (#2DD4BF)

**Antes vs Depois:**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| Fundo | Transparente | #1A1D24 (cinza escuro) |
| Borda | Underline S rank | Container com borda cyan |
| Fonte | Share Tech Mono | Orbitron (mais legível) |
| Hint alpha | 30% | 50% (maior contraste) |
| Border style | Underline | Box com border radius 4 |

#### 4. BOTÃO DEADLINE (MINIMALISTA)

**Implementação:**
```dart
Container(
  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  decoration: BoxDecoration(
    border: Border.all(
      color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Row([
    Icon(Icons.calendar_today, color: 0xFF2DD4BF, size: 16),
    Text(..., style: ShareTechMono),
  ]),
)
```

**Mudanças:**
- Border radius: De 0 para 4 (levemente arredondado)
- Cor: De AppColors.cyan para #2DD4BF (mesmo cyan, consistência)
- Tamanho fonte: De 10 para 11 (legibilidade)

#### 5. BOTÃO CONTINUAR (TECH STYLE)

**Novo método:** `_buildMilitaryContinueButton()`

```dart
Widget _buildMilitaryContinueButton() {
  return SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: _currentPage == 3
          ? (_isLoading ? null : _handleFinish)
          : _nextPage,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00E5FF), // Ciano
        foregroundColor: Colors.black, // Texto preto
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        _currentPage == 3 ? 'ENTRAR NO SISTEMA' : 'CONTINUAR',
        style: GoogleFonts.orbitron(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    ),
  );
}
```

**Características:**

1. **Shape: BeveledRectangleBorder**
   - Cantos chanfrados (consistente com cards)
   - Radius: 10.0

2. **Cor de fundo:**
   - #00E5FF (Ciano vibrante)
   - Contraste máximo

3. **Texto:**
   - Cor: Preto (máximo contraste com fundo)
   - Fonte: Orbitron w700
   - Letter spacing: 1.5

4. **Elevation:**
   - 0 (flat, sem sombra)
   - Shadow: Transparente

**Antes vs Depois:**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| Widget | SystemButton | ElevatedButton |
| Shape | Padrão | BeveledRectangleBorder |
| Cor | AppColors.cyan | #00E5FF (ciano) |
| Texto cor | Branco | Preto (contraste) |
| Elevation | Padrão | 0 (flat) |

### Arquivos Modificados

#### Modificados
- `lib/features/onboarding/presentation/onboarding_screen.dart`
  - Header `_buildObjectivesPage()`: Novo título e subtítulo
  - Método `_buildTacticalObjectiveCard()`: Refatorado de Stack para Card
  - Criado método: `_buildMilitaryInput()` - Inputs com fundo e borda
  - Método `_buildDeadlineButton()`: Atualizado com border radius 4
  - Criado método: `_buildMilitaryContinueButton()` - Botão com BeveledRectangleBorder
  - Removido: `_buildCornerBrackets()` (obsoleto)
  - Removido import: `system_button.dart` (não mais usado)

#### Documentação
- `historico_da_ia/12_2025-01-14_onboarding_militar_futurista.md` (criado)
- `historico_da_ia/README.md` (atualizado)

### Paleta de Cores (Militar Futurista)

```dart
// Estrutural
const gunmetalDark = Color(0xFF0F1115);     // Fundo dos cards
const inputBackground = Color(0xFF1A1D24);   // Fundo dos inputs

// Acentos
const cyanPrimary = Color(0xFF2DD4BF);       // Bordas, labels
const cyanButton = Color(0xFF00E5FF);        // Botão continuar

// Texto
const white = Color(0xFFFFFFFF);             // Texto principal
const blueGrey200 = Color(0xFFB0BEC5);       // Subtítulo
```

### Comparação: Arcade vs Militar

| Aspecto | Arcade/Neon (Antes) | Militar Futurista (Depois) |
|---------|---------------------|----------------------------|
| **Cantos** | Afiados (zero radius) ou arredondados | **Chanfrados (beveled)** |
| **Cores** | S rank dourado, glow intenso | **Cyan sóbrio, gunmetal** |
| **Inputs** | Underline apenas | **Container com fundo e borda** |
| **Contraste** | Médio (hint 30% alpha) | **Alto (hint 50% alpha)** |
| **Sombras** | BoxShadow glow | **Elevation 2 (sutil)** |
| **Corner Brackets** | ✅ Presente | **❌ Removido** |
| **Estética** | Cyberpunk ornamentado | **HUD tático limpo** |

### Detalhes Técnicos

#### BeveledRectangleBorder

```dart
BeveledRectangleBorder(
  borderRadius: BorderRadius.circular(10.0),
  side: BorderSide(...),
)
```

**Efeito:**
- Cantos cortados em diagonal (45°)
- Aparência de "placa metálica" cortada
- Estética militar/industrial

**Diferença de RoundedRectangleBorder:**
- Rounded: Curva suave nos cantos
- Beveled: Corte diagonal reto

#### Hierarquia de Cores

1. **Fundo mais escuro:** Gunmetal Dark (#0F1115)
2. **Input background:** Um tom mais claro (#1A1D24)
3. **Bordas:** Cyan translúcido (20-30% alpha)
4. **Texto:** Branco puro ou Blue Grey 200

**Razão:** Criar profundidade sem depender de sombras

### Impacto no Plano Original
✅ Não desvia do plano. Refatoração de UI/UX que melhora legibilidade e seriedade visual sem afetar funcionalidade ou arquitetura.

### Próximos Passos
1. Considerar aplicar o mesmo estilo às outras páginas do onboarding (penalty, tutorial)
2. Avaliar feedback sobre legibilidade dos inputs
3. Testar em diferentes tamanhos de tela

### Status
✅ **Código compila sem erros**
✅ **Estilo Militar Futurista implementado**
✅ **BeveledRectangleBorder em cards e botões**
✅ **Inputs com fundo (#1A1D24) e bordas**
✅ **Contraste aumentado (hint 50% alpha)**
✅ **Corner brackets removidos**
✅ **Header com "CONDIÇÕES DE VITÓRIA"**
✅ **Alta legibilidade alcançada**

---

## Checklist de Conformidade

### Header
- ✅ Título: "SUAS 3 CONDIÇÕES DE VITÓRIA"
- ✅ Fonte: Orbitron w900, branco, 24px
- ✅ Letter spacing: 1.5
- ✅ Subtítulo: "// DIRETRIZ PRIMÁRIA..."
- ✅ Fonte: Share Tech Mono, #B0BEC5, 14px

### Cards
- ✅ Shape: BeveledRectangleBorder (radius 10)
- ✅ Cor fundo: #0F1115 (Gunmetal Dark)
- ✅ Borda: Cyan 30% alpha, width 1
- ✅ Elevation: 2 (sombra sutil)
- ✅ Glow excessivo removido

### Inputs
- ✅ Fundo: #1A1D24
- ✅ Texto: Orbitron branco, 16px
- ✅ Hint: Share Tech Mono, white 50% alpha
- ✅ Border: Cyan 20% alpha
- ✅ Border radius: 4px

### Botão Continuar
- ✅ Shape: BeveledRectangleBorder (radius 10)
- ✅ Cor: #00E5FF (ciano)
- ✅ Texto: Preto, Orbitron w700
- ✅ Elevation: 0 (flat)

---

## Observações Finais

Esta refatoração transforma completamente a estética da tela de onboarding:

1. **De Arcade para Militar:** Cores vibrantes e glow substituídos por tons sóbrios e linhas precisas
2. **Alta legibilidade:** Contraste aumentado em todos os elementos de texto
3. **Cantos chanfrados:** BeveledRectangleBorder cria identidade única
4. **Sobriedade visual:** Remoção de elementos ornamentais (brackets) em favor de clareza

O resultado é um HUD tático que parece um sistema operacional militar avançado, mantendo funcionalidade completa enquanto eleva o nível de profissionalismo visual.
