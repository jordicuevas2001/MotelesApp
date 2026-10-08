<?php

namespace App\Http\Controllers;

use App\Helpers\ResponseHelpers;
use App\Models\Cuartos;
use Illuminate\Http\Request;

class CuartosController extends Controller
{
    // Obtener solamente los cuartos del motel del usuario autenticado
    public function cuartos(Request $request)
    {
        $usuario = $request->user();

        $cuartos = Cuartos::with([
            'moteles',
            'registroActivo',
        ])
        ->where('motel_id', $usuario->motel_id)
        ->get();

        $cuartosFormateados = $cuartos->map(function ($cuarto) {
            return [
                'id' => $cuarto->id,
                'motel_id' => $cuarto->motel_id,
                'numero' => $cuarto->numero,
                'ocupado' => $cuarto->ocupado,

                'motel' => [
                    'id' => $cuarto->moteles?->id,
                    'nombre' => $cuarto->moteles?->nombre,
                ],

                'registro_activo' => $cuarto->registroActivo ? [
                    'id' => $cuarto->registroActivo->id,
                    'hora_entrada' => $cuarto->registroActivo->hora_entrada,
                ] : null,
            ];
        });

        return ResponseHelpers::success(
            $cuartosFormateados,
            'Cuartos obtenidos correctamente'
        );
    }


    // Crear cuarto en el motel del usuario autenticado
    public function crearCuarto(Request $request)
    {
        $usuario = $request->user();

        $validado = $request->validate([
            'numero'  => 'required|integer',
            'ocupado' => 'sometimes|boolean',
        ]);

        $cuarto = new Cuartos();

        // El motel NO viene de Flutter.
        // Lo obtenemos del usuario autenticado.
        $cuarto->motel_id = $usuario->motel_id;
        $cuarto->numero = $validado['numero'];
        $cuarto->ocupado = $validado['ocupado'] ?? false;

        if ($cuarto->save()) {
            return ResponseHelpers::success(
                $cuarto,
                'Cuarto creado exitosamente',
                201
            );
        }

        return ResponseHelpers::error(
            'Error al crear cuarto',
            500
        );
    }


    // Actualizar solamente un cuarto perteneciente al motel del usuario
    public function actualizarCuarto(Request $request, $id)
    {
        $usuario = $request->user();

        $cuarto = Cuartos::where('id', $id)
            ->where('motel_id', $usuario->motel_id)
            ->firstOrFail();

        $validado = $request->validate([
            'numero'  => 'sometimes|required|integer',
            'ocupado' => 'sometimes|boolean',
        ]);

        $cuarto->fill($validado);

        if ($cuarto->save()) {
            return ResponseHelpers::success(
                $cuarto,
                'Cuarto actualizado exitosamente'
            );
        }

        return ResponseHelpers::error(
            'Error al actualizar cuarto',
            500
        );
    }


    // Eliminar solamente un cuarto perteneciente al motel del usuario
    public function eliminarCuarto(Request $request, $id)
    {
        $usuario = $request->user();

        $cuarto = Cuartos::where('id', $id)
            ->where('motel_id', $usuario->motel_id)
            ->firstOrFail();

        $cuarto->delete();

        return ResponseHelpers::success(
            $cuarto,
            'Cuarto eliminado correctamente'
        );
    }


    // Ver solamente un cuarto perteneciente al motel del usuario
    public function verCuarto(Request $request, $id)
    {
        $usuario = $request->user();

        $cuarto = Cuartos::where('id', $id)
            ->where('motel_id', $usuario->motel_id)
            ->firstOrFail();

        $cuartoFormateado = [
            'id' => $cuarto->id,
            'motel_id' => $cuarto->motel_id,
            'numero' => $cuarto->numero,
            'ocupado' => $cuarto->ocupado,
        ];

        return ResponseHelpers::success(
            $cuartoFormateado,
            'Detalles del cuarto obtenidos correctamente'
        );
    }
}
