<?php
use App\Http\Controllers\MotelesController;
use App\Http\Controllers\CuartosController;
use App\Http\Controllers\BitacoraController;
use Illuminate\Support\Facades\Route;



//api catalogo de moteles
Route::get('/moteles', [MotelesController::class, 'moteles']);
Route::post('/agregarmotel', [MotelesController::class, 'crearMotel']);
Route::delete('/eliminarmotel/{id}', [MotelesController::class, 'EliminarMotel']);
Route::put('/actualizarmotel/{id}', [MotelesController::class, 'actualizarMotel']);
Route::get('/vermotel/{id}', [MotelesController::class, 'verMotel']);

//api catalogo de cuartos
Route::get('/cuartos', [CuartosController::class, 'cuartos']);
Route::post('/agregarcuarto', [CuartosController::class, 'crearCuarto']);
Route::put('/actualizarcuarto/{id}', [CuartosController::class, 'actualizarCuarto']);
Route::delete('/eliminarcuarto/{id}', [CuartosController::class, 'EliminarCuarto']);
Route::get('/vercuarto/{id}', [CuartosController::class, 'verCuarto']);


//api para bitacora
Route::post('/cuartos/{id}/entrada', [BitacoraController::class, 'registrarEntrada']);
Route::get('/cuartos/{id}/cobro', [BitacoraController::class, 'previewCobro']);
Route::post('/cuartos/{id}/salida', [BitacoraController::class, 'registrarSalida']);
Route::get('/historial', [BitacoraController::class, 'historial']);
