<?php

namespace App\Http\Controllers;

use App\Helpers\ResponseHelpers;
use App\Models\Bitacora;
use App\Models\Cuartos;
use Illuminate\Http\Request;

class BitacoraController extends Controller
{
    // POST /api/cuartos/{id}/entrada
    public function registrarEntrada(Request $request, $id)
    {
        $cuarto = Cuartos::findOrFail($id);

        if ($cuarto->ocupado) {
            return ResponseHelpers::error('El cuarto ya está ocupado', 422);
        }

        $registro = Bitacora::create([
            'cuarto_id' => $cuarto->id,
            'usuario_id' => $request->input('usuario_id'), // nullable por ahora, sin login aún
            'hora_entrada' => now(),
        ]);

        $cuarto->ocupado = true;
        $cuarto->save();

        return ResponseHelpers::success([
            'cuarto' => $cuarto,
            'registro' => $registro,
        ], 'Entrada registrada correctamente', 201);
    }

    // GET /api/cuartos/{id}/cobro -> preview sin cerrar, para mostrar el modal
    public function previewCobro($id)
    {
        $cuarto = Cuartos::findOrFail($id);

        $registro = Bitacora::where('cuarto_id', $cuarto->id)
            ->whereNull('hora_salida')
            ->with('cuarto')
            ->first();

        if (!$registro) {
            return ResponseHelpers::error('El cuarto no tiene un registro activo', 422);
        }

        $minutos = (int) $registro->hora_entrada->diffInMinutes(now());

        return ResponseHelpers::success([
            'registro' => $registro,
            'minutos_transcurridos' => $minutos,
            'total' => $registro->calcularCobro($minutos),
        ], 'Cobro calculado correctamente');
    }

    // POST /api/cuartos/{id}/salida -> cierra y cobra
    public function registrarSalida(Request $request, $id)
    {
        $cuarto = Cuartos::findOrFail($id);

        $registro = Bitacora::where('cuarto_id', $cuarto->id)
            ->whereNull('hora_salida')
            ->with('cuarto')
            ->first();

        if (!$registro) {
            return ResponseHelpers::error('El cuarto no tiene un registro activo', 422);
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

        return ResponseHelpers::success([
            'registro' => $registro,
            'total' => $total,
        ], 'Salida registrada correctamente');
    }

    // GET /api/historial?motel_id=1
    public function historial(Request $request)
    {
        $registros = Bitacora::with('cuarto.moteles')
            ->whereNotNull('hora_salida')
            ->when($request->query('motel_id'), function ($q, $motelId) {
                $q->whereHas('cuarto', fn ($q) => $q->where('motel_id', $motelId));
            })
            ->orderByDesc('hora_salida')
            ->paginate(20);

        return ResponseHelpers::success($registros, 'Historial obtenido correctamente');
    }
}
