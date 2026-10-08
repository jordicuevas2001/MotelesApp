import 'dart:async';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterService {
  PrinterService._();

  static final PrinterService instance = PrinterService._();

  final FlutterBluetoothSerial _bluetooth =
      FlutterBluetoothSerial.instance;

  BluetoothConnection? _connection;

  StreamSubscription<BluetoothDiscoveryResult>?
      _discoverySubscription;

  StreamSubscription<Uint8List>? _inputSubscription;

  final List<BluetoothDevice> _devices = [];

  bool _scanning = false;
  bool _connected = false;

  BluetoothDevice? _connectedDevice;

  bool get isConnected =>
      _connected &&
      (_connection?.isConnected ?? false);

  BluetoothDevice? get connectedDevice => _connectedDevice;

  List<BluetoothDevice> get devices =>
      List.unmodifiable(_devices);

  // ============================================================
  // CONVERTIR TEXTO PARA IMPRESORA TÉRMICA
  // ============================================================

  String textoParaImpresora(String texto) {
    return texto
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('ñ', 'n')
        .replaceAll('Ñ', 'N')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U');
  }

  // ============================================================
  // BLUETOOTH
  // ============================================================

  Future<bool> inicializarBluetooth() async {
    try {
      final permisos = await solicitarPermisos();

      if (!permisos) {
        return false;
      }

      final estado = await _bluetooth.isEnabled;

      if (estado != true) {
        await _bluetooth.requestEnable();
      }

      return true;
    } catch (e) {
      print('ERROR INICIALIZANDO BLUETOOTH: $e');
      return false;
    }
  }

  Future<bool> solicitarPermisos() async {
    try {
      if (await Permission.bluetooth.isDenied) {
        await Permission.bluetooth.request();
      }

      if (await Permission.bluetoothScan.isDenied) {
        await Permission.bluetoothScan.request();
      }

      if (await Permission.bluetoothConnect.isDenied) {
        await Permission.bluetoothConnect.request();
      }

      if (await Permission.location.isDenied) {
        await Permission.location.request();
      }

      final bluetooth = await Permission.bluetooth.status;
      final scan = await Permission.bluetoothScan.status;
      final connect =
          await Permission.bluetoothConnect.status;

      return bluetooth.isGranted &&
          scan.isGranted &&
          connect.isGranted;
    } catch (e) {
      print('ERROR PERMISOS BLUETOOTH: $e');
      return false;
    }
  }

  // ============================================================
  // ESCANEAR DISPOSITIVOS
  // ============================================================

  Future<void> iniciarEscaneo() async {
    if (_scanning) {
      return;
    }

    try {
      _scanning = true;
      _devices.clear();

      await solicitarPermisos();

      _discoverySubscription?.cancel();

      _discoverySubscription =
          _bluetooth.startDiscovery().listen(
        (result) {
          final device = result.device;

          final existe = _devices.any(
            (d) => d.address == device.address,
          );

          if (!existe) {
            _devices.add(device);
          }
        },
        onDone: () {
          _scanning = false;
        },
        onError: (e) {
          print('ERROR ESCANEANDO BLUETOOTH: $e');
          _scanning = false;
        },
      );
    } catch (e) {
      print('ERROR INICIANDO ESCANEO: $e');
      _scanning = false;
    }
  }

  Future<void> detenerEscaneo() async {
    try {
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;

      _scanning = false;
    } catch (e) {
      print('ERROR DETENIENDO ESCANEO: $e');
    }
  }

  // ============================================================
  // CONECTAR
  // ============================================================

  Future<bool> conectar(BluetoothDevice device) async {
    try {
      await desconectar();

      print(
        'CONECTANDO A: ${device.name} ${device.address}',
      );

      final connection =
          await BluetoothConnection.toAddress(
        device.address,
      );

      _connection = connection;
      _connectedDevice = device;
      _connected = true;

      _inputSubscription?.cancel();

      _inputSubscription =
          connection.input?.listen(
        (data) {
          print(
            'DATOS RECIBIDOS: $data',
          );
        },
        onDone: () {
          print('CONEXIÓN BLUETOOTH CERRADA');

          _connected = false;
          _connection = null;
          _connectedDevice = null;
        },
        onError: (e) {
          print(
            'ERROR EN INPUT BLUETOOTH: $e',
          );
        },
      );

      print('IMPRESORA CONECTADA');

      return true;
    } catch (e) {
      print(
        'ERROR CONECTANDO IMPRESORA: $e',
      );

      _connected = false;
      _connection = null;
      _connectedDevice = null;

      return false;
    }
  }

  // ============================================================
  // DESCONECTAR
  // ============================================================

  Future<void> desconectar() async {
    try {
      await _inputSubscription?.cancel();
      _inputSubscription = null;

      await _connection?.finish();

      _connection = null;
      _connected = false;
      _connectedDevice = null;
    } catch (e) {
      print(
        'ERROR DESCONECTANDO IMPRESORA: $e',
      );

      _connection = null;
      _connected = false;
      _connectedDevice = null;
    }
  }

  // ============================================================
  // ENVIAR BYTES
  // ============================================================

  Future<bool> _sendBytes(List<int> bytes) async {
    if (!isConnected) {
      print(
        'NO HAY IMPRESORA CONECTADA',
      );

      return false;
    }

    try {
      _connection!.output.add(
        Uint8List.fromList(bytes),
      );

      await _connection!.output.allSent;

      return true;
    } catch (e) {
      print(
        'ERROR ENVIANDO BYTES: $e',
      );

      return false;
    }
  }

  // ============================================================
  // IMPRIMIR TICKET
  // ============================================================

  Future<bool> imprimirTicket({
    required String motel,
    required int numeroCuarto,
    required String horaEntrada,
    required String horaSalida,
    required int minutosTranscurridos,
    required String total,
  }) async {
    if (!isConnected) {
      return false;
    }

    try {
      final profile =
          await CapabilityProfile.load();

      final generator = Generator(
        PaperSize.mm58,
        profile,
      );

      final bytes = <int>[];

      // --------------------------------------------------------
      // MOTEL
      // --------------------------------------------------------

      final motelImpresora =
          textoParaImpresora(
        motel.toUpperCase(),
      );

      bytes.addAll(
        generator.text(
          motelImpresora,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
      );

      bytes.addAll(
        generator.feed(1),
      );

      // --------------------------------------------------------
      // TITULO
      // --------------------------------------------------------

      bytes.addAll(
        generator.text(
          'TICKET DE COBRO',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        ),
      );

      bytes.addAll(
        generator.feed(1),
      );

      // --------------------------------------------------------
      // CUARTO
      // --------------------------------------------------------

      bytes.addAll(
        generator.text(
          'Cuarto: $numeroCuarto',
          styles: const PosStyles(
            align: PosAlign.left,
          ),
        ),
      );

      // --------------------------------------------------------
      // ENTRADA
      // --------------------------------------------------------

      bytes.addAll(
        generator.text(
          'Entrada: $horaEntrada',
          styles: const PosStyles(
            align: PosAlign.left,
          ),
        ),
      );

      // --------------------------------------------------------
      // SALIDA
      // --------------------------------------------------------

      bytes.addAll(
        generator.text(
          'Salida: $horaSalida',
          styles: const PosStyles(
            align: PosAlign.left,
          ),
        ),
      );

      // --------------------------------------------------------
      // TIEMPO
      // --------------------------------------------------------

      final horas =
          minutosTranscurridos ~/ 60;

      final minutos =
          minutosTranscurridos % 60;

      final tiempoFormateado =
          '${horas.toString().padLeft(2, '0')}h '
          '${minutos.toString().padLeft(2, '0')}min';

      bytes.addAll(
        generator.text(
          'Tiempo: $tiempoFormateado',
          styles: const PosStyles(
            align: PosAlign.left,
          ),
        ),
      );

      bytes.addAll(
        generator.feed(1),
      );

      // --------------------------------------------------------
      // TOTAL
      // --------------------------------------------------------

      bytes.addAll(
        generator.text(
          'TOTAL: \$$total',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
      );

      bytes.addAll(
        generator.feed(1),
      );

      // --------------------------------------------------------
      // DESPEDIDA
      // --------------------------------------------------------

      bytes.addAll(
        generator.text(
          'Gracias por su visita',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        ),
      );

      bytes.addAll(
        generator.feed(3),
      );

      // --------------------------------------------------------
      // CORTE
      // --------------------------------------------------------

      bytes.addAll(
        generator.cut(),
      );

      return await _sendBytes(bytes);
    } catch (e) {
      print(
        'ERROR IMPRIMIENDO TICKET: $e',
      );

      return false;
    }
  }

  // ============================================================
  // IMPRIMIR BARCODE
  // ============================================================

  Future<bool> printBarcode(
    String data, {
    int width = 2,
    int height = 80,
  }) async {
    if (!isConnected) {
      return false;
    }

    try {
      final profile =
          await CapabilityProfile.load();

      final generator = Generator(
        PaperSize.mm58,
        profile,
      );

      final bytes = <int>[];

      bytes.addAll(
        generator.barcode(
          Barcode.code128(
            data as List<dynamic>,
          ),
          width: width,
          height: height,
          align: PosAlign.center,
        ),
      );

      bytes.addAll(
        generator.feed(2),
      );

      return await _sendBytes(bytes);
    } catch (e) {
      print(
        'ERROR IMPRIMIENDO BARCODE: $e',
      );

      return false;
    }
  }
}