<?php
use App\Http\Controllers\MotelesController;
use App\Http\Controllers\CuartosController;
use App\Http\Controllers\BitacoraController;
use App\Http\Controllers\UsuariosController;
use Illuminate\Support\Facades\Route;


    //ruta publica para realizar el login

    Route::post('/login', [UsuariosController::class, 'login']);


    //ruta de autenticacion protegida

    Route::middleware('auth:sanctum')->group(function () {

    //cuartos
    // Las puede utilizar admin y usuario

    Route::get('/cuartos', [CuartosController::class, 'cuartos']);

    Route::post('/agregarcuarto', [CuartosController::class, 'crearCuarto']);

    Route::put(
        '/actualizarcuarto/{id}',
        [CuartosController::class, 'actualizarCuarto']
    );

    Route::delete(
        '/eliminarcuarto/{id}',
        [CuartosController::class, 'eliminarCuarto']
    );

    Route::get(
        '/vercuarto/{id}',
        [CuartosController::class, 'verCuarto']
    );


    //bitacora
    // Las puede utilizar admin y usuario

    Route::post(
        '/cuartos/{id}/entrada',
        [BitacoraController::class, 'registrarEntrada']
    );

    Route::get(
        '/cuartos/{id}/cobro',
        [BitacoraController::class, 'previewCobro']
    );

    Route::post('/cuartos/{id}/salida',[BitacoraController::class, 'registrarSalida']);

    Route::get('/historial',[BitacoraController::class, 'historial']);
    Route::get('/resumen', [BitacoraController::class, 'resumen']);
    Route::get('/reporte-detallado',[BitacoraController::class, 'reporteDetallado']
    );

        //solo permisos de admin
    Route::middleware('rol:admin')->group(function () {

       //rutas que pueden usar los usuarios

        Route::get(
            '/obtenerusuarios',
            [UsuariosController::class, 'obtenerUsuarios']
        );

        Route::get(
            '/verusuario/{id}',
            [UsuariosController::class, 'verUsuario']
        );

        Route::post(
            '/crearusuarios',
            [UsuariosController::class, 'crearUsuario']
        );

        Route::put(
            '/actualizarusuario/{id}',
            [UsuariosController::class, 'actualizarUsuario']
        );

        Route::delete(
            '/eliminarusuario/{id}',
            [UsuariosController::class, 'eliminarUsuario']
        );


      //para los moteles

        Route::get(
            '/moteles',
            [MotelesController::class, 'moteles']
        );

        Route::get(
            '/vermotel/{id}',
            [MotelesController::class, 'verMotel']
        );

        Route::post(
            '/agregarmotel',
            [MotelesController::class, 'crearMotel']
        );

        Route::put(
            '/actualizarmotel/{id}',
            [MotelesController::class, 'actualizarMotel']
        );

        Route::delete(
            '/eliminarmotel/{id}',
            [MotelesController::class, 'EliminarMotel']
        );
    });
});
