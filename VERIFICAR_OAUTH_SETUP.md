# Verificar OAuth Client ID Android

## ⚠️ Verificação Necessária

O JSON que você mostrou (`{"installed":{...}}`) indica um OAuth Client ID do tipo **"Desktop app"** ou **"Web application"**, não **Android**.

Para o Google Calendar funcionar no app Android, você precisa criar um OAuth Client ID do tipo **Android**.

---

## 🔍 Como Verificar

### No Google Cloud Console:

1. Acesse: https://console.cloud.google.com
2. Selecione o projeto: **`monarch-ap`**
3. Vá em **APIs & Services** → **Credentials**
4. Procure na lista de **OAuth 2.0 Client IDs**

### ✅ O que você deve ver:

Um OAuth Client ID com:
- **Type:** `Android client`
- **Name:** `Monarch Android - com.example.monarch` (ou similar)
- **Package name:** `com.example.monarch`
- **SHA-1 certificate fingerprint:** `C2:DD:D1:23:C0:A2:38:47:FA:4B:3C:29:C9:80:62:CA:21:9A:6C:CD`

### ❌ O que NÃO serve:

- Type: `Desktop client` ❌
- Type: `Web application` ❌
- Sem package name ❌
- Sem SHA-1 ❌

---

## 🔧 Se não existir o Android Client ID:

### Criar agora:

1. Em **Credentials**, clique **+ CREATE CREDENTIALS** → **OAuth client ID**
2. **Application type:** Selecione **Android** (não Desktop ou Web)
3. Preencha:
   - **Name:** `Monarch Android - com.example.monarch`
   - **Package name:** `com.example.monarch`
   - **SHA-1:** `C2:DD:D1:23:C0:A2:38:47:FA:4B:3C:29:C9:80:62:CA:21:9A:6C:CD`
4. Clique **CREATE**

---

## 🧪 Teste Rápido

Após criar/verificar o Android Client ID:

1. ⏱️ **Aguarde 5-10 minutos** para propagação
2. 📱 No app: **PERFIL** → **Google Calendar** → **CONECTAR**
3. ✅ Deve funcionar agora!

---

## 📝 Nota

Você pode ter **múltiplos** OAuth Client IDs:
- ✅ 1 Android (com package `com.example.monarch` + SHA-1)
- ✅ 1 iOS (opcional, para futura versão iOS)
- ✅ 1 Web/Desktop (opcional, se precisar)

Cada um serve para uma plataforma diferente. O app Android **só usa** o Android Client ID.
