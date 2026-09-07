<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cuartos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('motel_id')->constrained('moteles')->cascadeOnDelete();
            $table->unsignedInteger('numero');
            $table->boolean('ocupado')->default(false);
            $table->timestamps();

            $table->unique(['motel_id', 'numero']); // no se repite el número dentro del mismo motel
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cuartos');
    }
};
