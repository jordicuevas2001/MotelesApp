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

  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  StreamSubscription<Uint8List>? _inputSubscription;

  final List<BluetoothDevice> _devices = [];

  bool _scanning = false;
  bool _connected = false;

  BluetoothDevice? _connectedDevice;

  bool get isConnected =>
      _connected && (_connection?.isConnected ?? false);

  BluetoothDevice? get connectedDevice => _connectedDevice;

  List<BluetoothDevice> get devices =>
      List.unmodifiable(_devices);

  /// Inicializa Bluetooth y solicita los permisos necesarios.
  Future<void> initialize() async {
    try {
      await _requestBluetoothPermissions();

      final state = await _bluetooth.state;

      print('BLUETOOTH STATE: $state');

      if (!state.isEnabled) {
        print('Bluetooth está apagado.');
        return;
      }

      print('Bluetooth listo.');
    } catch (e) {
      print('ERROR INICIALIZANDO BLUETOOTH: $e');
    }
  }

  /// Solicita permisos Bluetooth según la versión de Android.
  Future<void> _requestBluetoothPermissions() async {
    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    final statuses = await permissions.request();

    for (final entry in statuses.entries) {
      print(
        'PERMISO ${entry.key}: ${entry.value}',
      );
    }
  }

  /// Busca dispositivos Bluetooth Classic.
  Future<List<BluetoothDevice>> scanPrinters({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_scanning) {
      return List.unmodifiable(_devices);
    }

    _scanning = true;
    _devices.clear();

    try {
      await _discoverySubscription?.cancel();

      final completer = Completer<void>();

      _discoverySubscription =
          _bluetooth.startDiscovery().listen(
        (result) {
          final device = result.device;

          final alreadyExists = _devices.any(
            (d) => d.address == device.address,
          );

          if (!alreadyExists) {
            _devices.add(device);

            print(
              'IMPRESORA ENCONTRADA: '
              '${device.name ?? "Sin nombre"} '
              '(${device.address})',
            );
          }
        },
        onError: (error) {
          print('ERROR DURANTE SCAN: $error');

          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          print('DESCUBRIMIENTO TERMINADO');

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      await Future.any([
        completer.future,
        Future.delayed(timeout),
      ]);

      await stopScan();

      print(
        'TOTAL DE DISPOSITIVOS: ${_devices.length}',
      );

      return List.unmodifiable(_devices);
    } catch (e) {
      print('ERROR BUSCANDO IMPRESORAS: $e');
      return [];
    } finally {
      _scanning = false;
    }
  }

  /// Detiene la búsqueda Bluetooth.
  Future<void> stopScan() async {
    try {
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;
    } catch (e) {
      print('ERROR DETENIENDO SCAN: $e');
    }

    _scanning = false;
  }

  /// Conecta con la impresora.
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await disconnect();

      print(
        'CONECTANDO A: '
        '${device.name ?? "Sin nombre"} '
        '${device.address}',
      );

      final connection =
          await BluetoothConnection.toAddress(
        device.address,
      );

      _connection = connection;
      _connectedDevice = device;
      _connected = true;

      _inputSubscription =
          connection.input?.listen(
        (data) {
          print(
            'DATOS RECIBIDOS: $data',
          );
        },
        onDone: () {
          print('IMPRESORA DESCONECTADA');

          _connected = false;
          _connectedDevice = null;
        },
        onError: (error) {
          print(
            'ERROR RECIBIENDO DATOS: $error',
          );
        },
      );

      print(
        'CONECTADO A: '
        '${device.name ?? "Sin nombre"}',
      );

      return true;
    } catch (e) {
      print(
        'ERROR CONECTANDO IMPRESORA: $e',
      );

      _connected = false;
      _connectedDevice = null;
      _connection = null;

      return false;
    }
  }

  /// Desconecta la impresora.
  Future<void> disconnect() async {
    try {
      await _inputSubscription?.cancel();
      _inputSubscription = null;

      if (_connection != null) {
        await _connection!.finish();
      }
    } catch (e) {
      print(
        'ERROR DESCONECTANDO IMPRESORA: $e',
      );
    } finally {
      _connection = null;
      _connectedDevice = null;
      _connected = false;
    }
  }

  /// Envía bytes directamente a la impresora.
  Future<bool> _sendBytes(List<int> bytes) async {
    if (!isConnected || _connection == null) {
      print('NO HAY IMPRESORA CONECTADA');
      return false;
    }

    try {
      final data = Uint8List.fromList(bytes);

      _connection!.output.add(data);

      await _connection!.output.allSent;

      return true;
    } catch (e) {
      print(
        'ERROR ENVIANDO DATOS: $e',
      );

      return false;
    }
  }

  /// Imprime el ticket de prueba.
  Future<bool> printTest() async {
    if (!isConnected) {
      print('NO HAY IMPRESORA CONECTADA');
      return false;
    }

    try {
      final profile =
          await CapabilityProfile.load();

      final generator = Generator(
        PaperSize.mm58,
        profile,
      );

      final List<int> bytes = [];

      bytes.addAll(
        generator.reset(),
      );

      bytes.addAll(
        generator.text(
          'Moteles App',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
          linesAfter: 1,
        ),
      );

      bytes.addAll(
        generator.text(
          'Prueba de impresion',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        ),
      );

      bytes.addAll(
        generator.text(
          'Impresora: '
          '${_connectedDevice?.name ?? "MP58C6"}',
          styles: const PosStyles(
            align: PosAlign.center,
          ),
        ),
      );

      bytes.addAll(
        generator.hr(),
      );

      bytes.addAll(
        generator.row([
          PosColumn(
            text: 'Cuarto 1',
            width: 8,
          ),
          PosColumn(
            text: '\$100.00',
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            ),
          ),
        ]),
      );

      bytes.addAll(
        generator.row([
          PosColumn(
            text: 'Producto 2',
            width: 8,
          ),
          PosColumn(
            text: '\$50.00',
            width: 4,
            styles: const PosStyles(
              align: PosAlign.right,
            ),
          ),
        ]),
      );

      bytes.addAll(
        generator.hr(),
      );

      bytes.addAll(
        generator.row([
          PosColumn(
            text: 'TOTAL',
            width: 7,
            styles: const PosStyles(
              bold: true,
            ),
          ),
          PosColumn(
            text: '\$150.00',
            width: 5,
            styles: const PosStyles(
              align: PosAlign.right,
              bold: true,
            ),
          ),
        ]),
      );

      bytes.addAll(
        generator.feed(3),
      );

      // Corte completo.
      bytes.addAll(
        generator.cut(),
      );

      final result =
          await _sendBytes(bytes);

      if (result) {
        print('IMPRESION TERMINADA');
      }

      return result;
    } catch (e) {
      print(
        'ERROR IMPRIMIENDO: $e',
      );

      return false;
    }
  }

  /// Imprime el ticket real de un cobro (entrada/salida/total).
  Future<bool> imprimirTicket({
    required String motel,
    required int numeroCuarto,
    required String horaEntrada,
    required String horaSalida,
    required String total,
  }) async {
    if (!isConnected) {
      print('NO HAY IMPRESORA CONECTADA');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      final List<int> bytes = [];

      bytes.addAll(generator.reset());

      bytes.addAll(
        generator.text(
          motel.toUpperCase(),
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
      );

      bytes.addAll(
        generator.text(
          'TICKET DE COBRO',
          styles: const PosStyles(align: PosAlign.center),
        ),
      );

      bytes.addAll(generator.hr());

      bytes.addAll(
        generator.row([
          PosColumn(text: 'Cuarto:', width: 5),
          PosColumn(
            text: '$numeroCuarto',
            width: 7,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );

      bytes.addAll(
        generator.row([
          PosColumn(text: 'Entrada:', width: 5),
          PosColumn(
            text: horaEntrada,
            width: 7,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );

      bytes.addAll(
        generator.row([
          PosColumn(text: 'Salida:', width: 5),
          PosColumn(
            text: horaSalida,
            width: 7,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );

      bytes.addAll(generator.hr());

      bytes.addAll(
        generator.text(
          'TOTAL: \$$total',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
          ),
        ),
      );

      bytes.addAll(generator.feed(1));

      bytes.addAll(
        generator.text(
          'Gracias por su visita',
          styles: const PosStyles(align: PosAlign.center),
        ),
      );

      bytes.addAll(generator.feed(3));
      bytes.addAll(generator.cut());

      final result = await _sendBytes(bytes);

      if (result) {
        print('TICKET IMPRESO');
      }

      return result;
    } catch (e) {
      print('ERROR IMPRIMIENDO TICKET: $e');
      return false;
    }
  }

  /// Imprime texto.
  Future<bool> printText(
    String text, {
    bool bold = false,
    PosAlign align = PosAlign.left,
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
        generator.text(
          text,
          styles: PosStyles(
            bold: bold,
            align: align,
          ),
        ),
      );

      return await _sendBytes(bytes);
    } catch (e) {
      print(
        'ERROR IMPRIMIENDO TEXTO: $e',
      );

      return false;
    }
  }

  /// Imprime un código QR.
  Future<bool> printQrCode(
    String data, {
    QRSize size = QRSize.size6,
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
        generator.qrcode(
          data,
          align: PosAlign.center,
          size: size,
          cor: QRCorrection.M,
        ),
      );

      bytes.addAll(
        generator.feed(2),
      );

      return await _sendBytes(bytes);
    } catch (e) {
      print(
        'ERROR IMPRIMIENDO QR: $e',
      );

      return false;
    }
  }

  /// Imprime un código de barras CODE128.
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

  /// Alimenta papel y corta.
  Future<bool> feedAndCut({
    int lines = 3,
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
        generator.feed(lines),
      );

      bytes.addAll(
        generator.cut(),
      );

      return await _sendBytes(bytes);
    } catch (e) {
      print(
        'ERROR ALIMENTANDO/CORTANDO: $e',
      );

      return false;
    }
  }

  /// Libera todos los recursos.
  Future<void> dispose() async {
    await stopScan();
    await disconnect();
  }
}