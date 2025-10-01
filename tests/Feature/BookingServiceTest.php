<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\Resource;
use App\Models\ResourceType;
use App\Services\BookingService;
use App\ValueObjects\ResourceConfig;
use DateTime;

class BookingServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_create_booking_requires_confirmation()
    {
        $type = ResourceType::factory()->create(['company_id'=>1,'type'=>'staff','name'=>'Staff']);
        $resource = Resource::create([
            'company_id' => 1,
            'resource_type_id' => $type->id,
            'resource_config' => ResourceConfig::fromArray([
                'require_confirmation' => true,
                'slot_duration_minutes' => 60
            ])
        ]);

        $participant = (object)['id' => 0];

        $service = app(BookingService::class);

        $start = (new DateTime())->add(new \DateInterval('P1D'));
        $end   = (clone $start)->add(new \DateInterval('PT1H'));

        $booking = $service->createBooking($resource, $start, $end, $participant);
        $this->assertEquals('pending_confirmation', $booking->status);
    }
}
