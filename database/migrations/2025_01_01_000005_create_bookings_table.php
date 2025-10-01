<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateBookingsTable extends Migration {
    public function up() {
        Schema::create('bookings', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('company_id')->index();
            $table->unsignedBigInteger('resource_id')->index();
            $table->unsignedBigInteger('timetable_id')->nullable();
            $table->boolean('is_group_booking')->default(false);
            $table->dateTime('start')->index();
            $table->dateTime('end')->index();
            $table->enum('status', [
                'creating','created','pending_confirmation','awaiting_payment',
                'confirmed','cancelled_by_client','cancelled_by_admin','rejected'
            ])->default('creating');
            $table->string('reason',255)->nullable();
            $table->json('meta')->nullable();
            $table->unsignedInteger('participants_count')->default(0);
            $table->timestamps();

            $table->index(['resource_id','start','end']);
        });
    }
    public function down() { Schema::dropIfExists('bookings'); }
}
