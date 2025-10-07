<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('company_id');
            $table->unsignedBigInteger('resource_id');
            $table->unsignedBigInteger('timetable_id')->nullable();
            $table->boolean('is_group_booking')->default(false);
            $table->dateTime('start');
            $table->dateTime('end');
            $table->enum('status', [
                'pending_confirmation',
                'confirmed',
                'cancelled_by_client',
                'cancelled_by_admin',
                'rejected',
                'rescheduled'
            ])->default('pending_confirmation');
            $table->string('reason')->nullable();
            $table->timestamps();

            $table->foreign('resource_id')->references('id')->on('resources')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
