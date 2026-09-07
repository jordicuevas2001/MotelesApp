<?php
namespace App\Http\Controllers;
use App\Helpers\ResponseHelpers;
use App\Http\Controllers\Controller;
use App\Models\Moteles;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
class MotelesController extends Controller
{
//obtener los moteles

    public function moteles()
    {
        $moteles = Moteles::all();
        return ResponseHelpers::success($moteles,'Moteles obtenidos correctamente');
    }

    //crear motel
    public function crearMotel(Request $request)
    {
         $validator = Validator::make($request->all(), [
            'nombre' => 'required|string|max:255',
        ]);

        if ($validator->fails()) {
            return ResponseHelpers::error($validator->errors()->first(), 400);
        }

        $motel = new Moteles();
        $motel->nombre = $request->input('nombre');

        if ($motel->save()) {
            return ResponseHelpers::success($motel, 'Motel creado exitosamente', 201);
        } else {
            return ResponseHelpers::error('Error al crear motel', 500);
        }

    }

    //eliminar motel
      public function EliminarMotel($id)
    {
        $motel = Moteles::findOrFail($id);
        $motel->delete();

        return ResponseHelpers::success($motel, 'Motel eliminado correctamente');
    }

    //actualizar motel
    public function actualizarMotel(Request $request, $id){
        $validator = Validator::make($request->all(), [
            'nombre' => 'required|string|max:255',
        ]);

        if ($validator->fails()) {
            return ResponseHelpers::error($validator->errors()->first(), 400);
        }

        $motel = Moteles::findOrFail($id);
        $motel->nombre = $request->input('nombre');

        if ($motel->save()) {
            return ResponseHelpers::success($motel, 'Motel actualizado exitosamente', 200);
        } else {
            return ResponseHelpers::error('Error al actualizar motel', 500);
        }
    }

      //Ver Motel
    public function verMotel($id)
    {
        $motel = Moteles::find($id);
        $motelFormateado = [
            'id' => $motel->id,
            'nombre' => $motel->nombre
        ];
        return ResponseHelpers::success($motelFormateado, "Detalles del motel obtenidos correctamente");
    }
}


