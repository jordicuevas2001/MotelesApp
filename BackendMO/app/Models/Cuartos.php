<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Cuartos extends Model
{
    protected $table = 'cuartos';

    protected $primaryKey = 'id';

    protected $fillable = [
        'id',
        'motel_id',
        'numero',
        'ocupado',
        'ocupacion_pendiente_desde',
        'ocupacion_pendiente_usuario_id',
    ];

    protected function casts(): array
    {
        return [
            'ocupado' => 'boolean',
            'ocupacion_pendiente_desde' => 'datetime',
        ];
    }

    public function moteles(): BelongsTo
    {
        return $this->belongsTo(
            Moteles::class,
            'motel_id',
            'id'
        );
    }

    public function registroActivo(): HasOne
    {
        return $this->hasOne(
            Bitacora::class,
            'cuarto_id'
        )->whereNull('hora_salida');
    }
}
