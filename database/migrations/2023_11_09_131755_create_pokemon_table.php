<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('pokemon', function (Blueprint $table) {
            $table->id();
            $table->unsignedTinyInteger('generation');
            $table->json('name');
            $table->string('image');
            $table->string('image_shiny')->nullable();
            $table->float('height');
            $table->float('weight');
            $table->json('stats');
        });
        Schema::create('pokemon_type', function (Blueprint $table) {
            $table->foreignId('pokemon_id')->constrained('pokemon')->cascadeOnDelete();
            $table->foreignId('type_id')->constrained('types')->cascadeOnDelete();
        });
        Schema::create('evolutions', function (Blueprint $table) {
            $table->foreignId('from_id')->constrained('pokemon', 'id')->cascadeOnDelete();
            $table->foreignId('to_id')->constrained('pokemon', 'id')->cascadeOnDelete();
            $table->string('condition');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pokemon_type');
        Schema::dropIfExists('pokemon');
    }
};
