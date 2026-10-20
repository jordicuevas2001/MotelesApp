<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\MotelesController;
use App\Http\Controllers\CuartosController;
use App\Http\Controllers\BitacoraController;
use App\Http\Controllers\UsuariosController;

// Ruta pública para iniciar sesión
Route::post('/login', [UsuariosController::class, 'login']);

// Rutas protegidas por autenticación
Route::middleware('auth:sanctum')->group(function () {

    // =========================
    // CUARTOS
    // =========================

    Route::get('/cuartos', [CuartosController::class, 'cuartos']);

    Route::post('/agregarcuarto', [CuartosController::class, 'crearCuarto']);

    Route::put('/actualizarcuarto/{id}', [CuartosController::class, 'actualizarCuarto']);

    Route::delete('/eliminarcuarto/{id}', [CuartosController::class, 'eliminarCuarto']);

    Route::get('/vercuarto/{id}', [CuartosController::class, 'verCuarto']);


    // =========================
    // BITÁCORA Y COBROS
    // =========================

    Route::post('/cuartos/{id}/entrada', [BitacoraController::class, 'registrarEntrada']);

    Route::get('/cuartos/{id}/cobro', [BitacoraController::class, 'previewCobro']);

    Route::post('/cuartos/{id}/salida', [BitacoraController::class, 'registrarSalida']);

    Route::get('/historial', [BitacoraController::class, 'historial']);

    Route::get('/resumen', [BitacoraController::class, 'resumen']);

    Route::get('/reporte-detallado', [BitacoraController::class, 'reporteDetallado']);


    // =========================
    // TURNOS
    // =========================

    // Iniciar turno del empleado
    Route::post('/turnos/iniciar', [BitacoraController::class, 'iniciarTurno']);

    // Consultar turno abierto del empleado
    Route::get('/turnos/actual', [BitacoraController::class, 'turnoActual']);

    // Cerrar turno del empleado
    Route::post('/turnos/cerrar', [BitacoraController::class, 'cerrarTurno']);

    // Consultar reporte de un turno
    Route::get('/turnos/{id}/reporte', [BitacoraController::class, 'reporteTurno']);


    // =========================
    // RUTAS EXCLUSIVAS DE ADMIN
    // =========================

    Route::middleware('rol:admin')->group(function () {

        // Usuarios
        Route::get('/obtenerusuarios', [UsuariosController::class, 'obtenerUsuarios']);

        Route::get('/verusuario/{id}', [UsuariosController::class, 'verUsuario']);

        Route::post('/crearusuarios', [UsuariosController::class, 'crearUsuario']);

        Route::put('/actualizarusuario/{id}', [UsuariosController::class, 'actualizarUsuario']);

        Route::delete('/eliminarusuario/{id}', [UsuariosController::class, 'eliminarUsuario']);


        // Moteles
        Route::get('/moteles', [MotelesController::class, 'moteles']);

        Route::get('/vermotel/{id}', [MotelesController::class, 'verMotel']);

        Route::post('/agregarmotel', [MotelesController::class, 'crearMotel']);

        Route::put('/actualizarmotel/{id}', [MotelesController::class, 'actualizarMotel']);

        Route::delete('/eliminarmotel/{id}', [MotelesController::class, 'EliminarMotel']);
    });
});
