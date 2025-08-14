import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';

import 'package:traccar_client/preferences.dart';
import 'package:traccar_client/password_service.dart';

class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  Stream<dynamic>? stream;
  Timer? _reconnectTimer;
  Timer? _sendTimer;
  bool _manuallyClosed = false;

  /// Start session login, open WS and begin sending locations
  Future<void> start() async {
    _manuallyClosed = false;
    await _connect();
    _startSendingLocation();
  }

  /// Stop sending and close WS gracefully
  Future<void> stop() async {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _sendTimer?.cancel();
    await _channel?.sink.close();
  }

  Future<String> _login() async {
    var baseUrl = Preferences.instance.getString(Preferences.url);
    final email = Preferences.instance.getString(Preferences.email);
    final password = await PasswordService.readPassword();
    if (baseUrl == null || email == null || password == null) {
      throw Exception('Missing server URL or credentials');
    }
    // Ensure HTTP(S) for login
    String httpBase = baseUrl.startsWith('ws')
        ? baseUrl.replaceFirst(RegExp(r'^ws'), 'http')
        : baseUrl;
    if (!httpBase.endsWith('/')) httpBase = '$httpBase/';
    final uri = Uri.parse('${httpBase}api/session');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'email=$email&password=$password',
    );
    if (response.statusCode == 204 || response.statusCode == 200) {
      final cookieHeader = response.headers['set-cookie'];
      final match = RegExp(r'JSESSIONID=([^;]+)').firstMatch(cookieHeader ?? '');
      if (match == null) throw Exception('JSESSIONID not found in response');
      return match.group(1)!;
    } else {
      throw Exception('Login failed [${response.statusCode}]');
    }
  }

  Future<void> _connect() async {
    final jsession = await _login();
    final serverUrl = Preferences.instance.getString(Preferences.url)!;
    final uri = Uri.parse(serverUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final wsBase = '$scheme://${uri.host}:${uri.port}';
    final wsUrl = '$wsBase/api/socket';
    _channel = IOWebSocketChannel.connect(
      wsUrl,
      headers: {'Cookie': 'JSESSIONID=$jsession'},
    );
    stream = _channel!.stream.asBroadcastStream();
    stream!.listen(
      (message) {
        // handle incoming messages if needed
        print('WS received: $message');
      },
      onDone: () {
        if (!_manuallyClosed) _scheduleReconnect();
      },
      onError: (_) {
        if (!_manuallyClosed) _scheduleReconnect();
      },
    );
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () => _connect());
  }

  void _startSendingLocation() {
    _sendTimer?.cancel();
    _sendTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_manuallyClosed) {
        timer.cancel();
        return;
      }
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final payload = jsonEncode({
          'deviceId': Preferences.instance.getString(Preferences.id),
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
        _channel?.sink.add(payload);
      } catch (e) {
        print('Error sending location: $e');
      }
    });
  }
  /// Send arbitrary payload over WebSocket
  void send(String message) {
    _channel?.sink.add(message);
  }
}