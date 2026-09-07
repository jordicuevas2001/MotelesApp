import 'package:flutter/material.dart';
import '../screens/habitacion.dart';
import '../services/api_service.dart';

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
        return _CobroContenido(habitacion: habitacion, actualizar: actualizar);
      },
    );
  }
}

class _CobroContenido extends StatefulWidget {
  final Habitacion habitacion;
  final VoidCallback actualizar;

  const _CobroContenido({required this.habitacion, required this.actualizar});

  @override
  State<_CobroContenido> createState() => _CobroContenidoState();
}

class _CobroContenidoState extends State<_CobroContenido> {
  Map<String, dynamic>? preview;
  String? error;
  bool cobrando = false;

  @override
  void initState() {
    super.initState();
    cargarPreview();
  }

  Future<void> cargarPreview() async {
    try {
      final data = await ApiService.previewCobro(widget.habitacion.id);
      setState(() {
        preview = data;
        error = null;
      });
    } on ApiException catch (e) {
      setState(() => error = e.message);
    }
  }

  Future<void> cobrar() async {
    setState(() => cobrando = true);
    try {
      await ApiService.registrarSalida(widget.habitacion.id);
      if (mounted) Navigator.pop(context);
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

  String formatearHora(String isoString) {
    final hora = DateTime.parse(isoString).toLocal();
    return "${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}";
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (preview == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final registro = preview!['registro'];
    final minutos = preview!['minutos_transcurridos'] as int;
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
        dato("Hora de entrada", formatearHora(registro['hora_entrada'])),
        const SizedBox(height: 15),
        dato("Tiempo transcurrido", formatearTiempo(minutos)),
        const SizedBox(height: 15),
        dato("Total", "\$${double.parse(total.toString()).toStringAsFixed(0)}"),
        const Spacer(),
        SizedBox(
          width: 300,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget dato(String titulo, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titulo, style: const TextStyle(color: Colors.white70, fontSize: 18)),
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