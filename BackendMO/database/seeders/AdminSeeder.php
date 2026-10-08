<?php

namespace Database\Seeders;

use App\Models\Usuarios;
use Illuminate\Database\Seeder;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        Usuarios::updateOrCreate(
            [
                'email' => 'moteladministrador@gmail.com',
            ],
            [
                'motel_id' => null,
                'name' => 'Administrador',
                'password' => 'administrador123',
                'rol' => 'admin',
            ]
        );
    }
}
