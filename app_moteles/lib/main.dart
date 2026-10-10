import 'package:flutter/material.dart';
import 'screens/habitacion.dart';
import 'services/api_service.dart';
import 'services/reverb_service.dart';
import 'widgets/registro.dart';
import 'widgets/cobro.dart';
import 'widgets/hab_estados.dart';
import 'screens/historial.dart';
import 'screens/login.dart';
import 'screens/adminscreen/reportes_admin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),
      home: const InicioScreen(),
    );
  }
}

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  @override
  void initState() {
    super.initState();

    verificarSesion();
  }

  Future<void> verificarSesion() async {
    try {
      final tieneSesion =
          await ApiService.tieneSesion();

      if (!tieneSesion) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginScreen(),
          ),
        );

        return;
      }

      final usuario =
          await ApiService.obtenerUsuario();

      if (!mounted) return;

      if (usuario == null) {
        await ApiService.cerrarSesion();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginScreen(),
          ),
        );

        return;
      }

      final rol = usuario['rol'];

      if (rol == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ReportesAdmin(),
          ),
        );

        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MotelScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor:
          Color(0xFF0F141C),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC58B2A),
        ),
      ),
    );
  }
}

class MotelScreen extends StatefulWidget {
  const MotelScreen({super.key});

  @override
  State<MotelScreen> createState() =>
      _MotelScreenState();
}

class _MotelScreenState extends State<MotelScreen> {
  List<Habitacion> habitaciones = [];

  bool cargando = true;

  String? error;

  // NOMBRE DEL MOTEL
  String nombreMotel = 'MOTEL EL FARAON';

  @override
  void initState() {
    super.initState();

    cargarDatos();
    conectarReverb();
  }

  Future<void> conectarReverb() async {
    try {
      final motelId = await ApiService.obtenerMotelId();

      if (motelId == null) {
        print('REVERB: No se encontró motel_id.');
        return;
      }

      print('REVERB: Conectando al motel $motelId...');

      await ReverbService.instance.conectar(
        motelId: motelId,
        onCuartoActualizado: (data) {
          print('REVERB: Cuarto actualizado: $data');

          if (!mounted) return;

          cargarCuartos();
        },
      );
    } catch (e) {
      print('REVERB: Error conectando: $e');
    }
  }

  @override
  void dispose() {
    ReverbService.instance.desconectar();
    super.dispose();
  }

  Future<void> cargarDatos() async {
    try {
      final usuario =
          await ApiService.obtenerUsuario();

      if (!mounted) return;

      if (usuario != null) {
        final motel =
            usuario['motel'];

        if (motel != null) {
          final nombre =
              motel['nombre'];

          if (nombre != null) {
            setState(() {
              nombreMotel =
                  nombre
                      .toString()
                      .toUpperCase();
            });
          }
        }
      }
    } catch (e) {
      print(
        'ERROR OBTENIENDO MOTEL: $e',
      );
    }

    await cargarCuartos();
  }

  // CARGAR CUARTOS

  Future<void> cargarCuartos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final data =
          await ApiService.obtenerCuartos();

      if (!mounted) return;

