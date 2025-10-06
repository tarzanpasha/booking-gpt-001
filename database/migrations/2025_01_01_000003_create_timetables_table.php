<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('timetables', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('company_id');
            $table->foreignId('resource_id')->constrained()->cascadeOnDelete();
            $table->string('name')->nullable();
            $table->enum('type',['static','dynamic']);
            $table->json('payload')->nullable();
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('timetables');
    }
};
