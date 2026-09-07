import 'package:flutter/material.dart';
import '../screens/habitacion.dart';

class EstadisticasHeader extends StatelessWidget {
  final List<Habitacion> habitaciones;

  const EstadisticasHeader({
    super.key,
    required this.habitaciones,
  });

  @override
  Widget build(BuildContext context) {
    final total = habitaciones.length;
    final ocupados = habitaciones.where((h) => h.ocupada).length;
    final libres = total - ocupados;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _tarjetaStat(
              valor: total.toString(),
              etiqueta: "TOTAL",
              color: Colors.white,
              borde: Colors.white24,
              fondo: const Color(0xFF3A3A3A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _tarjetaStat(
              valor: libres.toString(),
              etiqueta: "LIBRES",
              color: Colors.greenAccent,
              borde: Colors.greenAccent,
              fondo: const Color(0xFF1B2E22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _tarjetaStat(
              valor: ocupados.toString(),
              etiqueta: "OCUPADOS",
              color: Colors.orangeAccent,
              borde: Colors.orangeAccent,
              fondo: const Color(0xFF3A2A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaStat({
    required String valor,
    required String etiqueta,
    required Color color,
    required Color borde,
    required Color fondo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borde, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
