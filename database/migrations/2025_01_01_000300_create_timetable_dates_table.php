<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('timetable_dates', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('timetable_id');
            $table->date('date');
            $table->time('start');
            $table->time('end');
            $table->json('breaks')->nullable();
            $table->timestamps();

            $table->foreign('timetable_id')->references('id')->on('timetables')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('timetable_dates');
    }
};
