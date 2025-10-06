<?php

namespace App\Http\Controllers;

use App\Models\Resource;
use App\Models\Booking;
use App\Services\BookingService;
use Illuminate\Http\Request;
use Carbon\Carbon;

class BookingController extends Controller
{
    protected BookingService $service;

    public function __construct(BookingService $service)
    {
        $this->service = $service;
    }

    public function store(Request $request, Resource $resource)
    {
        $data = $request->validate([
            'start' => 'required|date',
            'end' => 'required|date|after:start',
            'participants_count' => 'nullable|integer|min:1'
        ]);

        $booking = $this->service->createBooking(
            $resource,
            Carbon::parse($data['start']),
            Carbon::parse($data['end']),
            $resource->resource_config['max_participants'] !== null,
            $data['participants_count'] ?? 1
        );

        return response()->json($booking, 201);
    }

    public function confirm(Booking $booking)
    {
        $this->service->confirmBooking($booking);
        return response()->json($booking);
    }

    public function cancel(Request $request, Booking $booking)
    {
        $data = $request->validate(['reason' => 'nullable|string']);
        $this->service->cancelBooking($booking, 'client', $data['reason'] ?? null);
        return response()->json($booking);
    }

    public function reschedule(Request $request, Booking $booking)
    {
        $data = $request->validate([
            'new_start' => 'required|date',
            'new_end' => 'required|date|after:new_start'
        ]);
        $this->service->rescheduleBooking(
            $booking,
            Carbon::parse($data['new_start']),
            Carbon::parse($data['new_end'])
        );
        return response()->json($booking);
    }
}
