<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Cuartos extends Model
{
    protected $table = 'cuartos';
    protected $primaryKey = 'id';
    protected $fillable = [
        'id',
        'motel_id',
        'numero',
        'ocupado',
    ];

    public function moteles()
    {
        return $this->belongsTo(Moteles::class, 'motel_id', 'id');
    }

    public function registroActivo()
    {
        return $this->hasOne(Bitacora::class, 'cuarto_id')->whereNull('hora_salida');
    }
}
