<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('company_id');
            $table->foreignId('resource_id')->constrained()->cascadeOnDelete();
            $table->foreignId('timetable_id')->nullable()->constrained()->nullOnDelete();
            $table->boolean('is_group_booking')->default(false);
            $table->dateTime('start');
            $table->dateTime('end');
            $table->enum('status', [
                'creating',
                'pending_confirmation',
                'confirmed',
                'awaiting_payment',
                'cancelled_by_client',
                'cancelled_by_admin',
                'rejected'
            ]);
            $table->string('reason',255)->nullable();
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('bookings');
    }
};
