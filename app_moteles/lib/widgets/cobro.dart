import 'package:flutter/material.dart';
import '../screens/habitacion.dart';
import '../services/api_service.dart';
import '../services/printer_service.dart';
import '../screens/printer_page.dart';

class MostrarCobro {
  static void show(
    BuildContext context,
    Habitacion habitacion,
    VoidCallback actualizar,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CobroContenido(
          habitacion: habitacion,
          actualizar: actualizar,
        );
      },
    );
  }
}

class _CobroContenido extends StatefulWidget {
  final Habitacion habitacion;
  final VoidCallback actualizar;

  const _CobroContenido({
    required this.habitacion,
    required this.actualizar,
  });

  @override
  State<_CobroContenido> createState() => _CobroContenidoState();
}

class _CobroContenidoState extends State<_CobroContenido> {
  Map<String, dynamic>? preview;
  String? error;
  bool cobrando = false;

  final printerService = PrinterService.instance;

  @override
  void initState() {
    super.initState();
    cargarPreview();
  }

  Future<void> cargarPreview() async {
    try {
      final data = await ApiService.previewCobro(
        widget.habitacion.id,
      );

      setState(() {
        preview = data;
        error = null;
      });
    } on ApiException catch (e) {
      setState(() => error = e.message);
    }
  }

  Future<void> cobrar() async {
    // Si no hay impresora conectada, preguntamos antes de cobrar.
    // Una vez que se cobra, el cuarto se libera en el backend.
    if (!printerService.isConnected) {
      final continuar = await _mostrarDialogoSinImpresora();

      if (continuar != true) {
        return;
      }
    }

    setState(() => cobrando = true);

    try {
      final resultado = await ApiService.registrarSalida(
        widget.habitacion.id,
      );

      // Imprime solamente si hay impresora conectada.
      if (printerService.isConnected) {
        await _imprimirTicket(resultado);
      }

      if (mounted) {
        Navigator.pop(context);
      }

      widget.actualizar();
    } on ApiException catch (e) {
      setState(() => cobrando = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<bool?> _mostrarDialogoSinImpresora() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff252536),
        title: const Text(
          'Sin impresora conectada',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'No hay ninguna impresora Bluetooth conectada. '
          '¿Qué quieres hacer?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, false);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrinterPage(),
                ),
              );

              if (mounted) {
                setState(() {});
              }
            },
            child: const Text('Conectar impresora'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cobrar sin ticket'),
          ),
        ],
      ),
    );
  }

  Future<void> _imprimirTicket(
    Map<String, dynamic> resultado,
  ) async {
    final registro = resultado['registro'];
    final cuarto = registro['cuarto'];

    final motel =
        cuarto?['moteles']?['nombre'] ?? 'Motel';

    final total = double
        .parse(resultado['total'].toString())
        .toStringAsFixed(0);

    // IMPORTANTE:
    // Este valor viene directamente de Laravel.
    // No calculamos nuevamente la duración en Flutter.
    final minutosTranscurridos = int.parse(
      resultado['minutos_transcurridos'].toString(),
    );

    final ok = await printerService.imprimirTicket(
      motel: motel,
      numeroCuarto: widget.habitacion.numero,
      horaEntrada: formatearHora(
        registro['hora_entrada'],
      ),
      horaSalida: formatearHora(
        registro['hora_salida'],
      ),
      minutosTranscurridos: minutosTranscurridos,
      total: total,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se cobró, pero no se pudo imprimir el ticket.',
          ),
        ),
      );
    }
  }

  String formatearHora(String isoString) {
    final hora = DateTime.parse(isoString).toLocal();

    return "${hora.hour.toString().padLeft(2, '0')}:"
        "${hora.minute.toString().padLeft(2, '0')}";
  }

  String formatearTiempo(int minutos) {
    final h = (minutos ~/ 60).toString().padLeft(2, '0');
    final m = (minutos % 60).toString().padLeft(2, '0');

    return "$h:$m";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xff252536),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    if (preview == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    final registro = preview!['registro'];

    final minutos = int.parse(
      preview!['minutos_transcurridos'].toString(),
    );

    final total = preview!['total'];

    return Column(
      children: [
        Text(
          "Cobro - Cuarto #${widget.habitacion.numero}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 30),

        dato(
          "Hora de entrada",
          formatearHora(
            registro['hora_entrada'],
          ),
        ),

        const SizedBox(height: 15),

        dato(
          "Tiempo transcurrido",
          formatearTiempo(minutos),
        ),

        const SizedBox(height: 15),

        dato(
          "Total",
          "\$${double.parse(total.toString()).toStringAsFixed(0)}",
        ),

        const SizedBox(height: 15),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Impresora",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Row(
              children: [
                Icon(
                  printerService.isConnected
                      ? Icons.print
                      : Icons.print_disabled,
                  size: 16,
                  color: printerService.isConnected
                      ? Colors.greenAccent
                      : Colors.white38,
                ),
                const SizedBox(width: 6),
                Text(
                  printerService.isConnected
                      ? 'Conectada'
                      : 'No conectada',
                  style: TextStyle(
                    color: printerService.isConnected
                        ? Colors.greenAccent
                        : Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),

        const Spacer(),

        SizedBox(
          width: 300,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: cobrando ? null : cobrar,
            child: cobrando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "COBRAR",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget dato(
    String titulo,
    String valor,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}