# Configuração Google Calendar - SYSTEM AWAKEN

## 📋 Informações Obtidas

**SHA-1 Fingerprint:**
```
C2:DD:D1:23:C0:A2:38:47:FA:4B:3C:29:C9:80:62:CA:21:9A:6C:CD
```

**Package Name:**
```
com.example.monarch
```

**Google Cloud Project:**
```
monarch-ap (Project ID: 804086085402)
```

---

## 🔧 Configuração no Google Cloud Console

### Passo 1: Acessar Google Cloud Console

1. Acesse: https://console.cloud.google.com
2. Selecione o projeto: **`monarch-ap`** (mesmo do Firebase)

---

### Passo 2: Habilitar Google Calendar API

1. No menu lateral, vá em **APIs & Services** → **Library**
2. Busque por: **"Google Calendar API"**
3. Clique em **ENABLE**

---

### Passo 3: Configurar OAuth Consent Screen (se necessário)

Se ainda não configurou:

1. Vá em **APIs & Services** → **OAuth consent screen**
2. Escolha **External** → **CREATE**
3. Preencha:
   - **App name**: `SYSTEM AWAKEN`
   - **User support email**: Seu email
   - **Developer contact information**: Seu email
4. Clique **SAVE AND CONTINUE**
5. Em **Scopes**, adicione: `https://www.googleapis.com/auth/calendar` (se não aparecer, pule)
6. Clique **SAVE AND CONTINUE**
7. Em **Test users**, adicione seu email Google (para testes)
8. Clique **SAVE AND CONTINUE**
9. Revisar e **BACK TO DASHBOARD**

---

### Passo 4: Criar OAuth Client ID (Android)

1. Vá em **APIs & Services** → **Credentials**
2. Clique **+ CREATE CREDENTIALS** → **OAuth client ID**
3. ⚠️ **CRÍTICO:** Em **Application type**, selecione: **Android** (NÃO "Desktop app" ou "Web application")
4. Preencha:
   - **Name**: `Monarch Android - com.example.monarch`
   - **Package name**: `com.example.monarch` (exatamente assim, sem espaços)
   - **SHA-1 certificate fingerprint**: 
     ```
     C2:DD:D1:23:C0:A2:38:47:FA:4B:3C:29:C9:80:62:CA:21:9A:6C:CD
     ```
     (Cole sem espaços ou com dois pontos - ambos funcionam)
5. Clique **CREATE**

**IMPORTANTE:** 
- ✅ Deve criar um OAuth Client ID do tipo **Android** (com package name e SHA-1)
- ❌ NÃO é um "Desktop app" ou "Web application"
- Anote o **Client ID** gerado (será algo como `804086085402-xxxxxxxxxx.apps.googleusercontent.com`)

**Verificação:** Após criar, na lista de Credentials, o OAuth Client ID deve mostrar:
- **Type:** Android client
- **Package name:** com.example.monarch
- **SHA-1:** C2:DD:D1:23:C0:A2:38:47:FA:4B:3C:29:C9:80:62:CA:21:9A:6C:CD

---

### Passo 5: Aguardar Propagação

⏱️ **Aguarde 5-10 minutos** para a configuração se propagar pelos servidores do Google.

---

## 🧪 Testando a Integração

### No App:

1. Abra o app **SYSTEM AWAKEN**
2. Vá na aba **PERFIL** (ícone de usuário no bottom navigation)
3. Role até a seção **"Google Calendar"**
4. Clique em **"CONECTAR GOOGLE CALENDAR"**
5. Selecione sua conta Google
6. Permita o acesso ao Google Calendar
7. ✅ Deve aparecer: **"Google Calendar conectado com sucesso!"**

---

## ❌ Solução de Problemas

### Erro: `ApiException: 10` (DEVELOPER_ERROR)

**Causa:** SHA-1 não configurado ou package name incorreto.

**Solução:**
1. Verifique se o SHA-1 está correto no Google Cloud Console
2. Verifique se o package name é exatamente `com.example.monarch`
3. Aguarde mais 10 minutos após criar o OAuth Client ID
4. Execute `flutter clean` e `flutter run` novamente

### Erro: OAuth Client ID não encontrado

**Causa:** OAuth Client ID criado para package diferente.

**Solução:**
- Verifique no Google Cloud Console se há um OAuth Client ID com:
  - Package name: `com.example.monarch`
  - SHA-1: `C2:DD:D1:23:C0:A2:38:47:FA:4B:3C:29:C9:80:62:CA:21:9A:6C:CD`

### Erro: "This app isn't verified"

**Causa:** App ainda em modo de teste no OAuth Consent Screen.

**Solução:**
- Isso é normal para desenvolvimento
- Adicione seu email como "Test user" no OAuth Consent Screen
- Ou publique o app (não recomendado para testes)

---

## 📝 Notas Importantes

- ✅ O SHA-1 obtido é do **keystore de debug** (`~/.android/debug.keystore`)
- ⚠️ Para **produção/release**, você precisará do SHA-1 do keystore de release
- 🔄 Se mudar de computador, o SHA-1 pode mudar (gerará novo keystore de debug)
- 📱 O OAuth Client ID funciona apenas no app Android (não iOS)

---

## 🔗 Links Úteis

- Google Cloud Console: https://console.cloud.google.com
- Firebase Console: https://console.firebase.google.com
- Google Calendar API Docs: https://developers.google.com/calendar/api
