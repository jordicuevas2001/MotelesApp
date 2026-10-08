import 'package:flutter/material.dart';
import 'package:app_moteles/services/api_service.dart';
import 'package:app_moteles/screens/login.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportesAdmin extends StatefulWidget {
  const ReportesAdmin({super.key});

  @override
  State<ReportesAdmin> createState() => _ReportesAdminState();
}

class _ReportesAdminState extends State<ReportesAdmin> {
  static const Color background = Color(0xFF0F141C);
  static const Color cardColor = Color(0xFF171E2A);
  static const Color inputColor = Color(0xFF222A39);
  static const Color gold = Color(0xFFC58B2A);

  String tipoReporte = 'General';

  String periodo = 'Día';

  DateTime fechaSeleccionada = DateTime.now();

  bool cargando = false;

  String? error;

  int servicios = 0;

  double ingresos = 0;

  List<dynamic> moteles = [];

  @override
  void initState() {
    super.initState();

    cargarReporte();
  }

  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(
              color: Colors.white,
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
                Navigator.pop(context, false);
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
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
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

    await ApiService.cerrarSesion();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  String fechaTexto(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  String fechaApi(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$anio-$mes-$dia';
  }

  Map<String, String> obtenerRangoFechas() {
    DateTime inicio;
    DateTime fin;

    if (periodo == 'Día') {
      inicio = fechaSeleccionada;
      fin = fechaSeleccionada;
    } else if (periodo == 'Semana') {
      final diferencia =
          fechaSeleccionada.weekday - DateTime.monday;

      inicio = fechaSeleccionada.subtract(
        Duration(days: diferencia),
      );

      fin = inicio.add(
        const Duration(days: 6),
      );
    } else {
      inicio = DateTime(
        fechaSeleccionada.year,
        fechaSeleccionada.month,
        1,
      );

      fin = DateTime(
        fechaSeleccionada.year,
        fechaSeleccionada.month + 1,
        0,
      );
    }

    return {
      'fecha_inicio': fechaApi(inicio),
      'fecha_fin': fechaApi(fin),
    };
  }

  String textoPeriodo() {
    final rango = obtenerRangoFechas();

    if (periodo == 'Día') {
      return fechaTexto(fechaSeleccionada);
    }

    final inicio = DateTime.parse(
      rango['fecha_inicio']!,
    );

    final fin = DateTime.parse(
      rango['fecha_fin']!,
    );

    return '${fechaTexto(inicio)} - ${fechaTexto(fin)}';
  }

  Future<void> seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color.fromARGB(
                255,
                242,
                170,
                46,
              ),
              surface: Color.fromARGB(
                255,
                28,
                35,
                48,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha == null) return;

    setState(() {
      fechaSeleccionada = fecha;
    });

    await cargarReporte();
  }

  Future<void> cambiarPeriodo(String nuevoPeriodo) async {
    setState(() {
      periodo = nuevoPeriodo;
    });

    await cargarReporte();
  }

  Future<void> cambiarTipoReporte(String? valor) async {
    if (valor == null) return;

    setState(() {
      tipoReporte = valor;
    });

    await cargarReporte();
  }

  // CARGAR RESUMEN


  Future<void> cargarReporte() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final rango = obtenerRangoFechas();

      final int? motelId =
          tipoReporte == 'General'
              ? null
              : int.tryParse(tipoReporte);

      final data = await ApiService.obtenerResumen(
        motelId: motelId,
        fechaInicio: rango['fecha_inicio'],
        fechaFin: rango['fecha_fin'],
      );

      if (!mounted) return;

      setState(() {
        servicios =
            int.tryParse(
                  data['servicios'].toString(),
                ) ??
                0;

        ingresos =
            double.tryParse(
                  data['ingresos'].toString(),
                ) ??
                0;

        moteles =
            data['moteles'] is List
                ? data['moteles']
                : [];

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

  // FORMATO DE DINERO

  String dinero(double cantidad) {
    return '\$${cantidad.toStringAsFixed(2)}';
  }

  // FUNCIONES PARA PDF

  String formatearHoraPdf(String fecha) {
    try {
      final date = DateTime.parse(fecha).toLocal();

      final hora = date.hour;
      final minuto = date.minute;

      final periodoHora = hora >= 12 ? 'PM' : 'AM';

      int hora12 = hora % 12;

      if (hora12 == 0) {
        hora12 = 12;
      }

      return '$hora12:${minuto.toString().padLeft(2, '0')} '
          '$periodoHora';
    } catch (_) {
      return fecha;
    }
  }

  String formatearFechaPdf(String fecha) {
    try {
      final date = DateTime.parse(fecha);

      return fechaTexto(date);
    } catch (_) {
      return fecha;
    }
  }

  String formatearDuracionPdf(int minutos) {
    final horas = minutos ~/ 60;
    final mins = minutos % 60;

    if (horas > 0) {
      return '${horas}h '
          '${mins.toString().padLeft(2, '0')}min';
    }

    return '${mins}min';
  }

  String dineroPdf(dynamic valor) {
    final cantidad =
        double.tryParse(valor.toString()) ?? 0;

    return '\$${cantidad.toStringAsFixed(2)}';
  }

  String nombreMotelPdf(String nombre) {
    return nombre.toUpperCase();
  }

  // GENERAR PDF


  Future<void> generarReportePdf() async {
    try {
      if (!mounted) return;

      setState(() {
        cargando = true;
        error = null;
      });

      final rango = obtenerRangoFechas();

      final int? motelId =
          tipoReporte == 'General'
              ? null
              : int.tryParse(tipoReporte);

      // OBTENER TODOS LOS SERVICIOS
   

      final reporte =
          await ApiService.obtenerReporteDetallado(
        motelId: motelId,
        fechaInicio: rango['fecha_inicio']!,
        fechaFin: rango['fecha_fin']!,
      );

      final pdf = pw.Document();

      final motelesPdf =
          reporte['moteles'] is List
              ? reporte['moteles'] as List<dynamic>
              : <dynamic>[];

      final serviciosTotal =
          int.tryParse(
                reporte['servicios_total']
                    .toString(),
              ) ??
              0;

      final totalGeneral =
          double.tryParse(
                reporte['total_general']
                    .toString(),
              ) ??
              0;
      // CREAR PDF
   

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,

          margin: const pw.EdgeInsets.all(30),

          header: (context) {
            return pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,

              children: [
                pw.Text(
                  'SISTEMA DE CONTROL',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 4),

                pw.Text(
                  'REPORTE DE SERVICIOS',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 5),

                pw.Text(
                  'Periodo: '
                  '${formatearFechaPdf(
                    rango['fecha_inicio']!,
                  )} - '
                  '${formatearFechaPdf(
                    rango['fecha_fin']!,
                  )}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                  ),
                ),

                pw.SizedBox(height: 15),

                pw.Divider(),
              ],
            );
          },

          footer: (context) {
            return pw.Container(
              alignment:
                  pw.Alignment.centerRight,

              margin:
                  const pw.EdgeInsets.only(
                top: 10,
              ),

              child: pw.Text(
                'Página '
                '${context.pageNumber} '
                'de '
                '${context.pagesCount}',

                style:
                    const pw.TextStyle(
                  fontSize: 8,
                ),
              ),
            );
          },

          build: (context) {
            final widgets =
                <pw.Widget>[];

            // SIN SERVICIOS


            if (motelesPdf.isEmpty) {
              widgets.add(
                pw.Center(
                  child: pw.Padding(
                    padding:
                        const pw.EdgeInsets.all(
                      30,
                    ),
                    child: pw.Text(
                      'No hay servicios registrados '
                      'en este periodo.',

                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }

            // MOTEL POR MOTEL

            for (final motel in motelesPdf) {
              final nombre =
                  motel['motel']
                          ?.toString() ??
                      'MOTEL';

              final serviciosMotel =
                  motel['servicios'] is List
                      ? motel['servicios']
                          as List<dynamic>
                      : <dynamic>[];

              final totalMotel =
                  double.tryParse(
                        motel['total_motel']
                            .toString(),
                      ) ??
                      0;

              widgets.add(
                pw.Container(
                  margin:
                      const pw.EdgeInsets.only(
                    bottom: 20,
                  ),

                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment
                            .start,

                    children: [

                      // ENCABEZADO MOTEL

                      pw.Container(
                        width:
                            double.infinity,

                        padding:
                            const pw.EdgeInsets
                                .all(10),

                        child: pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment
                                  .spaceBetween,

                          children: [
                            pw.Text(
                              nombreMotelPdf(
                                nombre,
                              ),

                              style:
                                  pw.TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    pw.FontWeight
                                        .bold,
                              ),
                            ),

                            pw.Text(
                              '${serviciosMotel.length} servicios',

                              style:
                                  pw.TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    pw.FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(
                        height: 8,
                      ),


                      // TABLA


                      if (serviciosMotel.isNotEmpty)
                        pw.TableHelper
                            .fromTextArray(
                          headers: [
                            'Cuarto',
                            'Entrada',
                            'Salida',
                            'Tiempo',
                            'Cobro',
                          ],

                          data:
                              serviciosMotel
                                  .map(
                            (servicio) {
                              final cuarto =
                                  servicio[
                                      'cuarto'];

                              final numeroCuarto =
                                  cuarto
                                          is Map
                                      ? cuarto[
                                              'numero']
                                          ?.toString()
                                      : '-';

                              final entrada =
                                  servicio[
                                      'hora_entrada'];

                              final salida =
                                  servicio[
                                      'hora_salida'];

                              final minutos =
                                  int.tryParse(
                                        servicio[
                                                'minutos_transcurridos']
                                            .toString(),
                                      ) ??
                                      0;

                              return [
                                numeroCuarto,

                                formatearHoraPdf(
                                  entrada
                                          ?.toString() ??
                                      '-',
                                ),

                                formatearHoraPdf(
                                  salida
                                          ?.toString() ??
                                      '-',
                                ),

                                formatearDuracionPdf(
                                  minutos,
                                ),

                                dineroPdf(
                                  servicio['total'],
                                ),
                              ];
                            },
                          ).toList(),

                          headerStyle:
                              pw.TextStyle(
                            fontSize: 9,
                            fontWeight:
                                pw.FontWeight
                                    .bold,
                          ),

                          cellStyle:
                              const pw.TextStyle(
                            fontSize: 8,
                          ),

                          cellAlignment:
                              pw.Alignment.center,

                          headerDecoration:
                              const pw.BoxDecoration(
                            color:
                                PdfColors
                                    .grey300,
                          ),

                          border:
                              pw.TableBorder
                                  .all(
                            color:
                                PdfColors
                                    .grey400,
                            width: .5,
                          ),

                          cellPadding:
                              const pw.EdgeInsets
                                  .all(5),
                        ),

                      if (serviciosMotel.isEmpty)
                        pw.Padding(
                          padding:
                              const pw.EdgeInsets
                                  .all(10),

                          child: pw.Text(
                            'No hay servicios '
                            'registrados para este motel.',
                            style:
                                const pw.TextStyle(
                              fontSize: 9,
                            ),
                          ),
                        ),

                      pw.SizedBox(
                        height: 8,
                      ),

                      // TOTAL MOTEL

                      pw.Align(
                        alignment:
                            pw.Alignment
                                .centerRight,

                        child: pw.Text(
                          'TOTAL '
                          '${nombreMotelPdf(nombre)}: '
                          '${dineroPdf(totalMotel)}',

                          style:
                              pw.TextStyle(
                            fontSize: 12,
                            fontWeight:
                                pw.FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // RESUMEN GENERAL


            widgets.add(
              pw.Container(
                margin:
                    const pw.EdgeInsets.only(
                  top: 10,
                ),

                padding:
                    const pw.EdgeInsets.all(
                  12,
                ),

                decoration:
                    pw.BoxDecoration(
                  border:
                      pw.Border.all(
                    color:
                        PdfColors.grey500,
                  ),
                ),

                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment
                          .start,

                  children: [
                    pw.Text(
                      'RESUMEN GENERAL',

                      style:
                          pw.TextStyle(
                        fontSize: 14,
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),

                    pw.SizedBox(
                      height: 8,
                    ),

                    pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment
                              .spaceBetween,

                      children: [
                        pw.Text(
                          'Total de servicios:',
                        ),

                        pw.Text(
                          serviciosTotal
                              .toString(),

                          style:
                              pw.TextStyle(
                            fontWeight:
                                pw.FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(
                      height: 5,
                    ),

                    pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment
                              .spaceBetween,

                      children: [
                        pw.Text(
                          'TOTAL GENERAL:',

                          style:
                              pw.TextStyle(
                            fontWeight:
                                pw.FontWeight
                                    .bold,
                          ),
                        ),

                        pw.Text(
                          dineroPdf(
                            totalGeneral,
                          ),

                          style:
                              pw.TextStyle(
                            fontSize: 14,
                            fontWeight:
                                pw.FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

            return widgets;
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      // MOSTRAR / IMPRIMIR PDF

      await Printing.layoutPdf(
        onLayout:
            (PdfPageFormat format) async {
          return pdf.save();
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo generar el PDF:\n$e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,

        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              'SISTEMA DE CONTROL',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),

            Text(
              'REPORTES DE ADMINISTRADOR',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: cargarReporte,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Actualizar',
          ),

          IconButton(
            onPressed: cerrarSesion,
            icon: const Icon(
              Icons.logout,
            ),
            tooltip: 'Cerrar sesión',
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: cargando
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: gold,
                ),
              )
            : error != null
                ? _buildError()
                : _buildContenido(),
      ),
    );
  }


  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 60,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'No se pudo obtener el reporte',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              error ?? 'Error desconocido',

              textAlign:
                  TextAlign.center,

              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed: cargarReporte,

              icon: const Icon(
                Icons.refresh,
              ),

              label: const Text(
                'Reintentar',
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor:
                    Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    return RefreshIndicator(
      onRefresh: cargarReporte,

      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            _buildTitulo(),

            const SizedBox(
              height: 20,
            ),

            _buildFiltros(),

            const SizedBox(
              height: 20,
            ),

            _buildResumenGeneral(),

            const SizedBox(
              height: 25,
            ),

            _buildResumenMoteles(),
          ],
        ),
      ),
    );
  }


  Widget _buildTitulo() {
    return const Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'Panel de reportes',

          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        SizedBox(
          height: 6,
        ),

        Text(
          'Consulta el rendimiento de los moteles por periodo.',

          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
      ],
    );
  }


  Widget _buildFiltros() {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: Colors.white10,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Filtros del reporte',

            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'MOTEL',

            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          DropdownButtonFormField<String>(
            value: tipoReporte,

            dropdownColor:
                inputColor,

            style:
                const TextStyle(
              color: Colors.white,
            ),

            decoration:
                InputDecoration(
              filled: true,

              fillColor:
                  inputColor,

              prefixIcon:
                  const Icon(
                Icons.hotel,
                color: gold,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),

            items: const [
              DropdownMenuItem(
                value: 'General',
                child: Text(
                  'Todos los moteles',
                ),
              ),

              DropdownMenuItem(
                value: '1',
                child: Text(
                  'El Faraón',
                ),
              ),

              DropdownMenuItem(
                value: '2',
                child: Text(
                  'La Curva',
                ),
              ),
            ],

            onChanged:
                cambiarTipoReporte,
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'PERIODO',

            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _botonPeriodo(
                  'Día',
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                    _botonPeriodo(
                  'Semana',
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                    _botonPeriodo(
                  'Mes',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'FECHA',

            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          InkWell(
            onTap:
                seleccionarFecha,

            borderRadius:
                BorderRadius.circular(
              12,
            ),

            child: Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
                vertical: 16,
              ),

              decoration:
                  BoxDecoration(
                color: inputColor,

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: gold,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          textoPeriodo(),

                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          periodo ==
                                  'Día'
                              ? 'Reporte del día seleccionado'
                              : 'Periodo seleccionado',

                          style:
                              const TextStyle(
                            color:
                                Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_drop_down,
                    color:
                        Colors.white54,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ======================================================
          // BOTÓN GENERAR PDF
          // ======================================================

          SizedBox(
            width:
                double.infinity,

            height: 50,

            child:
                ElevatedButton.icon(
              onPressed:
                  generarReportePdf,

              icon:
                  const Icon(
                Icons.picture_as_pdf,
              ),

              label:
                  const Text(
                'GENERAR REPORTE PDF',

                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    gold,

                foregroundColor:
                    Colors.black,

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

  Widget _botonPeriodo(
    String texto,
  ) {
    final seleccionado =
        periodo == texto;

    return InkWell(
      onTap: () =>
          cambiarPeriodo(texto),

      borderRadius:
          BorderRadius.circular(10),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 13,
        ),

        decoration:
            BoxDecoration(
          color: seleccionado
              ? gold
              : inputColor,

          borderRadius:
              BorderRadius.circular(
            10,
          ),

          border:
              Border.all(
            color: seleccionado
                ? gold
                : Colors.white10,
          ),
        ),

        child: Center(
          child: Text(
            texto,

            style: TextStyle(
              color: seleccionado
                  ? Colors.black
                  : Colors.white70,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumenGeneral() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'Resumen',

          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Row(
          children: [
            Expanded(
              child:
                  _tarjetaResumen(
                icono:
                    Icons.login,
                titulo:
                    'Servicios',
                valor:
                    servicios.toString(),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child:
                  _tarjetaResumen(
                icono:
                    Icons.attach_money,
                titulo:
                    'Ingresos',
                valor:
                    dinero(ingresos),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _tarjetaResumen({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: Colors.white10,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icono,
            color: gold,
            size: 30,
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            titulo,

            style:
                const TextStyle(
              color:
                  Colors.white54,
              fontSize: 13,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          FittedBox(
            child: Text(
              valor,

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 25,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESUMEN POR MOTELES
  // ============================================================

  Widget _buildResumenMoteles() {
    if (moteles.isEmpty) {
      return Container(
        width:
            double.infinity,

        padding:
            const EdgeInsets.all(25),

        decoration:
            BoxDecoration(
          color: cardColor,

          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),

        child: const Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: Colors.white30,
              size: 50,
            ),

            SizedBox(
              height: 12,
            ),

            Text(
              'No hay registros para este periodo.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    Colors.white60,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'Rendimiento por motel',

          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        ...moteles.map(
          (motel) {
            final nombre =
                motel['motel']
                        ?.toString() ??
                    'Motel';

            final serviciosMotel =
                int.tryParse(
                      motel['servicios']
                          .toString(),
                    ) ??
                    0;

            final ingresosMotel =
                double.tryParse(
                      motel['ingresos']
                          .toString(),
                    ) ??
                    0;

            return Container(
              width:
                  double.infinity,

              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),

              padding:
                  const EdgeInsets.all(
                18,
              ),

              decoration:
                  BoxDecoration(
                color: cardColor,

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                border: Border.all(
                  color:
                      Colors.white10,
                ),
              ),

              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,

                    decoration:
                        BoxDecoration(
                      color:
                          gold.withOpacity(
                        .15,
                      ),

                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),

                    child:
                        const Icon(
                      Icons.hotel,
                      color: gold,
                    ),
                  ),

                  const SizedBox(
                    width: 15,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          nombre,

                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          '$serviciosMotel servicios',

                          style:
                              const TextStyle(
                            color:
                                Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .end,

                    children: [
                      const Text(
                        'INGRESOS',

                        style:
                            TextStyle(
                          color:
                              Colors.white38,
                          fontSize: 9,
                          letterSpacing:
                              1,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        dinero(
                          ingresosMotel,
                        ),

                        style:
                            const TextStyle(
                          color: gold,
                          fontSize: 17,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}