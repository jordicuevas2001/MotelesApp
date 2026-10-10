import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Backend Laravel.
///
/// Dispositivo físico:
/// Usa la IP de tu computadora dentro de la red local.
///
/// IMPORTANTE:
/// El celular y la computadora deben estar conectados
/// a la misma red Wi-Fi.
const String kBaseUrl = "http://192.168.1.189:8000/api";
//const String kBaseUrl = "http://10.0.2.2:8000/api";
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  // ============================================================
  // TOKEN / SESIÓN
  // ============================================================
  static Future<int?> obtenerMotelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('motel_id');
  }
  
  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  static Future<void> guardarSesion({
    required String token,
    required Map<String, dynamic> usuario,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);

    await prefs.setString(
      'usuario',
      jsonEncode(usuario),
    );

    await prefs.setString(
      'rol',
      usuario['rol']?.toString() ?? '',
    );

    if (usuario['motel_id'] != null) {
      final motelId = int.tryParse(
        usuario['motel_id'].toString(),
      );

      if (motelId != null) {
        await prefs.setInt(
          'motel_id',
          motelId,
        );
      }
    } else {
      await prefs.remove('motel_id');
    }
  }

  static Future<Map<String, dynamic>?> obtenerUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    final usuarioJson =
        prefs.getString('usuario');

    if (usuarioJson == null) {
      return null;
    }

    try {
      return jsonDecode(usuarioJson)
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> obtenerRol() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('rol');
  }

  static Future<bool> tieneSesion() async {
    final token = await obtenerToken();

    return token != null && token.isNotEmpty;
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('usuario');
    await prefs.remove('rol');
    await prefs.remove('motel_id');
  }

  // ============================================================
  // HEADERS
  // ============================================================

  static Future<Map<String, String>> _headers() async {
    final token = await obtenerToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',

      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // PROCESAR RESPUESTA
  // ============================================================

  static Future<dynamic> _procesar(
    http.Response response,
  ) async {
    dynamic body;

    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'El servidor devolvió una respuesta inválida.',
      );
    }

    // ----------------------------------------------------------
    // RESPUESTAS CORRECTAS
    // ----------------------------------------------------------

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return body['data'];
    }

    // ----------------------------------------------------------
    // NO AUTORIZADO
    // ----------------------------------------------------------

    if (response.statusCode == 401) {
      throw ApiException(
        'Sesión no válida o expirada. '
        'Inicia sesión nuevamente.',
      );
    }

    // ----------------------------------------------------------
    // VALIDACIÓN LARAVEL
    // ----------------------------------------------------------

    if (response.statusCode == 422) {
      final errores = body['errors'];

      if (errores is Map) {
        final mensajes = <String>[];

        errores.forEach((campo, mensajesCampo) {
          if (mensajesCampo is List) {
            mensajes.addAll(
              mensajesCampo.map(
                (e) => e.toString(),
              ),
            );
          }
        });

        if (mensajes.isNotEmpty) {
          throw ApiException(
            mensajes.join('\n'),
          );
        }
      }
    }

    // ----------------------------------------------------------
    // ERROR GENERAL
    // ----------------------------------------------------------

    throw ApiException(
      body['message']?.toString() ??
          'Error desconocido del servidor.',
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = await _procesar(res);

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'La respuesta del login no tiene un formato válido.',
      );
    }

    final token = data['token'];
    final usuario = data['usuario'];

    if (token == null || usuario is! Map<String, dynamic>) {
      throw ApiException(
        'La respuesta del login está incompleta.',
      );
    }

    await guardarSesion(
      token: token.toString(),
      usuario: usuario,
    );

    return data;
  }

  // ============================================================
  // TARIFAS
  // ============================================================

  static Future<Map<String, dynamic>> obtenerTarifas(
    int motelId,
  ) async {
    final res = await http.get(
      Uri.parse(
        '$kBaseUrl/moteles/$motelId/tarifas',
      ),
      headers: await _headers(),
    );

    final data = await _procesar(res);

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'La respuesta de tarifas no tiene un formato válido.',
      );
    }

    return data;
  }

  // ============================================================
  // HISTORIAL
  // ============================================================

  static Future<List<dynamic>> obtenerHistorial({
    int? motelId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final params = <String, String>{};

    if (motelId != null) {
      params['motel_id'] =
          motelId.toString();
    }

    if (fechaInicio != null) {
      params['fecha_inicio'] =
          fechaInicio;
    }

    if (fechaFin != null) {
      params['fecha_fin'] =
          fechaFin;
    }

    final uri = Uri.parse(
      '$kBaseUrl/historial',
    ).replace(
      queryParameters:
          params.isEmpty
              ? null
              : params,
    );

    final res = await http.get(
      uri,
      headers: await _headers(),
    );

    final data = await _procesar(res);

    if (data is Map<String, dynamic>) {
      final registros = data['data'];

      if (registros is List) {
        return registros;
      }
    }

    if (data is List) {
      return data;
    }

    return [];
  }

  // ============================================================
  // RESUMEN
  // ============================================================

  static Future<Map<String, dynamic>> obtenerResumen({
    int? motelId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final params = <String, String>{};

    if (motelId != null) {
      params['motel_id'] =
          motelId.toString();
    }

    if (fechaInicio != null) {
      params['fecha_inicio'] =
          fechaInicio;
    }

    if (fechaFin != null) {
      params['fecha_fin'] =
          fechaFin;
    }

    final uri = Uri.parse(
      '$kBaseUrl/resumen',
    ).replace(
      queryParameters:
          params.isEmpty
              ? null
              : params,
    );

    final res = await http.get(
      uri,
      headers: await _headers(),
    );

    final data = await _procesar(res);

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'La respuesta del resumen no tiene un formato válido.',
      );
    }

    return data;
  }

  // ============================================================
  // REPORTE DETALLADO PARA PDF
  // ============================================================

  static Future<Map<String, dynamic>>
      obtenerReporteDetallado({
    int? motelId,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    final params = <String, String>{
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
    };

    if (motelId != null) {
      params['motel_id'] =
          motelId.toString();
    }

    final uri = Uri.parse(
      '$kBaseUrl/reporte-detallado',
    ).replace(
      queryParameters: params,
    );

    final res = await http.get(
      uri,
      headers: await _headers(),
    );

    final data = await _procesar(res);

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'La respuesta del reporte detallado '
        'no tiene un formato válido.',
      );
    }

    return data;
  }

  // ============================================================
  // CUARTOS
  // ============================================================

  static Future<List<dynamic>> obtenerCuartos() async {
    final res = await http.get(
      Uri.parse(
        '$kBaseUrl/cuartos',
      ),
      headers: await _headers(),
    );

    final data = await _procesar(res);

    if (data is! List) {
      throw ApiException(
        'La respuesta de cuartos no tiene un formato válido.',
      );
    }

    return data;
  }

  // ============================================================
  // ENTRADA
  // ============================================================

  static Future<Map<String, dynamic>>
      registrarEntrada(
    int cuartoId,
  ) async {
    final res = await http.post(
      Uri.parse(
        '$kBaseUrl/cuartos/$cuartoId/entrada',
      ),
      headers: await _headers(),
    );

    final data = await _procesar(res);

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'La respuesta de entrada no tiene un formato válido.',
      );
    }

    return data;
  }

  // ============================================================
  // COBRO
  // ============================================================

  static Future<Map<String, dynamic>>
      previewCobro(
    int cuartoId,
  ) async {
    final res = await http.get(
      Uri.parse(
        '$kBaseUrl/cuartos/$cuartoId/cobro',
      ),
      headers: await _headers(),
    );

    final data = await _procesar(res);

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'La respuesta del cobro no tiene un formato válido.',
      );
    }

    return data;
  }

  // ============================================================
  // SALIDA
  // ============================================================

  static Future<Map<String, dynamic>>
      registrarSalida(
    int cuartoId, {
    String? observaciones,
  }) async {
    final res = await http.post(
      Uri.parse(
        '$kBaseUrl/cuartos/$cuartoId/salida',
      ),
      headers: await _headers(),
      body: jsonEncode({
        'observaciones': observaciones,
      }),
    );

    final data = await _procesar(res);

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'La respuesta de salida no tiene un formato válido.',
      );
    }

    return data;
  }
}