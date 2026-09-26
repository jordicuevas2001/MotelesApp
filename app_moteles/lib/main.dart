import 'package:flutter/material.dart';
import 'screens/habitacion.dart';
import 'services/api_service.dart';
import 'widgets/registro.dart';
import 'widgets/cobro.dart';
import 'widgets/hab_estados.dart';
import 'screens/historial.dart';
import 'screens/login.dart';
import 'services/printer_service.dart';
import 'package:app_moteles/screens/printer_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Entradas y Salidas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MotelScreen(),
    );
  }
}

class MotelScreen extends StatefulWidget {
  const MotelScreen({super.key});

  @override
  State<MotelScreen> createState() => _MotelScreenState();
}

class _MotelScreenState extends State<MotelScreen> {
  List<Habitacion> habitaciones = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarCuartos();
  }

  Future<void> cargarCuartos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final data = await ApiService.obtenerCuartos();
      setState(() {
        habitaciones = data.map((j) => Habitacion.fromJson(j)).toList();
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        cargando = false;
      });
    }
  }

  String formatoTiempo(Duration tiempo) {
    String horas = tiempo.inHours.toString().padLeft(2, '0');
    String minutos = (tiempo.inMinutes % 60).toString().padLeft(2, '0');
    String segundos = (tiempo.inSeconds % 60).toString().padLeft(2, '0');

    return "$horas:$minutos:$segundos";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 31, 30),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "SISTEMA DE CONTROL",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "MOTEL EL FARAON",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarCuartos,
            tooltip: 'Actualizar',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(

                
              //boton para tener el historial de los cortes
              //la pantalla a la que pertenece: HistorialScreen / LoginScreen
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrinterPage(),
                  ),
                );
              },
              
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.access_time, size: 18),
              label: const Text("Historial"),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  

  Widget _buildBody() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              Text(
                "No se pudo conectar con el servidor.\n$error",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: cargarCuartos,
                child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          EstadisticasHeader(habitaciones: habitaciones),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              itemCount: habitaciones.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                final habitacion = habitaciones[index];

                return Card(
                  elevation: 6,
                  color: const Color.fromARGB(255, 64, 71, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      if (habitacion.ocupada) {
                        MostrarCobro.show(context, habitacion, () {
                          cargarCuartos(); // recarga desde el backend tras cobrar
                        });
                      } else {
                        MostrarRegistro.show(context, habitacion, () {
                          cargarCuartos(); // recarga desde el backend tras registrar
                        });
                      }
                    },
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(
                            Icons.circle,
                            color: habitacion.ocupada
                                ? Colors.red
                                : Colors.greenAccent,
                            size: 15,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Cuarto ${habitacion.numero}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.hotel,
                                    color: Colors.white,
                                    size: 35,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// CRONÓMETRO
                              StreamBuilder<int>(
                                stream: Stream.periodic(
                                  const Duration(seconds: 1),
                                  (x) => x,
                                ),
                                builder: (context, snapshot) {
                                  if (!habitacion.ocupada ||
                                      habitacion.horaEntrada == null) {
                                    return const Text(
                                      "Disponible",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    );
                                  }

                                  final tiempo = DateTime.now().difference(
                                    habitacion.horaEntrada!,
                                  );

                                  return Text(
                                    formatoTiempo(tiempo),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:  [
                                  Icon(
                                    Icons.touch_app,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "Toca para registrar${habitacion.ocupada ? " el cobro" : ""}",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


//Prueba de commit