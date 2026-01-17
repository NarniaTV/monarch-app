# 🔧 Correção: Plugin connectivity_plus não está registrado

## ⚠️ Problema

```
MissingPluginException(No implementation found for method check on channel dev.fluttercommunity.plus/connectivity)
```

Este erro acontece porque o plugin `connectivity_plus` não está registrado corretamente no app. Isso é comum após hot restart/reload.

## ✅ Solução

### 1. Reinstalar o app completamente

**NÃO use hot restart ou hot reload!** Você precisa reinstalar o app completamente:

```bash
# 1. Parar o app atual
# No terminal ou no Android Studio, pressione Ctrl+C ou pare a execução

# 2. Desinstalar o app do dispositivo/emulador (via ADB)
adb uninstall com.example.monarch

# 3. Reinstalar completamente
flutter run

# OU se estiver usando Android Studio:
# Stop → Clean Project → Rebuild Project → Run
```

### 2. Verificar se está usando Android 12+ (API 31+)

Se estiver usando Android 12+, pode precisar adicionar permissões no `AndroidManifest.xml`. Verifique se estas linhas estão presentes:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

### 3. Limpar build cache (se ainda não funcionar)

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### 4. Verificar versão do connectivity_plus

No `pubspec.yaml`, certifique-se de que está usando:

```yaml
connectivity_plus: ^6.0.5
```

---

## 🧪 Como testar após reinstalar

1. **Instale o app completamente** (não use hot restart)
2. **Aguarde o app inicializar** (verifique logs: `✅ ConnectivityService iniciado`)
3. **Desligue o WiFi** no dispositivo/emulador
4. **Aguarde 3-5 segundos**
5. **Verifique:**
   - AppBar mostra "OFFLINE" (laranja)
   - Banner "MODO OFFLINE" aparece no Dashboard
   - Logs mostram: `[SYNC] ❌ Sem conexão de rede detectada (OFFLINE)`

---

## 📝 Logs esperados (após correção)

**Ao iniciar o app:**
```
✅ ConnectivityService iniciado - sincronização automática ativa
[CONNECTIVITY] ✅ Listener de conectividade iniciado
```

**Ao desligar WiFi:**
```
[CONNECTIVITY] Mudança detectada: OFFLINE (none)
[SYNC] ❌ Sem conexão de rede detectada (OFFLINE)
[DASHBOARD] Status de conectividade alterado: OFFLINE
```

**Se ainda aparecer MissingPluginException:**
- Verifique se desinstalou o app completamente
- Tente limpar build cache do Android (`./gradlew clean`)
- Reinstale o app novamente

---

## ⚠️ Importante

**Nunca use hot restart/hot reload** quando adicionar novos plugins. Sempre reinstale completamente o app!
