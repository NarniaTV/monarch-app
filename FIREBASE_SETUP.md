# Configuração do Firebase

Para que a autenticação funcione, você precisa configurar o Firebase no projeto.

## Passo 1: Criar Projeto no Firebase Console

1. Acesse [Firebase Console](https://console.firebase.google.com)
2. Clique em "Adicionar projeto" ou selecione um projeto existente
3. Siga o assistente para criar/configurar o projeto

## Passo 2: Adicionar App Android ao Firebase

1. No Firebase Console, clique em "Adicionar app" → Android
2. Informe o package name: `com.example.monarch` (ou o que você configurou)
3. Baixe o arquivo `google-services.json`
4. Coloque o arquivo em: `monarch/android/app/google-services.json`

## Passo 3: Instalar FlutterFire CLI

```bash
flutter pub global activate flutterfire_cli
```

## Passo 4: Configurar Firebase no Projeto

```bash
cd monarch
flutterfire configure
```

Este comando irá:
- Detectar suas plataformas (Android, iOS, etc.)
- Gerar o arquivo `lib/firebase_options.dart` automaticamente
- Configurar o projeto para usar Firebase

## Passo 5: Habilitar Authentication no Firebase Console

1. No Firebase Console, vá em **Authentication**
2. Clique em "Começar"
3. Na aba **Sign-in method**, habilite:
   - **Email/Password** (ativar e salvar)

## Passo 6: Verificar

Após configurar, o arquivo `lib/firebase_options.dart` será gerado automaticamente e o app poderá se conectar ao Firebase.

## Nota

O arquivo `lib/firebase_options.dart` atual é apenas um placeholder. Ele será substituído quando você executar `flutterfire configure`.
