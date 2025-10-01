<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateResourcesTable extends Migration {
    public function up() {
        Schema::create('resources', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('company_id')->index();
            $table->unsignedBigInteger('resource_type_id')->index();
            $table->json('options')->nullable();
            $table->json('payload')->nullable();
            $table->json('resource_config')->nullable();
            $table->timestamps();

            $table->foreign('resource_type_id')->references('id')->on('resource_types')->onDelete('cascade');
        });
    }
    public function down() { Schema::dropIfExists('resources'); }
}
