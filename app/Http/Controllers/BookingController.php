<?php

namespace App\Http\Controllers;

use App\Models\Resource;
use App\Models\Booking;
use App\Services\BookingService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;
use Exception;

class BookingController extends Controller
{
    protected BookingService $service;

    public function __construct(BookingService $service)
    {
        $this->service = $service;
    }

    public function store(Request $request, $resourceId): JsonResponse
    {
        try {
            $resource = Resource::findOrFail($resourceId);
            $start = Carbon::parse($request->input('start'));
            $end = Carbon::parse($request->input('end'));

            $booking = $this->service->createBooking(
                $resource,
                $start,
                $end,
                $request->boolean('is_group_booking', false)
            );

            return response()->json($booking, 201);
        } catch (Exception $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }

    public function confirm($id): JsonResponse
    {
        try {
            $booking = Booking::findOrFail($id);
            $confirmed = $this->service->confirmBooking($booking);
            return response()->json($confirmed);
        } catch (Exception $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }

    public function cancel(Request $request, $id): JsonResponse
    {
        try {
            $booking = Booking::findOrFail($id);
            $cancelled = $this->service->cancelBooking(
                $booking,
                $request->input('cancelled_by', 'client'),
                $request->input('reason')
            );
            return response()->json($cancelled);
        } catch (Exception $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }

    public function reschedule(Request $request, $id): JsonResponse
    {
        try {
            $booking = Booking::findOrFail($id);
            $newStart = Carbon::parse($request->input('new_start'));
            $newEnd = Carbon::parse($request->input('new_end'));

            $rescheduled = $this->service->rescheduleBooking(
                $booking,
                $newStart,
                $newEnd,
                $request->input('requested_by', 'client')
            );

            return response()->json($rescheduled);
        } catch (Exception $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }
}
