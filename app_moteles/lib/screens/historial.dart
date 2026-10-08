import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/printer_service.dart';
import '../screens/printer_page.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<dynamic> registros = [];
  bool cargando = true;
  String? error;

  int? imprimiendoId;

  final PrinterService printerService = PrinterService.instance;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final data = await ApiService.obtenerHistorial();

      setState(() {
        registros = data;
        cargando = false;
      });
    } on ApiException catch (e) {
      setState(() {
        error = e.message;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error al cargar el historial: $e';
        cargando = false;
      });
    }
  }

  String formatearFechaHora(String iso) {
    final f = DateTime.parse(iso).toLocal();

    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final horaStr = f.hour == 0
        ? 12
        : (f.hour > 12 ? f.hour - 12 : f.hour);

    final ampm = f.hour >= 12 ? 'p.m.' : 'a.m.';

    return "${f.day} ${meses[f.month - 1]} ${f.year} "
        "${horaStr.toString().padLeft(2, '0')}:"
        "${f.minute.toString().padLeft(2, '0')}:"
        "${f.second.toString().padLeft(2, '0')} $ampm";
  }

  String formatearHora(String iso) {
    final f = DateTime.parse(iso).toLocal();

    final hora = f.hour == 0
        ? 12
        : (f.hour > 12 ? f.hour - 12 : f.hour);

    final ampm = f.hour >= 12 ? 'p.m.' : 'a.m.';

    return '${hora.toString().padLeft(2, '0')}:'
        '${f.minute.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> reimprimirTicket(Map<String, dynamic> r) async {
    final id = int.parse(r['id'].toString());

    if (imprimiendoId != null) {
      return;
    }

    setState(() {
      imprimiendoId = id;
    });

    try {
      // ------------------------------------------------------------
      // 1. Verificar conexión con la impresora
      // ------------------------------------------------------------
      if (!printerService.isConnected) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PrinterPage(),
          ),
        );

        // El usuario regresó de PrinterPage.
        // Verificamos nuevamente.
        if (!printerService.isConnected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No hay una impresora conectada.',
                ),
              ),
            );
          }

          return;
        }
      }

      // ------------------------------------------------------------
      // 2. Obtener datos del registro
      // ------------------------------------------------------------
      final cuarto = r['cuarto'] as Map<String, dynamic>?;

      final motel =
          cuarto?['moteles']?['nombre']?.toString() ?? 'Motel';

      final numeroCuarto =
          int.parse(cuarto?['numero'].toString() ?? '0');

      // IMPORTANTE:
      // Este valor viene directamente de Laravel.
      // NO calculamos la duración nuevamente en Flutter.
      final minutosTranscurridos =
          int.parse(r['minutos_transcurridos'].toString());

      final total =
          double.parse(r['total'].toString()).toStringAsFixed(0);

      final horaEntrada =
          formatearHora(r['hora_entrada'].toString());

      final horaSalida =
          formatearHora(r['hora_salida'].toString());

      // ------------------------------------------------------------
      // 3. Imprimir
      // ------------------------------------------------------------
      final ok = await printerService.imprimirTicket(
        motel: motel,
        numeroCuarto: numeroCuarto,
        horaEntrada: horaEntrada,
        horaSalida: horaSalida,
        minutosTranscurridos: minutosTranscurridos,
        total: total,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket reimpreso correctamente.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo imprimir el ticket.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al imprimir: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          imprimiendoId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1c1c2e),
      appBar: AppBar(
        backgroundColor: const Color(0xff252536),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Historial de Cobros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargar,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (registros.isEmpty) {
      return const Center(
        child: Text(
          'Todavía no hay cobros registrados.',
          style: TextStyle(
            color: Colors.white54,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: registros.length,
      separatorBuilder: (_, __) => const Divider(
        color: Colors.white12,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final r = registros[index];

        final cuarto =
            r['cuarto'] as Map<String, dynamic>?;

        final motel =
            cuarto?['moteles']?['nombre']?.toString() ?? 'Motel';

        final numeroCuarto =
            cuarto?['numero']?.toString() ?? '?';

        final total =
            double.parse(r['total'].toString())
                .toStringAsFixed(0);

        final id =
            int.parse(r['id'].toString());

        final estaImprimiendo =
            imprimiendoId == id;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            "Cuarto $numeroCuarto - $motel",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "${formatearFechaHora(r['hora_entrada'])}  -->  "
              "${formatearFechaHora(r['hora_salida'])}",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "\$ $total",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),

              if (estaImprimiendo)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.print,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    reimprimirTicket(
                      Map<String, dynamic>.from(r),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}