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
  bool operacionTurno = false;

  String? error;
  String? errorTurno;

  Map<String, dynamic>? turno;

  int? imprimiendoId;

  final PrinterService printerService = PrinterService.instance;

  bool get turnoAbierto =>
      turno != null &&
      turno!['estado']?.toString() == 'abierto';

  @override
  void initState() {
    super.initState();
    cargar();
  }

  // ============================================================
  // CARGAR HISTORIAL Y TURNO
  // ============================================================

  Future<void> cargar() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    await Future.wait([
      _cargarHistorial(),
      _cargarTurno(),
    ]);

    if (mounted) {
      setState(() => cargando = false);
    }
  }

  Future<void> _cargarHistorial() async {
    try {
      final data = await ApiService.obtenerHistorial();

      if (!mounted) return;

      setState(() {
        registros = data;
        error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'Error al cargar el historial: $e');
    }
  }

  
Future<void> _cargarTurno() async {
  try {
    final actual = await ApiService.obtenerTurnoActual();

    if (!mounted) return;

    setState(() {
      turno = actual;
      errorTurno = null;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      errorTurno = e.toString();
    });
  }
}



  // ============================================================
  // INICIAR TURNO
  // ============================================================

  Future<void> iniciarTurno() async {
    if (operacionTurno) return;

    setState(() {
      operacionTurno = true;
      errorTurno = null;
    });

    try {
      await ApiService.iniciarTurno();
      await Future.wait([_cargarHistorial(), _cargarTurno()]);   // antes: await _cargarTurno();

      if (!mounted) return;

      if (turnoAbierto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turno iniciado correctamente.'),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );

      await _cargarTurno();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar el turno: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => operacionTurno = false);
      }
    }
  }

  // ============================================================
  // CERRAR TURNO
  // ============================================================

  Future<void> cerrarTurno() async {
    if (operacionTurno || !turnoAbierto) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff252536),
        title: const Text(
          'Cerrar turno',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Deseas cerrar tu turno? Se calculará el total '
          'de los servicios asociados a este turno.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar turno'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      operacionTurno = true;
      errorTurno = null;
    });

    try {
      final resultado = await ApiService.cerrarTurno();

      if (!mounted) return;

      final turnoCerrado = resultado['turno'];

      await Future.wait([_cargarHistorial(), _cargarTurno()]);

      final total = turnoCerrado is Map
          ? double.tryParse(
                  turnoCerrado['total_cobrado'].toString(),
                ) ??
                0
          : 0.0;

      final servicios = turnoCerrado is Map
          ? turnoCerrado['cantidad_servicios'] ?? 0
          : 0;

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xff252536),
          title: const Text(
            'Turno cerrado',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'El turno se cerró correctamente.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Text(
                'Servicios: $servicios',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Total cobrado: \$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );

      await _cargarTurno();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar el turno: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => operacionTurno = false);
      }
    }
  }

  // ============================================================
  // FECHAS
  // ============================================================

  String formatearFechaHora(String iso) {
    final f = DateTime.parse(iso).toLocal();

    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];

    final horaStr = f.hour == 0
        ? 12
        : (f.hour > 12 ? f.hour - 12 : f.hour);

    final ampm = f.hour >= 12 ? 'p.m.' : 'a.m.';

    return '${f.day} ${meses[f.month - 1]} ${f.year} '
        '${horaStr.toString().padLeft(2, '0')}:'
        '${f.minute.toString().padLeft(2, '0')}:'
        '${f.second.toString().padLeft(2, '0')} $ampm';
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

  // ============================================================
  // REIMPRIMIR TICKET
  // ============================================================

  Future<void> reimprimirTicket(Map<String, dynamic> r) async {
    final id = int.parse(r['id'].toString());

    if (imprimiendoId != null) return;

    setState(() => imprimiendoId = id);

    try {
      if (!printerService.isConnected) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PrinterPage(),
          ),
        );

        if (!printerService.isConnected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No hay una impresora conectada.'),
              ),
            );
          }
          return;
        }
      }

      final cuarto = r['cuarto'] as Map<String, dynamic>?;

      final motel =
          cuarto?['moteles']?['nombre']?.toString() ?? 'Motel';

      final numeroCuarto =
          int.parse(cuarto?['numero'].toString() ?? '0');

      final minutosTranscurridos =
          int.parse(r['minutos_transcurridos'].toString());

      final total =
          double.parse(r['total'].toString()).toStringAsFixed(0);

      final horaEntrada = formatearHora(
        r['hora_entrada'].toString(),
      );

      final horaSalida = formatearHora(
        r['hora_salida'].toString(),
      );

      final ok = await printerService.imprimirTicket(
        motel: motel,
        numeroCuarto: numeroCuarto,
        horaEntrada: horaEntrada,
        horaSalida: horaSalida,
        minutosTranscurridos: minutosTranscurridos,
        total: total,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Ticket reimpreso correctamente.'
                : 'No se pudo imprimir el ticket.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => imprimiendoId = null);
      }
    }
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

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
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: cargar,
          ),
        ],
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : RefreshIndicator(
              onRefresh: cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildTarjetaTurno(),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: cargar,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  else if (registros.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Todavía no hay cobros registrados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else
                    ...registros.map((registro) {
                      final r = Map<String, dynamic>.from(registro);
                      return _construirRegistro(r);
                    }),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // TARJETA DEL TURNO
  // ============================================================

  Widget _buildTarjetaTurno() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff252536),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: turnoAbierto
              ? Colors.greenAccent.withValues(alpha: 0.5)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                turnoAbierto ? Icons.lock_open : Icons.schedule,
                color: turnoAbierto
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Control de turno',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (operacionTurno)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (errorTurno != null)
            Text(
              errorTurno!,
              style: const TextStyle(color: Colors.redAccent),
            )
          else
            Text(
              turnoAbierto
                  ? 'Tu turno está abierto.'
                  : 'No tienes un turno abierto.',
              style: TextStyle(
                color: turnoAbierto
                    ? Colors.greenAccent
                    : Colors.white70,
                fontSize: 15,
              ),
            ),
          if (turnoAbierto &&
              turno!['fecha_inicio'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Inicio: ${formatearFechaHora(turno!['fecha_inicio'].toString())}',
              style: const TextStyle(color: Colors.white60),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: operacionTurno
                  ? null
                  : turnoAbierto
                      ? cerrarTurno
                      : errorTurno != null
                          ? _cargarTurno
                          : iniciarTurno,
              icon: Icon(
                turnoAbierto ? Icons.stop_circle : Icons.play_circle,
              ),
              label: Text(
                turnoAbierto ? 'CERRAR TURNO' : 'INICIAR TURNO',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: turnoAbierto
                    ? Colors.redAccent
                    : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (errorTurno != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No se pudo verificar el estado. Actualiza antes de iniciar.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTRO DE HISTORIAL
  // ============================================================

  Widget _construirRegistro(Map<String, dynamic> r) {
    final cuarto = r['cuarto'] as Map<String, dynamic>?;

    final motel =
        cuarto?['moteles']?['nombre']?.toString() ?? 'Motel';

    final numeroCuarto = cuarto?['numero']?.toString() ?? '?';

    final total =
        double.parse(r['total'].toString()).toStringAsFixed(0);

    final id = int.parse(r['id'].toString());
    final estaImprimiendo = imprimiendoId == id;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            'Cuarto $numeroCuarto - $motel',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${formatearFechaHora(r['hora_entrada'].toString())}  →  '
              '${formatearFechaHora(r['hora_salida'].toString())}',
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
                '\$ $total',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
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
                  tooltip: 'Reimprimir ticket',
                  icon: const Icon(
                    Icons.print,
                    color: Colors.white70,
                  ),
                  onPressed: () => reimprimirTicket(r),
                ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }
}
