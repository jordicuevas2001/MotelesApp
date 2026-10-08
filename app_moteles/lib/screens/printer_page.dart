import 'package:app_moteles/services/printer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final PrinterService printerService =
      PrinterService.instance;

  List<BluetoothDevice> printers = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    inicializar();
  }

  // ============================================================
  // INICIALIZAR BLUETOOTH
  // ============================================================

  Future<void> inicializar() async {
    final resultado =
        await printerService.inicializarBluetooth();

    if (!resultado) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo inicializar Bluetooth '
            'o faltan permisos.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUSCAR IMPRESORAS
  // ============================================================

  Future<void> buscarImpresoras() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      printers = [];
    });

    try {
      await printerService.iniciarEscaneo();

      // Esperamos un poco para permitir que
      // aparezcan los dispositivos encontrados.
      await Future.delayed(
        const Duration(seconds: 5),
      );

      await printerService.detenerEscaneo();

      if (!mounted) return;

      setState(() {
        printers = printerService.devices;
      });

      print(
        'TOTAL ENCONTRADAS: ${printers.length}',
      );
    } catch (e) {
      print(
        'ERROR BUSCANDO IMPRESORAS: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error buscando impresoras: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // CONECTAR
  // ============================================================

  Future<void> conectar(
    BluetoothDevice device,
  ) async {
    final connected =
        await printerService.conectar(device);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          connected
              ? 'Conectado a '
                  '${device.name ?? device.address}'
              : 'No se pudo conectar',
        ),
      ),
    );

    setState(() {});
  }

  // ============================================================
  // DESCONECTAR
  // ============================================================

  Future<void> desconectar() async {
    await printerService.desconectar();

    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // IMPRIMIR PRUEBA
  // ============================================================

  Future<void> imprimir() async {
    if (!printerService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay una impresora conectada.',
          ),
        ),
      );

      return;
    }

    final result =
        await printerService.imprimirTicket(
      motel: 'PRUEBA',
      numeroCuarto: 1,
      horaEntrada: '12:00 p.m.',
      horaSalida: '02:35 p.m.',
      minutosTranscurridos: 155,
      total: '100',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result
              ? 'Impresión enviada'
              : 'Error de impresión',
        ),
      ),
    );
  }

  @override
  void dispose() {
    printerService.detenerEscaneo();
    super.dispose();
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final connected =
        printerService.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Impresora Bluetooth',
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // ----------------------------------------------------
          // BOTÓN BUSCAR
          // ----------------------------------------------------

          ElevatedButton.icon(
            onPressed:
                _loading ? null : buscarImpresoras,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.search,
                  ),
            label: Text(
              _loading
                  ? 'Buscando...'
                  : 'Buscar impresoras',
            ),
          ),

          // ----------------------------------------------------
          // IMPRESORA CONECTADA
          // ----------------------------------------------------

          if (connected)
            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.print,
                  ),
                  title: Text(
                    printerService
                            .connectedDevice
                            ?.name ??
                        'Impresora conectada',
                  ),
                  subtitle: Text(
                    printerService
                            .connectedDevice
                            ?.address ??
                        '',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.link_off,
                    ),
                    onPressed:
                        desconectar,
                  ),
                ),
              ),
            ),

          // ----------------------------------------------------
          // LISTA DE IMPRESORAS
          // ----------------------------------------------------

          Expanded(
            child: printers.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron '
                      'dispositivos.',
                    ),
                  )
                : ListView.builder(
                    itemCount:
                        printers.length,
                    itemBuilder:
                        (context, index) {
                      final device =
                          printers[index];

                      final yaConectada =
                          printerService
                                  .connectedDevice
                                  ?.address ==
                              device.address;

                      return ListTile(
                        leading:
                            const Icon(
                          Icons.bluetooth,
                        ),
                        title: Text(
                          device.name ??
                              'Sin nombre',
                        ),
                        subtitle: Text(
                          device.address,
                        ),
                        trailing:
                            yaConectada
                                ? const Text(
                                    'Conectada',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed:
                                        () =>
                                            conectar(
                                      device,
                                    ),
                                    child:
                                        const Text(
                                      'Conectar',
                                    ),
                                  ),
                      );
                    },
                  ),
          ),

          // ----------------------------------------------------
          // IMPRIMIR PRUEBA
          // ----------------------------------------------------

          Padding(
            padding:
                const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    connected
                        ? imprimir
                        : null,
                icon: const Icon(
                  Icons.print,
                ),
                label: const Text(
                  'IMPRIMIR PRUEBA',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}