import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vs_pusher_channels_flutter/vs_pusher_channels_flutter.dart';
import 'api_service.dart';

class ReverbService {
  ReverbService._();

  static final ReverbService instance = ReverbService._();

  final PusherChannelsFlutter _pusher =
      PusherChannelsFlutter.getInstance();

  String? _canalActual;
  bool _inicializado = false;

  Future<void> conectar({
    required int motelId,
    required Function(Map<String, dynamic>) onCuartoActualizado,
  }) async {
    try {
      final token = await ApiService.obtenerToken();

      if (token == null || token.isEmpty) {
        print('REVERB: No hay token.');
        return;
      }

      final canal = 'private-moteles.$motelId';

      _canalActual = canal;

      if (!_inicializado) {
        await _pusher.init(
          apiKey: 'xklssje1nq73slipi0nf',

          // REVERB LOCAL
          host: '192.168.1.189',
          wsPort: 8080,
          wssPort: 8080,

          useTLS: false,

          onAuthorizer: (
            String channelName,
            String socketId,
            dynamic options,
          ) async {
            try {
              final response = await http.post(
                Uri.parse(
                  'http://192.168.1.189:8000/api/broadcasting/auth',
                ),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                  'socket_id': socketId,
                  'channel_name': channelName,
                }),
              );

              print(
                'REVERB AUTH STATUS: ${response.statusCode}',
              );

              print(
                'REVERB AUTH DATA: ${response.body}',
              );

              if (response.statusCode != 200) {
                throw Exception(
                  'Error autenticando canal privado: '
                  '${response.statusCode}',
                );
              }

              final data = jsonDecode(response.body);

              return data;
            } catch (e) {
              print('REVERB ERROR AUTH: $e');
              rethrow;
            }
          },

          onConnectionStateChange: (
            currentState,
            previousState,
          ) {
            print(
              'REVERB CONEXIÓN: '
              '$previousState → $currentState',
            );
          },

          onError: (
            message,
            code,
            error,
          ) {
            print(
              'REVERB ERROR: '
              '$message '
              'Código: $code '
              'Error: $error',
            );
          },

          onSubscriptionSucceeded: (
            channelName,
            data,
          ) {
            print(
              'REVERB SUSCRIPCIÓN OK: '
              '$channelName',
            );
          },

          onSubscriptionError: (
            message,
            error,
          ) {
            print(
              'REVERB ERROR SUSCRIPCIÓN: '
              '$message '
              '$error',
            );
          },
        );

        _inicializado = true;
      }

      await _pusher.subscribe(
  channelName: canal,
  onEvent: (event) {
    try {
      final PusherEvent pusherEvent = event as PusherEvent;

      print(
        'REVERB EVENTO: '
        '${pusherEvent.eventName}',
      );

      print(
        'REVERB DATA: '
        '${pusherEvent.data}',
      );

      if (pusherEvent.eventName == 'cuarto.actualizado') {
        dynamic decoded = jsonDecode(pusherEvent.data);

        if (decoded is Map<String, dynamic>) {
          onCuartoActualizado(decoded);
        }
      }
    } catch (e) {
      print(
        'REVERB ERROR EVENTO: $e',
      );
    }
  },
);

      await _pusher.connect();

      print(
        'REVERB CONECTADO AL MOTEL: $motelId',
      );
    } catch (e) {
      print(
        'REVERB ERROR AL CONECTAR: $e',
      );
    }
  }

  Future<void> desconectar() async {
    try {
      if (_canalActual != null) {
        await _pusher.unsubscribe(
          channelName: _canalActual!,
        );

        _canalActual = null;
      }

      await _pusher.disconnect();

      _inicializado = false;

      print(
        'REVERB DESCONECTADO',
      );
    } catch (e) {
      print(
        'REVERB ERROR AL DESCONECTAR: $e',
      );
    }
  }
}