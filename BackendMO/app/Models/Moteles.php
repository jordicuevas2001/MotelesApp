<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Moteles extends Model
{
 protected $table = 'Moteles';

    protected $primaryKey= 'id';

    protected $fillable= [
        'nombre',
    ];

    protected $keyType = 'int';
    public $timestamps = true;
}


