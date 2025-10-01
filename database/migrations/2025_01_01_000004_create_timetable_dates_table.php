<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTimetableDatesTable extends Migration {
    public function up() {
        Schema::create('timetable_dates', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('timetable_id')->index();
            $table->date('date');
            $table->time('start')->nullable();
            $table->time('end')->nullable();
            $table->json('breaks')->nullable();
            $table->timestamps();
            $table->unique(['timetable_id','date']);
            $table->foreign('timetable_id')->references('id')->on('timetables')->onDelete('cascade');
        });
    }
    public function down() { Schema::dropIfExists('timetable_dates'); }
}
