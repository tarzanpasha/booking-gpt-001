<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateResourceTypesTable extends Migration {
    public function up() {
        Schema::create('resource_types', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('company_id')->index();
            $table->string('type', 63);
            $table->string('name', 127);
            $table->string('description', 255)->nullable();
            $table->json('options')->nullable();
            $table->json('resource_config')->nullable();
            $table->timestamps();
            $table->unique(['company_id','type']);
        });
    }
    public function down() { Schema::dropIfExists('resource_types'); }
}
