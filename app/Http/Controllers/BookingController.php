<?php

namespace App\Http\Controllers;

use App\Models\Resource;
use App\Models\Booking;
use App\Services\BookingService;
use Illuminate\Http\Request;
use DateTime;

class BookingController extends Controller
{
    public function store(Request $request, Resource $resource, BookingService $service)
    {
        $data = $request->validate([
            'start' => 'required|date',
            'end'   => 'required|date|after:start',
            'participants_count' => 'nullable|integer|min:1'
        ]);

        // no auth: use a placeholder participant model if none provided (you can adjust)
        $participant = (object)['id' => 0, 'email' => 'guest@example.com'];

        $booking = $service->createBooking(
            $resource,
            new DateTime($data['start']),
            new DateTime($data['end']),
            $participant,
            $data['participants_count'] ?? 1
        );

        return response()->json($booking);
    }

    public function confirm(Booking $booking, BookingService $service)
    {
        $service->confirmBooking($booking);
        return response()->json($booking);
    }

    public function cancel(Booking $booking, Request $request, BookingService $service)
    {
        $service->cancelBooking($booking, 'client', $request->input('reason'));
        return response()->json($booking);
    }

    public function reschedule(Booking $booking, Request $request, BookingService $service)
    {
        $data = $request->validate([
            'new_start' => 'required|date',
            'new_end'   => 'required|date|after:new_start',
        ]);

        $service->rescheduleBooking(
            $booking,
            new DateTime($data['new_start']),
            new DateTime($data['new_end']),
            'client'
        );

        return response()->json($booking);
    }
}
