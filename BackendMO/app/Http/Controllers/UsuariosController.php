<?php

namespace App\Http\Controllers;

use App\Helpers\ResponseHelpers;
use App\Models\Usuarios;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;

class UsuariosController extends Controller
{
    // Obtener todos los usuarios
    public function obtenerUsuarios()
    {
        $usuarios = Usuarios::with('motel')->get();

        return ResponseHelpers::success(
            $usuarios,
            'Usuarios obtenidos correctamente'
        );
    }

    // Crear usuario
   public function crearUsuario(Request $request)
{
    $validator = Validator::make($request->all(), [
        'motel_id' => 'nullable|exists:moteles,id',
        'name' => 'required|string|max:255',
        'email' => 'required|email|max:255|unique:usuarios,email',
        'password' => 'required|string|min:8',
        'rol' => 'required|string|in:admin,usuario',
    ]);

    if ($validator->fails()) {
        return ResponseHelpers::error(
            $validator->errors()->first(),
            400
        );
    }

    if (
        $request->input('rol') === 'usuario' &&
        !$request->filled('motel_id')
    ) {
        return ResponseHelpers::error(
            'El usuario debe tener un motel asignado',
            400
        );
    }

    $usuario = new Usuarios();

    $usuario->motel_id = $request->input('motel_id');
    $usuario->name = $request->input('name');
    $usuario->email = $request->input('email');
    $usuario->password = $request->input('password');
    $usuario->rol = $request->input('rol');

    if ($usuario->save()) {
        return ResponseHelpers::success(
            $usuario,
            'Usuario creado exitosamente',
            201
        );
    }

    return ResponseHelpers::error(
        'Error al crear usuario',
        500
    );
}

    // Login
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return ResponseHelpers::error(
                $validator->errors()->first(),
                400
            );
        }

        $usuario = Usuarios::with('motel')
            ->where('email', $request->input('email'))
            ->first();

        if (
            !$usuario ||
            !Hash::check(
                $request->input('password'),
                $usuario->password
            )
        ) {
            return ResponseHelpers::error(
                'Correo o contraseña incorrectos',
                401
            );
        }

        // Eliminar tokens anteriores
        $usuario->tokens()->delete();

        // Crear nuevo token
        $token = $usuario->createToken('flutter')->plainTextToken;

        return ResponseHelpers::success(
            [
                'token' => $token,

                'usuario' => [
                    'id' => $usuario->id,
                    'name' => $usuario->name,
                    'email' => $usuario->email,
                    'rol' => $usuario->rol,
                    'motel_id' => $usuario->motel_id,
                    'motel' => $usuario->motel,
                ],
            ],
            'Login correcto'
        );
    }

    // Eliminar usuario
    public function eliminarUsuario($id)
    {
        $usuario = Usuarios::findOrFail($id);

        $usuario->delete();

        return ResponseHelpers::success(
            $usuario,
            'Usuario eliminado correctamente'
        );
    }

    // Actualizar usuario
    public function actualizarUsuario(Request $request, $id)
    {
        $usuario = Usuarios::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'motel_id' => 'required|exists:moteles,id',
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:usuarios,email,' . $id,
            'password' => 'nullable|string|min:8',
            'rol' => 'required|string|in:admin,usuario',
        ]);

        if ($validator->fails()) {
            return ResponseHelpers::error(
                $validator->errors()->first(),
                400
            );
        }

        $usuario->motel_id = $request->input('motel_id');
        $usuario->name = $request->input('name');
        $usuario->email = $request->input('email');
        $usuario->rol = $request->input('rol');

        if ($request->filled('password')) {
            $usuario->password = $request->input('password');
        }

        if ($usuario->save()) {
            return ResponseHelpers::success(
                $usuario,
                'Usuario actualizado exitosamente',
                200
            );
        }

        return ResponseHelpers::error(
            'Error al actualizar usuario',
            500
        );
    }

    // Ver usuario
    public function verUsuario($id)
    {
        $usuario = Usuarios::with('motel')->findOrFail($id);

        $usuarioFormateado = [
            'id' => $usuario->id,
            'motel_id' => $usuario->motel_id,
            'motel' => $usuario->motel,
            'name' => $usuario->name,
            'email' => $usuario->email,
            'rol' => $usuario->rol,
        ];

        return ResponseHelpers::success(
            $usuarioFormateado,
            'Detalles del usuario obtenidos correctamente'
        );
    }
}
