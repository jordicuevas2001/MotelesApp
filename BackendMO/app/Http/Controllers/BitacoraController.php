<?php

namespace App\Http\Controllers;

use App\Events\CuartoActualizado;
use App\Helpers\ResponseHelpers;
use App\Models\Bitacora;
use App\Models\Cuartos;
use Illuminate\Http\Request;

class BitacoraController extends Controller
{
    // POST /api/cuartos/{id}/entrada
    public function registrarEntrada(Request $request, $id)
    {
        $usuario = $request->user();

        // Solo puede acceder a cuartos de su propio motel
        $cuarto = Cuartos::where('id', $id)
            ->where('motel_id', $usuario->motel_id)
            ->firstOrFail();

        if ($cuarto->ocupado) {
            return ResponseHelpers::error(
                'El cuarto ya está ocupado',
                422
            );
        }

        $registro = Bitacora::create([
            'cuarto_id' => $cuarto->id,
            'usuario_id' => $usuario->id,
            'hora_entrada' => now(),
        ]);

        $cuarto->ocupado = true;
        $cuarto->save();

        // 🔔 AVISAR A LOS CLIENTES CONECTADOS
        broadcast(new CuartoActualizado(
            (int) $cuarto->motel_id,
            (int) $cuarto->id,
            'entrada'
        ));

        return ResponseHelpers::success([
            'cuarto' => $cuarto,
            'registro' => $registro,
        ], 'Entrada registrada correctamente', 201);
    }

    // GET /api/cuartos/{id}/cobro
    public function previewCobro(Request $request, $id)
    {
        $usuario = $request->user();

        // Solo puede consultar cuartos de su motel
        $cuarto = Cuartos::where('id', $id)
            ->where('motel_id', $usuario->motel_id)
            ->firstOrFail();

        $registro = Bitacora::where('cuarto_id', $cuarto->id)
            ->whereNull('hora_salida')
            ->with('cuarto')
            ->first();

        if (!$registro) {
            return ResponseHelpers::error(
                'El cuarto no tiene un registro activo',
                422
            );
        }

        $minutos = (int) $registro->hora_entrada->diffInMinutes(now());

        return ResponseHelpers::success([
            'registro' => $registro,
            'minutos_transcurridos' => $minutos,
            'total' => $registro->calcularCobro($minutos),
        ], 'Cobro calculado correctamente');
    }

    // POST /api/cuartos/{id}/salida
    public function registrarSalida(Request $request, $id)
    {
        $usuario = $request->user();

        // Solo puede cerrar cuartos de su motel
        $cuarto = Cuartos::where('id', $id)
            ->where('motel_id', $usuario->motel_id)
            ->firstOrFail();

        $registro = Bitacora::where('cuarto_id', $cuarto->id)
            ->whereNull('hora_salida')
            ->with('cuarto')
            ->first();

        if (!$registro) {
            return ResponseHelpers::error(
                'El cuarto no tiene un registro activo',
                422
            );
        }

        $minutos = (int) $registro->hora_entrada->diffInMinutes(now());

        $total = $registro->calcularCobro($minutos);

        $registro->hora_salida = now();
        $registro->total = $total;
        $registro->observaciones = $request->input('observaciones');
        $registro->save();

        $cuarto->ocupado = false;
        $cuarto->save();

        $registro->setRelation('cuarto', $cuarto);

        // 🔔 AVISAR A LOS CLIENTES CONECTADOS
        broadcast(new CuartoActualizado(
            (int) $cuarto->motel_id,
            (int) $cuarto->id,
            'salida'
        ));

        return ResponseHelpers::success([
            'registro' => $registro,
            'total' => $total,
            'minutos_transcurridos' => $minutos,
        ], 'Salida registrada correctamente');
    }

