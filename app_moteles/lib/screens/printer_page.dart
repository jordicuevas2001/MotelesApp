import 'package:app_moteles/services/printer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final printerService = PrinterService.instance;

  List<BluetoothDevice> printers = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    printerService.initialize();
  }

  Future<void> buscarImpresoras() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      printers = [];
    });

    try {
      final devices =
          await printerService.scanPrinters();

      if (!mounted) return;

      setState(() {
        printers = devices;
      });

      print(
        'TOTAL ENCONTRADAS: ${printers.length}',
      );
    } catch (e) {
      print(
        'ERROR BUSCANDO IMPRESORAS: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> conectar(
    BluetoothDevice device,
  ) async {
    final connected =
        await printerService.connect(device);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          connected
              ? 'Conectado a ${device.name ?? device.address}'
              : 'No se pudo conectar',
        ),
      ),
    );

    setState(() {});
  }

  Future<void> imprimir() async {
    final result =
        await printerService.printTest();

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
    printerService.stopScan();
    super.dispose();
  }

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
                : const Icon(Icons.search),
            label: Text(
              _loading
                  ? 'Buscando...'
                  : 'Buscar impresoras',
            ),
          ),

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
                    onPressed: () async {
                      await printerService
                          .disconnect();

                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
            ),

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

                      return ListTile(
                        leading: const Icon(
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
                            ElevatedButton(
                          onPressed: () =>
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