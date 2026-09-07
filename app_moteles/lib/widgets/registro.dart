import 'package:flutter/material.dart';
import 'package:app_moteles/screens/habitacion.dart';
import '../services/api_service.dart';
import 'tarifas.dart';

class MostrarRegistro {
  static void show(
    BuildContext context,
    Habitacion habitacion,
    VoidCallback actualizar,
  ) {
    bool cargando = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 350,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xff252536),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Text(
                    "Registrar Entrada - #${habitacion.numero}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Tarifas",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const TarifasRow(),
                  const SizedBox(height: 30),
                  TextButton(
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.all(Colors.blue),
                      backgroundColor: WidgetStateProperty.all(Colors.white),
                      fixedSize: WidgetStateProperty.all(const Size(300, 40)),
                    ),
                    onPressed: cargando
                        ? null
                        : () async {
                            setModalState(() => cargando = true);

                            try {
                              await ApiService.registrarEntrada(habitacion.id);
                              if (context.mounted) Navigator.pop(context);
                              actualizar();
                            } on ApiException catch (e) {
                              setModalState(() => cargando = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.message)),
                                );
                              }
                            }
                          },
                    child: cargando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Registrar Entrada"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}