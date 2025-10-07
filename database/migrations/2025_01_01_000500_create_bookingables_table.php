<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('bookingables', function (Blueprint $table) {
            $table->unsignedBigInteger('booking_id');
            $table->morphs('bookingable'); // создаст bookingable_id и bookingable_type
            $table->primary(['booking_id', 'bookingable_id', 'bookingable_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookingables');
    }
};