      setState(() {
        habitaciones = data
            .map(
              (j) =>
                  Habitacion.fromJson(j),
            )
            .toList();

        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        cargando = false;
      });
    }
  }

  // CERRAR SESIÓN

  Future<void> cerrarSesion() async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF171E2A),

          title: const Text(
            'Cerrar sesión',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          content: const Text(
            '¿Seguro que deseas cerrar la sesión?',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Cerrar sesión',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await ApiService.cerrarSesion();
    } catch (e) {
      // Aunque falle la petición,
      // se cerrará la sesión localmente.
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // FORMATO TIEMPO

  String formatoTiempo(
    Duration tiempo,
  ) {
    String horas =
        tiempo.inHours
            .toString()
            .padLeft(2, '0');

    String minutos =
        (tiempo.inMinutes % 60)
            .toString()
            .padLeft(2, '0');

    String segundos =
        (tiempo.inSeconds % 60)
            .toString()
            .padLeft(2, '0');

    return "$horas:$minutos:$segundos";
  }

  // BUILD

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(
        255,
        30,
        31,
        30,
      ),

      // APP BAR

      appBar: AppBar(
        backgroundColor:
            Colors.deepPurple,

        foregroundColor:
            Colors.white,

        titleSpacing: 16,

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Text(
              "SISTEMA DE CONTROL",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),

            Text(
              nombreMotel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [

          // ACTUALIZAR

          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed:
                cargarCuartos,
            tooltip: 'Actualizar',
          ),

          // HISTORIAL

          Padding(
            padding:
                const EdgeInsets.only(
              right: 12,
            ),

            child:
                OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const HistorialScreen(),
                  ),
                );
              },

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.white,

                side:
                    const BorderSide(
                  color:
                      Colors.white54,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),

              icon: const Icon(
                Icons.access_time,
                size: 18,
              ),

              label: const Text(
                "Historial",
              ),
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (cargando) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const Icon(
                Icons.wifi_off,
                color:
                    Colors.white54,
                size: 48,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                "No se pudo conectar con el servidor.\n$error",

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  color:
                      Colors.white70,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              ElevatedButton(
                onPressed:
                    cargarCuartos,
                child:
                    const Text(
                  "Reintentar",
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.all(12),

      child: Column(
        children: [
          // ======================================================
          // ESTADÍSTICAS
          // ======================================================

          EstadisticasHeader(
            habitaciones:
                habitaciones,
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // CUARTOS
          // ======================================================

          Expanded(
            child:
                GridView.builder(
              itemCount:
                  habitaciones.length,

              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,

                crossAxisSpacing:
                    12,

                mainAxisSpacing:
                    12,

                childAspectRatio:
                    1.3,
              ),

              itemBuilder:
                  (context, index) {
                final habitacion =
                    habitaciones[
                        index];

                return Card(
                  elevation: 6,

                  color:
                      const Color.fromARGB(
                    255,
                    64,
                    71,
                    64,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                  ),

                  child: InkWell(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),

                    onTap: () {
                      if (habitacion
                          .ocupada) {
                        MostrarCobro
                            .show(
                          context,
                          habitacion,
                          () {
                            cargarCuartos();
                          },
                        );
                      } else {
                        MostrarRegistro
                            .show(
                          context,
                          habitacion,
                          () {
                            cargarCuartos();
                          },
                        );
                      }
                    },

                    child:
                        Stack(
                      children: [
                        // ==================================================
                        // ESTADO
                        // ==================================================

                        Positioned(
                          top: 10,
                          right: 10,

                          child: Icon(
                            Icons.circle,

                            color: habitacion
                                    .ocupada
                                ? Colors.red
                                : Colors
                                    .greenAccent,

                            size: 15,
                          ),
                        ),

                        // ==================================================
                        // CONTENIDO
                        // ==================================================

                        Center(
                          child:
                              Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                            children: [
                              // ============================================
                              // CUARTO
                              // ============================================

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,

                                children: [
                                  Text(
                                    "Cuarto ${habitacion.numero}",

                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,

                                      fontSize:
                                          22,

                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  const Icon(
                                    Icons.hotel,

                                    color:
                                        Colors.white,

                                    size: 35,
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              // ============================================
                              // TIEMPO
                              // ============================================

                              StreamBuilder<
                                  int>(
                                stream:
                                    Stream.periodic(
                                  const Duration(
                                    seconds:
                                        1,
                                  ),
                                  (x) =>
                                      x,
                                ),

                                builder:
                                    (
                                  context,
                                  snapshot,
                                ) {
                                  if (!habitacion
                                          .ocupada ||
                                      habitacion
                                              .horaEntrada ==
                                          null) {
                                    return const Text(
                                      "Disponible",

                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white70,

                                        fontSize:
                                            16,
                                      ),
                                    );
                                  }

                                  final tiempo =
                                      DateTime.now()
                                          .difference(
                                    habitacion
                                        .horaEntrada!,
                                  );

                                  return Text(
                                    formatoTiempo(
                                      tiempo,
                                    ),

                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,

                                      fontSize:
                                          16,

                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              // ============================================
                              // TEXTO
                              // ============================================

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,

                                children: const [
                                  Icon(
                                    Icons
                                        .touch_app,

                                    color:
                                        Colors.white,

                                    size: 25,
                                  ),

                                  SizedBox(
                                    width: 5,
                                  ),

                                  Text(
                                    "Toca para registrar",

                                    style:
                                        TextStyle(
                                      color:
                                          Colors.white70,

                                      fontSize:
                                          10,
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

          const SizedBox(
            height: 12,
          ),

          // ========================================================
          // CERRAR SESIÓN
          // ========================================================

          SizedBox(
            width:
                double.infinity,

            height: 52,

            child:
                ElevatedButton.icon(
              onPressed:
                  cerrarSesion,

              icon: const Icon(
                Icons.logout,
                color:
                    Colors.white,
              ),

              label: const Text(
                "CERRAR SESIÓN",

                style: TextStyle(
                  color:
                      Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,

                foregroundColor:
                    Colors.white,

                elevation: 4,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}