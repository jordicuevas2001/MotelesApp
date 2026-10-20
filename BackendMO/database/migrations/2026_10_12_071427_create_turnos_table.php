<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('turnos', function (Blueprint $table) {
            $table->id();

            $table->foreignId('usuario_id')
                ->constrained('usuarios')
                ->restrictOnDelete();

            $table->foreignId('motel_id')
                ->constrained('moteles')
                ->restrictOnDelete();

            $table->dateTime('fecha_inicio');
            $table->dateTime('fecha_cierre')->nullable();

            $table->enum('estado', ['abierto', 'cerrado'])
                ->default('abierto');

            $table->decimal('total_cobrado', 10, 2)->default(0);
            $table->unsignedInteger('cantidad_servicios')->default(0);

            $table->timestamps();

            $table->index(['usuario_id', 'estado']);
            $table->index(['motel_id', 'fecha_inicio']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('turnos');
    }
};

