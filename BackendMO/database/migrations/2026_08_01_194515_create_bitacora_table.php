<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bitacora', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cuarto_id')->constrained('cuartos')->cascadeOnDelete();
            $table->dateTime('hora_entrada');
            $table->dateTime('hora_salida')->nullable();
            $table->foreignId('usuario_id')->nullable()->constrained('usuarios')->nullOnDelete();
            $table->decimal('total', 8, 2)->nullable();
            $table->string('observaciones')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void

    {
        Schema::dropIfExists('bitacora');
    }
};
