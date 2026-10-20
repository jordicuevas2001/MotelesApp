<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bitacora', function (Blueprint $table) {
            $table->foreignId('turno_cobro_id')
                ->nullable()
                ->after('usuario_id')
                ->constrained('turnos')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('bitacora', function (Blueprint $table) {
            $table->dropConstrainedForeignId('turno_cobro_id');
        });
    }
};
