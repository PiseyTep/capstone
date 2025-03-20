<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Booking;
class BookingController extends Controller
{
    // Get all bookings
    public function index()
    {
        return response()->json(Booking::all());
    }

    // Create a new booking
    public function store(Request $request)
    {
        $request->validate([
            'user_id' => 'required',
            'tractor_id' => 'required',
            'date' => 'required|date',
            'acres' => 'required|integer',
        ]);
  // Create a new booking using the validated data
 
        $booking = Booking::create([
            'user_id' => $request->user_id,
            'tractor_id' => $request->tractor_id,
            'date' => $request->date,
            'acres' => $request->acres,
            'status' => 'pending', // default status
        ]);

// Return the created booking as a JSON response
return response()->json([
    'message' => 'Booking created successfully',
    'booking' => $booking
], 201);
    }
}
