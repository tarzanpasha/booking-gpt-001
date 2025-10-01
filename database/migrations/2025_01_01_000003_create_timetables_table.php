<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTimetablesTable extends Migration {
    public function up() {
        Schema::create('timetables', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('company_id')->index();
            $table->unsignedBigInteger('resource_id')->nullable()->index();
            $table->string('name')->nullable();
            $table->enum('type', ['static','dynamic'])->default('static');
            $table->json('payload')->nullable();
            $table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('timetables'); }
}
