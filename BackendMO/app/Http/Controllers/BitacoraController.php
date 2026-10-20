<?php
namespace App\Http\Controllers;
use App\Events\CuartoActualizado;
use App\Helpers\ResponseHelpers;
use App\Models\Bitacora;
use App\Models\Cuartos;
use App\Models\Turno;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BitacoraController extends Controller
{
    // ENTRADA
    // POST /api/cuartos/{id}/entrada
    public function registrarEntrada(Request $request, $id)
    {
        $usuario = $request->user();

        if (!$usuario->motel_id) {
            return ResponseHelpers::error(
                'El usuario no tiene un motel asignado.',
                422
            );
        }

        // El empleado debe iniciar turno antes de registrar entradas.
        $turno = Turno::where('usuario_id', $usuario->id)
            ->where('motel_id', $usuario->motel_id)
            ->where('estado', 'abierto')
            ->latest('id')
            ->first();

        if (!$turno) {
            return ResponseHelpers::error(
                'Debes iniciar tu turno antes de registrar entradas.',
                422
            );
        }

     $cuarto = Cuartos::where('id', $id)
    ->where('motel_id', $usuario->motel_id)
    ->firstOrFail();

try {
    [$registro, $cuarto] = DB::transaction(function () use ($cuarto, $usuario) {
        // Bloquear el cuarto mientras se registra la entrada.
        $cuartoBloqueado = Cuartos::where('id', $cuarto->id)
            ->lockForUpdate()
            ->firstOrFail();

        if ($cuartoBloqueado->ocupado) {
            throw new \DomainException('El cuarto ya está ocupado.');
        }

        $registro = Bitacora::create([
            'cuarto_id' => $cuartoBloqueado->id,
            'usuario_id' => $usuario->id,
            'hora_entrada' => now(),
        ]);

        $cuartoBloqueado->ocupado = true;
        $cuartoBloqueado->save();

        return [$registro, $cuartoBloqueado];
    });
} catch (\DomainException $e) {
    return ResponseHelpers::error($e->getMessage(), 422);
}

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

    // PREVISUALIZAR COBRO
    // GET /api/cuartos/{id}/cobro

    public function previewCobro(Request $request, $id)
    {
        $usuario = $request->user();

        $cuarto = Cuartos::where('id', $id)
            ->where('motel_id', $usuario->motel_id)
            ->firstOrFail();

        $registro = Bitacora::where('cuarto_id', $cuarto->id)
            ->whereNull('hora_salida')
            ->with('cuarto')
            ->first();

        if (!$registro) {
            return ResponseHelpers::error(
                'El cuarto no tiene un registro activo.',
                422
            );
        }

        $minutos = (int) $registro->hora_entrada
            ->diffInMinutes(now());

        return ResponseHelpers::success([
            'registro' => $registro,
            'minutos_transcurridos' => $minutos,
            'total' => $registro->calcularCobro($minutos),
        ], 'Cobro calculado correctamente');
    }

    // SALIDA Y COBRO
    // POST /api/cuartos/{id}/salida
    public function registrarSalida(Request $request, $id)
    {
        $usuario = $request->user();

        if (!$usuario->motel_id) {
            return ResponseHelpers::error(
                'El usuario no tiene un motel asignado.',
                422
            );
        }

        $cuarto = Cuartos::where('id', $id)
            ->where('motel_id', $usuario->motel_id)
            ->firstOrFail();

        try {
            $resultado = DB::transaction(function () use (
                $cuarto,
                $usuario,
                $request
            ) {
                // Bloquear el cuarto mientras se procesa el cobro.
                $cuartoBloqueado = Cuartos::where(
                    'id',
                    $cuarto->id
                )->lockForUpdate()->firstOrFail();

                // Obtener y bloquear el registro activo.
                $registro = Bitacora::where(
                    'cuarto_id',
                    $cuartoBloqueado->id
                )
                    ->whereNull('hora_salida')
                    ->lockForUpdate()
                    ->first();

                if (!$registro) {
                    throw new \DomainException(
                        'El cuarto no tiene un registro activo.'
                    );
                }

                // Buscar el turno abierto del empleado.
                $turno = Turno::where(
                    'usuario_id',
                    $usuario->id
                )
                    ->where('motel_id', $usuario->motel_id)
                    ->where('estado', 'abierto')
                    ->latest('id')
                    ->lockForUpdate()
                    ->first();

                if (!$turno) {
                    throw new \DomainException(
                        'Debes iniciar tu turno antes de cobrar.'
                    );
                }

                $horaSalida = now();

                $minutos = (int) $registro->hora_entrada
                    ->diffInMinutes($horaSalida);

                $total = $registro->calcularCobro($minutos);

                // Asociar el cobro al turno que lo está realizando.
                $registro->turno_cobro_id = $turno->id;
                $registro->hora_salida = $horaSalida;
                $registro->total = $total;
                $registro->observaciones =
                    $request->input('observaciones');

                $registro->save();

                // Liberar el cuarto.
                $cuartoBloqueado->ocupado = false;
                $cuartoBloqueado->save();

                $registro->setRelation(
                    'cuarto',
                    $cuartoBloqueado
                );

                // Actualizar los acumulados del turno.
                $turno->total_cobrado =
                    (float) $turno->total_cobrado
                    + (float) $total;

                $turno->cantidad_servicios =
                    (int) $turno->cantidad_servicios + 1;

                $turno->save();

                return [
                    'registro' => $registro,
                    'total' => $total,
                    'minutos_transcurridos' => $minutos,
                    'motel_id' => (int) $cuartoBloqueado->motel_id,
                    'cuarto_id' => (int) $cuartoBloqueado->id,
                ];
            });
        } catch (\DomainException $e) {
            return ResponseHelpers::error(
                $e->getMessage(),
                422
            );
        }

        broadcast(new CuartoActualizado(
            $resultado['motel_id'],
            $resultado['cuarto_id'],
            'salida'
        ));

        return ResponseHelpers::success([
            'registro' => $resultado['registro'],
            'total' => $resultado['total'],
            'minutos_transcurridos' =>
                $resultado['minutos_transcurridos'],
        ], 'Salida registrada correctamente');
    }


 //POST /api/turnos/iniciar

public function iniciarTurno(Request $request)
{
    $usuario = $request->user();

    if (!$usuario->motel_id) {
        return ResponseHelpers::error(
            'El usuario no tiene un motel asignado.',
            422
        );
    }

    $turno = DB::transaction(function () use ($usuario) {

        // Turnos abiertos del motel (bloqueados mientras se decide).
        $abiertos = Turno::where('motel_id', $usuario->motel_id)
            ->where('estado', 'abierto')
            ->lockForUpdate()
            ->get();

        // Ya tiene un turno abierto.
        if ($abiertos->contains('usuario_id', $usuario->id)) {
            return null;
        }

        // Máximo 2 turnos abiertos al mismo tiempo por motel.
        if ($abiertos->count() >= 2) {
            return null;
        }

        // Cada inicio crea un turno nuevo para conservar su historial.
        return Turno::create([
            'usuario_id' => $usuario->id,
            'motel_id' => $usuario->motel_id,
            'fecha_inicio' => now(),
            'fecha_cierre' => null,
            'estado' => 'abierto',
            'total_cobrado' => 0,
            'cantidad_servicios' => 0,
        ]);
    });

    if (!$turno) {
        return ResponseHelpers::error(
            'Ya tienes un turno abierto o no hay turnos disponibles.',
            422
        );
    }

    return ResponseHelpers::success(
        ['turno' => $turno],
        'Turno iniciado correctamente',
        201
    );
}

    // CONSULTAR TURNO ACTUAL
    // GET /api/turno/actual
    public function turnoActual(Request $request)
    {
        $usuario = $request->user();

        $turno = Turno::where('usuario_id', $usuario->id)
            ->where('motel_id', $usuario->motel_id)
            ->where('estado', 'abierto')
            ->latest('id')
            ->first();

        return ResponseHelpers::success([
            'turno' => $turno,
        ], $turno
            ? 'Turno abierto encontrado'
            : 'No tienes un turno abierto');
    }

    // ============================================================
    // CERRAR TURNO
    // POST /api/turno/cerrar
    // ============================================================

    public function cerrarTurno(Request $request)
    {
        $usuario = $request->user();

        $turno = DB::transaction(function () use ($usuario) {
            $turno = Turno::where(
                'usuario_id',
                $usuario->id
            )
                ->where('motel_id', $usuario->motel_id)
                ->where('estado', 'abierto')
                ->latest('id')
                ->lockForUpdate()
                ->first();

            if (!$turno) {
                return null;
            }

            // Recalcular a partir de los cobros guardados.
            $cobros = Bitacora::where(
                'turno_cobro_id',
                $turno->id
            )->whereNotNull('hora_salida');

            $turno->total_cobrado = $cobros->sum('total');
            $turno->cantidad_servicios = $cobros->count();
            $turno->fecha_cierre = now();
            $turno->estado = 'cerrado';
            $turno->save();

            return $turno;
        });

        if (!$turno) {
            return ResponseHelpers::error(
                'No tienes un turno abierto para cerrar.',
                422
            );
        }

        return ResponseHelpers::success([
            'turno' => $turno,
        ], 'Turno cerrado correctamente');
    }

    // ============================================================
    // REPORTE DEL TURNO CERRADO
    // GET /api/turno/{id}/reporte
    // ============================================================

    public function reporteTurno(Request $request, $id)
    {
        $usuario = $request->user();

        $turno = Turno::where('id', $id)
            ->where('usuario_id', $usuario->id)
            ->where('motel_id', $usuario->motel_id)
            ->where('estado', 'cerrado')
            ->first();

        if (!$turno) {
            return ResponseHelpers::error(
                'El turno no existe, no te pertenece o sigue abierto.',
                404
            );
        }

        $cobros = Bitacora::with([
            'cuarto.moteles',
            'usuario',
        ])
            ->where('turno_cobro_id', $turno->id)
            ->whereNotNull('hora_salida')
            ->orderBy('hora_salida')
            ->get();

        return ResponseHelpers::success([
            'turno' => $turno,
            'servicios' => $cobros,
            'total' => round($cobros->sum('total'), 2),
            'cantidad_servicios' => $cobros->count(),
        ], 'Reporte del turno obtenido correctamente');
    }

    // ============================================================
    // HISTORIAL
    // GET /api/historial
    // ============================================================

    public function historial(Request $request)
    {
        $usuario = $request->user();

        $validado = $request->validate([
            'motel_id' => 'nullable|integer|exists:moteles,id',
            'fecha_inicio' => 'nullable|date',
            'fecha_fin' => 'nullable|date|after_or_equal:fecha_inicio',
        ]);

        $turnoAbierto = null;

        if ($usuario->rol !== 'admin') {
            $turnoAbierto = Turno::where(
                'usuario_id',
                $usuario->id
            )
                ->where('motel_id', $usuario->motel_id)
                ->where('estado', 'abierto')
                ->latest('id')
                ->first();
        }

        $registros = Bitacora::with([
            'cuarto.moteles',
            'usuario',
        ])
            ->whereNotNull('hora_salida')

            // Empleados: solo los cobros de su turno actual.
            // Sin turno abierto, no se muestran cobros.
            ->when(
                $usuario->rol !== 'admin',
                function ($query) use ($turnoAbierto) {
                    if (!$turnoAbierto) {
                        $query->whereRaw('1 = 0');
                    } else {
                        $query->where(
                            'turno_cobro_id',
                            $turnoAbierto->id
                        );
                    }
                }
            )

            // ADMIN: puede filtrar por motel.
            ->when(
                $usuario->rol === 'admin'
                && !empty($validado['motel_id']),
                function ($query) use ($validado) {
                    $query->whereHas(
                        'cuarto',
                        function ($q) use ($validado) {
                            $q->where(
                                'motel_id',
                                $validado['motel_id']
                            );
                        }
                    );
                }
            )

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

        $registros->getCollection()->transform(
            function ($registro) {
                $segundosTranscurridos = $registro
                    ->hora_entrada
                    ->diffInSeconds($registro->hora_salida);

                $registro->minutos_transcurridos = intdiv(
                    $segundosTranscurridos,
                    60
                );

                return $registro;
            }
        );

        return ResponseHelpers::success(
            $registros,
            'Historial obtenido correctamente'
        );
    }

    // ============================================================
    // RESUMEN
    // GET /api/resumen
    // ============================================================

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

        if ($usuario->rol !== 'admin') {
            $consulta->whereHas(
                'cuarto',
                function ($query) use ($usuario) {
                    $query->where(
                        'motel_id',
                        $usuario->motel_id
                    );
                }
            );
        }

        if (
            $usuario->rol === 'admin'
            && !empty($validado['motel_id'])
        ) {
            $consulta->whereHas(
                'cuarto',
                function ($query) use ($validado) {
                    $query->where(
                        'motel_id',
                        $validado['motel_id']
                    );
                }
            );
        }

        if (!empty($validado['fecha_inicio'])) {
            $consulta->whereDate(
                'hora_salida',
                '>=',
                $validado['fecha_inicio']
            );
        }

        if (!empty($validado['fecha_fin'])) {
            $consulta->whereDate(
                'hora_salida',
                '<=',
                $validado['fecha_fin']
            );
        }

        $servicios = (clone $consulta)->count();
        $ingresos = (clone $consulta)->sum('total');

        $registros = (clone $consulta)
            ->with('cuarto.moteles')
            ->get();

        $porMotel = $registros
            ->groupBy(function ($registro) {
                return $registro->cuarto->motel_id;
            })
            ->map(function ($registrosMotel) {
                $motel = $registrosMotel
                    ->first()
                    ->cuarto
                    ->moteles;

                return [
                    'motel_id' => $motel->id,
                    'motel' => $motel->nombre,
                    'servicios' => $registrosMotel->count(),
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

    // ============================================================
    // REPORTE DETALLADO
    // GET /api/reporte-detallado
    // ============================================================

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

        if ($usuario->rol !== 'admin') {
            $consulta->whereHas(
                'cuarto',
                function ($query) use ($usuario) {
                    $query->where(
                        'motel_id',
                        $usuario->motel_id
                    );
                }
            );
        }

        if (
            $usuario->rol === 'admin'
            && !empty($validado['motel_id'])
        ) {
            $consulta->whereHas(
                'cuarto',
                function ($query) use ($validado) {
                    $query->where(
                        'motel_id',
                        $validado['motel_id']
                    );
                }
            );
        }

        $consulta->whereDate(
            'hora_salida',
            '>=',
            $validado['fecha_inicio']
        );

        $consulta->whereDate(
            'hora_salida',
            '<=',
            $validado['fecha_fin']
        );

        $registros = $consulta
            ->orderBy('hora_entrada')
            ->get();

        $registros->transform(function ($registro) {
            $segundosTranscurridos = $registro
                ->hora_entrada
                ->diffInSeconds($registro->hora_salida);

            $registro->minutos_transcurridos = intdiv(
                $segundosTranscurridos,
                60
            );

            return $registro;
        });

        $porMotel = $registros
            ->groupBy(function ($registro) {
                return $registro->cuarto->motel_id;
            })
            ->map(function ($registrosMotel) {
                $motel = $registrosMotel
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
                                    'id' => $registro->cuarto->id,
                                    'numero' => $registro->cuarto->numero,
                                ],

                                'hora_entrada' => $registro->hora_entrada,
                                'hora_salida' => $registro->hora_salida,

                                'minutos_transcurridos' =>
                                    $registro->minutos_transcurridos,

                                'total' => $registro->total,
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

        return ResponseHelpers::success([
            'fecha_inicio' => $validado['fecha_inicio'],
            'fecha_fin' => $validado['fecha_fin'],
            'moteles' => $porMotel,
            'servicios_total' => $registros->count(),
            'total_general' => round(
                $registros->sum('total'),
                2
            ),
        ], 'Reporte detallado obtenido correctamente');
    }
}
