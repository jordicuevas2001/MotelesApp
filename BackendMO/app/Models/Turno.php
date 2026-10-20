<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Turno extends Model
{
    protected $table = 'turnos';

    protected $fillable = [
        'usuario_id',
        'motel_id',
        'fecha_inicio',
        'fecha_cierre',
        'estado',
        'total_cobrado',
        'cantidad_servicios',
    ];

    protected function casts(): array
    {
        return [
            'fecha_inicio' => 'datetime',
            'fecha_cierre' => 'datetime',
            'total_cobrado' => 'decimal:2',
            'cantidad_servicios' => 'integer',
        ];
    }

    public function motel(): BelongsTo
    {
        return $this->belongsTo(Moteles::class, 'motel_id');
    }

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(Usuarios::class, 'usuario_id');
    }

    public function cobros(): HasMany
    {
        return $this->hasMany(
            Bitacora::class,
            'turno_cobro_id'
        );
    }

    public function estaAbierto(): bool
    {
        return $this->estado === 'abierto';
    }
}