    // GET /api/historial
    public function historial(Request $request)
    {
        $usuario = $request->user();

        $validado = $request->validate([
            'motel_id' => 'nullable|integer|exists:moteles,id',
            'fecha_inicio' => 'nullable|date',
            'fecha_fin' => 'nullable|date|after_or_equal:fecha_inicio',
        ]);

        $registros = Bitacora::with([
            'cuarto.moteles',
            'usuario',
        ])
            ->whereNotNull('hora_salida')

            // USUARIO NORMAL: SOLO SU MOTEL
            ->when(
                $usuario->rol !== 'admin',
                function ($query) use ($usuario) {
                    $query->whereHas('cuarto', function ($q) use ($usuario) {
                        $q->where('motel_id', $usuario->motel_id);
                    });
                }
            )

            // ADMIN: PUEDE FILTRAR POR MOTEL
            ->when(
                $usuario->rol === 'admin' &&
                !empty($validado['motel_id']),
                function ($query) use ($validado) {
                    $query->whereHas('cuarto', function ($q) use ($validado) {
                        $q->where('motel_id', $validado['motel_id']);
                    });
                }
            )

            // FECHA INICIAL
            ->when(
                !empty($validado['fecha_inicio']),
                function ($query) use ($validado) {
                    $query->whereDate(
                        'hora_salida',
                        '>=',
                        $validado['fecha_inicio']
                    );
                }
            )

            // FECHA FINAL
            ->when(
                !empty($validado['fecha_fin']),
                function ($query) use ($validado) {
                    $query->whereDate(
                        'hora_salida',
                        '<=',
                        $validado['fecha_fin']
                    );
                }
            )

            ->orderByDesc('hora_salida')
            ->paginate(20);

        // DURACIÓN CALCULADA POR LARAVEL
        $registros->getCollection()->transform(function ($registro) {

            $segundosTranscurridos = $registro->hora_entrada
                ->diffInSeconds($registro->hora_salida);

            $registro->minutos_transcurridos = intdiv(
                $segundosTranscurridos,
                60
            );

            return $registro;
        });

        return ResponseHelpers::success(
            $registros,
            'Historial obtenido correctamente'
        );
    }

    // GET /api/resumen
    public function resumen(Request $request)
    {
        $usuario = $request->user();

        $validado = $request->validate([
            'motel_id' => 'nullable|integer|exists:moteles,id',
            'fecha_inicio' => 'nullable|date',
            'fecha_fin' => 'nullable|date|after_or_equal:fecha_inicio',
        ]);

        $consulta = Bitacora::query()
            ->whereNotNull('hora_salida');

        // USUARIO NORMAL
        if ($usuario->rol !== 'admin') {
            $consulta->whereHas('cuarto', function ($query) use ($usuario) {
                $query->where('motel_id', $usuario->motel_id);
            });
        }

        // ADMIN PUEDE FILTRAR POR MOTEL
        if (
            $usuario->rol === 'admin' &&
            !empty($validado['motel_id'])
        ) {
            $consulta->whereHas('cuarto', function ($query) use ($validado) {
                $query->where('motel_id', $validado['motel_id']);
            });
        }

        // FECHA INICIAL
        if (!empty($validado['fecha_inicio'])) {
            $consulta->whereDate(
                'hora_salida',
                '>=',
                $validado['fecha_inicio']
            );
        }

        // FECHA FINAL
        if (!empty($validado['fecha_fin'])) {
            $consulta->whereDate(
                'hora_salida',
                '<=',
                $validado['fecha_fin']
            );
        }

        // RESUMEN GENERAL
        $servicios = (clone $consulta)->count();

        $ingresos = (clone $consulta)->sum('total');

        // RESUMEN POR MOTEL
        $registros = (clone $consulta)
            ->with('cuarto.moteles')
            ->get();

        $porMotel = $registros
            ->groupBy(function ($registro) {
                return $registro->cuarto->motel_id;
            })
            ->map(function ($registrosMotel) {

                $motel =
                    $registrosMotel
                        ->first()
                        ->cuarto
                        ->moteles;

                return [
                    'motel_id' => $motel->id,
                    'motel' => $motel->nombre,

                    'servicios' =>
                        $registrosMotel->count(),

                    'ingresos' => round(
                        $registrosMotel->sum('total'),
                        2
                    ),
                ];
            })
            ->values();

        return ResponseHelpers::success([
            'servicios' => $servicios,
            'ingresos' => round($ingresos, 2),
            'moteles' => $porMotel,
        ], 'Resumen obtenido correctamente');
    }

