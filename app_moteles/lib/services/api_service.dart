import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cambia esto según dónde corras el backend:
/// - Emulador Android: 10.0.2.2 en vez de 127.0.0.1
/// - Dispositivo físico: la IP de tu compu en la red local (ej. 192.168.1.50)
/// - Chrome/desktop: 127.0.0.1 funciona directo
const String kBaseUrl = "http://10.0.2.2:8000/api";
//const String kBaseUrl = "http://192.168.1.145:8000/api";

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static Future<dynamic> _procesar(http.Response response) async {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body['data'];
    }

    throw ApiException(body['message'] ?? 'Error desconocido del servidor');
  }

  static Future<Map<String, dynamic>> obtenerTarifas(int motelId) async {
    final res = await http.get(Uri.parse('$kBaseUrl/moteles/$motelId/tarifas'));
    final data = await _procesar(res);
    return data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> obtenerHistorial() async {
    final res = await http.get(Uri.parse('$kBaseUrl/historial'));
    final data = await _procesar(res);
    // Laravel pagina la respuesta: la lista real viene dentro de data['data']
    return data['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> obtenerHistorialDiario() async {
    final res = await http.get(Uri.parse('$kBaseUrl/historial/diario'));
    final data = await _procesar(res);
    return data as List<dynamic>;
  }

  static Future<List<dynamic>> obtenerDetalleDia(String fecha) async {
    final res = await http.get(Uri.parse('$kBaseUrl/historial/diario/$fecha'));
    final data = await _procesar(res);
    return data as List<dynamic>;
  }

  static Future<List<dynamic>> obtenerCuartos() async {
    final res = await http.get(Uri.parse('$kBaseUrl/cuartos'));
    final data = await _procesar(res);
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> registrarEntrada(int cuartoId) async {
    final res = await http.post(Uri.parse('$kBaseUrl/cuartos/$cuartoId/entrada'));
    final data = await _procesar(res);
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> previewCobro(int cuartoId) async {
    final res = await http.get(Uri.parse('$kBaseUrl/cuartos/$cuartoId/cobro'));
    final data = await _procesar(res);
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> registrarSalida(
    int cuartoId, {
    String? observaciones,
  }) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/cuartos/$cuartoId/salida'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'observaciones': observaciones}),
    );
    final data = await _procesar(res);
    return data as Map<String, dynamic>;
  }
}