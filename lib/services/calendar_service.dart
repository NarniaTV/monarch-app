import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/objective_model.dart';
import '../core/utils/constants.dart';

/// Serviço para sincronização com Google Calendar
class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  // GoogleSignIn - usa configuração automática do google-services.json
  // Se necessário, pode especificar serverClientId explicitamente
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar'],
  );
  
  calendar.CalendarApi? _calendarApi;
  bool _isAuthenticated = false;
  
  // Cache do status de autenticação
  static const String _prefsKeyCalendarEnabled = 'calendar_enabled';
  static const String _prefsKeyCalendarEmail = 'calendar_email';

  /// Inicializa e autentica com Google Calendar
  Future<bool> initializeCalendar() async {
    try {
      final account = await _googleSignIn.signInSilently();
      
      if (account != null) {
        await _authenticateAndSetup(account);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Erro ao inicializar Calendar: $e');
      return false;
    }
  }

  /// Solicita autenticação explícita do usuário
  Future<bool> authenticate() async {
    try {
      // Tenta desconectar primeiro para limpar cache
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignora erros ao desconectar
      }
      
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        debugPrint('Usuário cancelou autenticação Google Calendar');
        return false; // Usuário cancelou
      }
      
      await _authenticateAndSetup(account);
      return true;
    } catch (e) {
      debugPrint('Erro ao autenticar no Google Calendar: $e');
      
      // Mensagem de erro mais específica
      if (e.toString().contains('ApiException: 10') || 
          e.toString().contains('DEVELOPER_ERROR') ||
          e.toString().contains('sign_in_failed')) {
        debugPrint('');
        debugPrint('═══════════════════════════════════════════════════');
        debugPrint('ERRO DE CONFIGURAÇÃO OAuth - Google Calendar');
        debugPrint('═══════════════════════════════════════════════════');
        debugPrint('Causa: SHA-1 fingerprint não configurado ou inválido');
        debugPrint('');
        debugPrint('SOLUÇÃO:');
        debugPrint('1. Execute no terminal:');
        debugPrint('   cd android && keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1');
        debugPrint('');
        debugPrint('2. Copie o SHA-1 (exemplo: A1:B2:C3:D4:E5:...)');
        debugPrint('');
        debugPrint('3. No Google Cloud Console:');
        debugPrint('   - APIs & Services → Credentials');
        debugPrint('   - Criar OAuth Client ID (Android)');
        debugPrint('   - Package name: com.example.monarch');
        debugPrint('   - SHA-1: COLE_O_SHA1_AQUI');
        debugPrint('');
        debugPrint('4. Aguardar 5-10 minutos para propagação');
        debugPrint('5. Rebuild do app: flutter clean && flutter run');
        debugPrint('═══════════════════════════════════════════════════');
        debugPrint('');
      }
      
      return false;
    }
  }

  /// Autentica e configura Calendar API
  Future<void> _authenticateAndSetup(GoogleSignInAccount account) async {
    try {
      final authHeaders = await account.authHeaders;
      debugPrint('[CALENDAR AUTH] Headers obtidos: ${authHeaders.keys.join(", ")}');
      debugPrint('[CALENDAR AUTH] Authorization header presente: ${authHeaders.containsKey("Authorization")}');
      
      final authenticatedClient = GoogleAuthClient(authHeaders);
      
      _calendarApi = calendar.CalendarApi(authenticatedClient);
      _isAuthenticated = true;
      
      // Salva status nas preferências
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyCalendarEnabled, true);
      await prefs.setString(_prefsKeyCalendarEmail, account.email);
      
      debugPrint('[CALENDAR AUTH] ✅ Autenticado no Google Calendar: ${account.email}');
      debugPrint('[CALENDAR AUTH] Calendar API configurado: ${_calendarApi != null}');
    } catch (e, stackTrace) {
      debugPrint('[CALENDAR AUTH] ❌ Erro ao configurar Calendar API: $e');
      debugPrint('[CALENDAR AUTH] Stack trace: $stackTrace');
      _isAuthenticated = false;
    }
  }

  /// Desconecta do Google Calendar
  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
      _calendarApi = null;
      _isAuthenticated = false;
      
      // Remove status das preferências
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyCalendarEnabled, false);
      await prefs.remove(_prefsKeyCalendarEmail);
      
      debugPrint('Desconectado do Google Calendar');
    } catch (e) {
      debugPrint('Erro ao desconectar do Google Calendar: $e');
    }
  }

  /// Verifica se está autenticado
  bool get isAuthenticated => _isAuthenticated;

  /// Verifica se calendar está habilitado (salvo nas preferências)
  Future<bool> isCalendarEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyCalendarEnabled) ?? false;
  }

  /// Obtém email do calendário
  Future<String?> getCalendarEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyCalendarEmail);
  }

  /// Cria evento no calendário para uma tarefa
  Future<String?> createCalendarEvent(TaskModel task) async {
    if (!_isAuthenticated || _calendarApi == null) {
      debugPrint('[CALENDAR] Calendar não autenticado');
      return null;
    }

    if (task.time == null) {
      debugPrint('[CALENDAR] Tarefa ${task.title} não tem horário, ignorando');
      return null; // Só cria evento se tiver horário
    }

    try {
      // Parse do horário
      final timeParts = task.time!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Data/hora do evento (createdAt já é a data agendada no nosso sistema)
      final eventDateTime = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
        hour,
        minute,
      );

      debugPrint('[CALENDAR] Criando evento para tarefa: ${task.title}');
      debugPrint('[CALENDAR] Data/hora do evento: $eventDateTime');
      debugPrint('[CALENDAR] Data/hora atual: ${DateTime.now()}');

      // REMOVIDO: Verificação de data passada
      // Agora cria eventos mesmo se a data já passou (útil para tarefas recorrentes e histórico)
      // Se a data já passou, cria evento de qualquer forma (o Google Calendar permite)

      final startDateTime = calendar.EventDateTime()
        ..dateTime = eventDateTime.toUtc()
        ..timeZone = 'America/Sao_Paulo';
      
      final endDateTime = calendar.EventDateTime()
        ..dateTime = eventDateTime.add(const Duration(hours: 1)).toUtc()
        ..timeZone = 'America/Sao_Paulo';

      final event = calendar.Event()
        ..summary = task.title
        ..description = task.description ?? ''
        ..start = startDateTime
        ..end = endDateTime;

      // Cores baseadas no rank
      final colorId = _getColorIdForTaskRank(task.rank);
      if (colorId != null) {
        event.colorId = colorId;
      }

      debugPrint('[CALENDAR] Inserindo evento no Google Calendar...');
      final createdEvent = await _calendarApi!.events.insert(event, 'primary');
      
      debugPrint('[CALENDAR] ✅ Evento criado com sucesso! ID: ${createdEvent.id}');
      debugPrint('[CALENDAR] Título: ${createdEvent.summary}');
      debugPrint('[CALENDAR] Início: ${createdEvent.start?.dateTime}');
      
      return createdEvent.id;
    } catch (e, stackTrace) {
      debugPrint('[CALENDAR] ❌ Erro ao criar evento no Calendar: $e');
      debugPrint('[CALENDAR] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Atualiza evento no calendário
  Future<bool> updateCalendarEvent(String eventId, TaskModel task) async {
    if (!_isAuthenticated || _calendarApi == null) {
      return false;
    }

    if (task.time == null) {
      // Se não tem mais horário, deleta o evento
      return await deleteCalendarEvent(eventId);
    }

    try {
      // Busca evento existente
      final existingEvent = await _calendarApi!.events.get('primary', eventId);

      // Parse do horário
      final timeParts = task.time!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Data/hora do evento
      final eventDateTime = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
        hour,
        minute,
      );

      final startDateTime = calendar.EventDateTime()
        ..dateTime = eventDateTime.toUtc()
        ..timeZone = 'America/Sao_Paulo';
      
      final endDateTime = calendar.EventDateTime()
        ..dateTime = eventDateTime.add(const Duration(hours: 1)).toUtc()
        ..timeZone = 'America/Sao_Paulo';

      existingEvent.summary = task.title;
      existingEvent.description = task.description ?? '';
      existingEvent.start = startDateTime;
      existingEvent.end = endDateTime;

      // Cores baseadas no rank
      final colorId = _getColorIdForTaskRank(task.rank);
      if (colorId != null) {
        existingEvent.colorId = colorId;
      }

      await _calendarApi!.events.update(existingEvent, 'primary', eventId);
      
      debugPrint('Evento atualizado no Calendar: $eventId');
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar evento no Calendar: $e');
      return false;
    }
  }

  /// Deleta evento do calendário
  Future<bool> deleteCalendarEvent(String eventId) async {
    if (!_isAuthenticated || _calendarApi == null) {
      debugPrint('[CALENDAR DELETE] Calendar não autenticado, abortando exclusão');
      return false;
    }

    try {
      debugPrint('[CALENDAR DELETE] Deletando evento do Google Calendar: $eventId');
      await _calendarApi!.events.delete('primary', eventId);
      debugPrint('[CALENDAR DELETE] ✅ Evento deletado com sucesso: $eventId');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[CALENDAR DELETE] ❌ Erro ao deletar evento do Calendar: $e');
      debugPrint('[CALENDAR DELETE] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Sincroniza tarefa completa (cria ou atualiza)
  Future<String?> syncTaskToCalendar(TaskModel task) async {
    if (!await isCalendarEnabled() || !_isAuthenticated) {
      return null;
    }

    // Se já tem calendarEventId, atualiza
    if (task.calendarEventId != null) {
      final updated = await updateCalendarEvent(task.calendarEventId!, task);
      return updated ? task.calendarEventId : null;
    }

    // Caso contrário, cria novo
    return await createCalendarEvent(task);
  }

  /// Sincroniza hábito no calendário (cria eventos recorrentes)
  /// Para hábitos, cria um evento recorrente baseado na frequência
  Future<String?> syncHabitToCalendar(ObjectiveModel habit) async {
    if (!await isCalendarEnabled() || !_isAuthenticated) {
      return null;
    }

    if (habit.rank != ObjectiveRank.b || habit.time == null) {
      return null; // Apenas hábitos (Rank B) com horário
    }

    try {
      // Parse do horário
      final timeParts = habit.time!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Data/hora base do evento
      final now = DateTime.now();
      final eventDateTime = DateTime(now.year, now.month, now.day, hour, minute);

      // Se já passou hoje, começa amanhã
      final startDateTime = eventDateTime.isBefore(now)
          ? eventDateTime.add(const Duration(days: 1))
          : eventDateTime;

      final startEventDateTime = calendar.EventDateTime()
        ..dateTime = startDateTime.toUtc()
        ..timeZone = 'America/Sao_Paulo';
      
      final endEventDateTime = calendar.EventDateTime()
        ..dateTime = startDateTime.add(const Duration(hours: 1)).toUtc()
        ..timeZone = 'America/Sao_Paulo';

      final event = calendar.Event()
        ..summary = 'Hábito: ${habit.title}'
        ..description = habit.description ?? ''
        ..start = startEventDateTime
        ..end = endEventDateTime;

      // Regra de recorrência baseada na frequência
      String rrule = '';
      switch (habit.frequencyType) {
        case FrequencyType.daily:
          rrule = 'RRULE:FREQ=DAILY';
          break;
        case FrequencyType.everyXDays:
          final days = habit.frequencyValue ?? 2;
          rrule = 'RRULE:FREQ=DAILY;INTERVAL=$days';
          break;
        case FrequencyType.weekly:
          if (habit.weekDays != null && habit.weekDays!.isNotEmpty) {
            // Converte dias da semana (1=Domingo, 2=Segunda, etc.) para formato iCal (SU, MO, etc.)
            final days = habit.weekDays!.map((d) => _convertWeekDayToICal(d)).join(',');
            rrule = 'RRULE:FREQ=WEEKLY;BYDAY=$days';
          }
          break;
        default:
          rrule = 'RRULE:FREQ=DAILY';
      }

      if (rrule.isNotEmpty) {
        event.recurrence = [rrule];
      }

      // Cor verde para hábitos
      event.colorId = '10'; // Verde

      final createdEvent = await _calendarApi!.events.insert(event, 'primary');
      
      debugPrint('Evento recorrente criado no Calendar: ${createdEvent.id}');
      return createdEvent.id;
    } catch (e) {
      debugPrint('Erro ao criar evento recorrente no Calendar: $e');
      return null;
    }
  }

  /// Converte dia da semana do formato do app (1=Domingo) para iCal (SU)
  String _convertWeekDayToICal(int weekDay) {
    const days = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
    return days[(weekDay - 1) % 7];
  }

  /// Obtém ID de cor baseado no rank da tarefa
  String? _getColorIdForTaskRank(TaskRank rank) {
    switch (rank) {
      case TaskRank.c:
        return '6'; // Laranja (importante)
      case TaskRank.d:
        return '5'; // Amarelo (normal)
      case TaskRank.e:
        return '4'; // Azul (casual)
      default:
        return '9'; // Azul (padrão)
    }
  }
}

/// Cliente HTTP autenticado para Google APIs
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // CRÍTICO: Adiciona headers de autenticação ao request
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
    return super.head(url, headers: {..._headers, ...?headers});
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return super.get(url, headers: {..._headers, ...?headers});
  }

  @override
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return super.post(url,
        headers: {..._headers, ...?headers},
        body: body,
        encoding: encoding);
  }

  @override
  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return super.put(url,
        headers: {..._headers, ...?headers},
        body: body,
        encoding: encoding);
  }

  @override
  Future<http.Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return super.patch(url,
        headers: {..._headers, ...?headers},
        body: body,
        encoding: encoding);
  }

  @override
  Future<http.Response> delete(Uri url, {Object? body, Encoding? encoding, Map<String, String>? headers}) {
    return super.delete(url, body: body, encoding: encoding, headers: {..._headers, ...?headers});
  }
}
