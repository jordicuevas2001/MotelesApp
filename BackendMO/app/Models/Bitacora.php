<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Bitacora extends Model
{
    protected $table = 'bitacora';

    protected $fillable = [
        'cuarto_id',
        'usuario_id',
        'hora_entrada',
        'hora_salida',
        'total',
        'observaciones',
    ];

    protected $casts = [
        'hora_entrada' => 'datetime',
        'hora_salida' => 'datetime',
        'total' => 'decimal:2',
    ];

    public function cuarto(): BelongsTo
    {
        return $this->belongsTo(Cuartos::class, 'cuarto_id');
    }

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(User::class, 'usuario_id');
    }

    /**
     * Calcula el cobro según las franjas configuradas en config/tarifas.php
     * para el motel al que pertenece el cuarto de este registro.
     */
    public function calcularCobro(int $minutos): float
    {
        $motelId = $this->cuarto->motel_id;
        $config = config("tarifas.moteles.$motelId");

        if (!$config) {
            throw new \RuntimeException("No hay tarifas configuradas para el motel $motelId");
        }

        foreach ($config['franjas'] as $franja) {
            if ($minutos <= $franja['horas'] * 60) {
                return (float) $franja['precio'];
            }
        }

        $ultima = end($config['franjas']);
        $minutosExtra = $minutos - ($ultima['horas'] * 60);
        $horasExtra = (int) ceil($minutosExtra / 60);

        return (float) $ultima['precio'] + ($horasExtra * $config['precio_hora_extra']);
    }
}