    // GET /api/reporte-detallado
    public function reporteDetallado(Request $request)
    {
        $usuario = $request->user();

        $validado = $request->validate([
            'motel_id' => 'nullable|integer|exists:moteles,id',
            'fecha_inicio' => 'required|date',
            'fecha_fin' => 'required|date|after_or_equal:fecha_inicio',
        ]);

        $consulta = Bitacora::query()
            ->with([
                'cuarto.moteles',
                'usuario',
            ])
            ->whereNotNull('hora_salida');

        // USUARIO NORMAL
        if ($usuario->rol !== 'admin') {
            $consulta->whereHas('cuarto', function ($query) use ($usuario) {
                $query->where('motel_id', $usuario->motel_id);
            });
        }

        // ADMIN PUEDE FILTRAR POR MOTEL
        if (
            $usuario->rol === 'admin' &&
            !empty($validado['motel_id'])
        ) {
            $consulta->whereHas('cuarto', function ($query) use ($validado) {
                $query->where('motel_id', $validado['motel_id']);
            });
        }

        // FECHA INICIAL
        $consulta->whereDate(
            'hora_salida',
            '>=',
            $validado['fecha_inicio']
        );

        // FECHA FINAL
        $consulta->whereDate(
            'hora_salida',
            '<=',
            $validado['fecha_fin']
        );

        // TRAER TODOS LOS SERVICIOS
        // NO usamos paginate(20)
        $registros = $consulta
            ->orderBy('hora_entrada')
            ->get();

        // CALCULAR DURACIÓN
        $registros->transform(function ($registro) {

            $segundosTranscurridos = $registro->hora_entrada
                ->diffInSeconds($registro->hora_salida);

            $registro->minutos_transcurridos = intdiv(
                $segundosTranscurridos,
                60
            );

            return $registro;
        });

        // AGRUPAR POR MOTEL
        $porMotel = $registros
            ->groupBy(function ($registro) {
                return $registro->cuarto->motel_id;
            })
            ->map(function ($registrosMotel) {

                $motel =
                    $registrosMotel
                        ->first()
                        ->cuarto
                        ->moteles;

                return [
                    'motel_id' => $motel->id,

                    'motel' => $motel->nombre,

                    'servicios' => $registrosMotel
                        ->map(function ($registro) {

                            return [
                                'id' => $registro->id,

                                'cuarto' => [
                                    'id' =>
                                        $registro->cuarto->id,

                                    'numero' =>
                                        $registro->cuarto->numero,
                                ],

                                'hora_entrada' =>
                                    $registro->hora_entrada,

                                'hora_salida' =>
                                    $registro->hora_salida,

                                'minutos_transcurridos' =>
                                    $registro->minutos_transcurridos,

                                'total' =>
                                    $registro->total,
                            ];
                        })
                        ->values()
                        ->all(),

                    'total_motel' => round(
                        $registrosMotel->sum('total'),
                        2
                    ),
                ];
            })
            ->values();

        // RESPUESTA FINAL PARA EL PDF
        return ResponseHelpers::success([
            'fecha_inicio' =>
                $validado['fecha_inicio'],

            'fecha_fin' =>
                $validado['fecha_fin'],

            'moteles' =>
                $porMotel,

            'servicios_total' =>
                $registros->count(),

            'total_general' =>
                round(
                    $registros->sum('total'),
                    2
                ),
        ], 'Reporte detallado obtenido correctamente');
    }
}
