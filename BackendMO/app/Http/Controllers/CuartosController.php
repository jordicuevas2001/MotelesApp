<?php
namespace App\Http\Controllers;
use App\Helpers\ResponseHelpers;
use App\Models\Cuartos;
use Illuminate\Http\Request;

class CuartosController extends Controller
{
    // obtener los cuartos
    public function cuartos()
    {
        $cuartos = Cuartos::with([
            'moteles',
            'registroActivo',
        ])->get();

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

        return ResponseHelpers::success($cuartosFormateados, 'Cuartos obtenidos correctamente');
    }
    // crear cuartos
    public function crearCuarto(Request $request)
    {
        $validado = $request->validate([
            'motel_id' => 'required|exists:moteles,id',
            'numero'   => 'required|integer',
            'ocupado'  => 'boolean',

        ]);

        $cuarto = new Cuartos();
        $cuarto->motel_id = $validado['motel_id'];
        $cuarto->numero = $validado['numero'];
        $cuarto->ocupado = $validado['ocupado'] ?? false;

        if ($cuarto->save()) {
            return ResponseHelpers::success($cuarto, 'Cuarto creado exitosamente', 201);
        } else {
            return ResponseHelpers::error('Error al crear cuarto', 500);
        }
    }

    // actualizar cuartos
    public function actualizarCuarto(Request $request, $id)
    {
        $cuarto = Cuartos::findOrFail($id);

        $validado = $request->validate([
            'numero'  => 'sometimes|required|integer',
            'ocupado' => 'sometimes|boolean',
        ]);

        $cuarto->fill($validado);

        if ($cuarto->save()) {
            return ResponseHelpers::success($cuarto, 'Cuarto actualizado exitosamente');
        } else {
            return ResponseHelpers::error('Error al actualizar cuarto', 500);
        }
    }

    // eliminar cuarto
    public function eliminarCuarto($id)
    {
        $cuarto = Cuartos::findOrFail($id);
        $cuarto->delete();

        return ResponseHelpers::success($cuarto, 'Cuarto eliminado correctamente');
    }

    // ver cuarto
    public function verCuarto($id)
    {
        $cuarto = Cuartos::findOrFail($id);
        $cuartoFormateado = [
            'id' => $cuarto->id,
            'motel_id' => $cuarto->motel_id,
            'numero' => $cuarto->numero,
            'ocupado' => $cuarto->ocupado,
        ];

        return ResponseHelpers::success($cuartoFormateado, 'Detalles del cuarto obtenidos correctamente');
    }
}
