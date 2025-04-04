<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rental;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class RentalController extends Controller
{
    public function index(Request $request)
    {
        // Check if user_id filter is provided
        if ($request->has('user_id')) {
            $rentals = Rental::where('user_id', $request->user_id)->get();
        } else {
            $rentals = Rental::all();
        }
        
        return response()->json([
            'success' => true,
            'data' => $rentals
        ]);
    }

    public function store(Request $request)
    {
        // Validate the incoming request
        $validator = Validator::make($request->all(), [
            'tractor_id' => 'required|string',
            'rental_date' => 'required|date',
            'return_date' => 'required|date|after_or_equal:rental_date',
            'land_size' => 'nullable|numeric',
            'land_size_unit' => 'nullable|string',
            'total_price' => 'required|numeric',
            'customer_name' => 'required|string',
            'customer_phone' => 'nullable|string',
            'customer_address' => 'nullable|string',
            'notes' => 'nullable|string'
        ]);

        // If validation fails, return error response
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation Error',
                'errors' => $validator->errors()
            ], 400);
        }

        try {
            // Create the rental with properly mapped field names
            $rental = new Rental();
            $rental->user_id = Auth::id();
            $rental->tractor_id = $request->tractor_id;
            $rental->product_name = $request->tractorName ?? 'Unknown Tractor';
            $rental->rental_date = $request->rental_date;
            $rental->return_date = $request->return_date;
            $rental->total_price = $request->total_price;
            $rental->status = 'pending';
            $rental->farmer_name = $request->customer_name;
            $rental->farmer_phone = $request->customer_phone;
            $rental->farmer_address = $request->customer_address;
            $rental->land_size = $request->land_size;
            $rental->land_size_unit = $request->land_size_unit ?? 'Acres';
            $rental->notes = $request->notes;
            $rental->save();

            // Return success response
            return response()->json([
                'success' => true,
                'message' => 'Rental created successfully',
                'data' => $rental
            ], 201);
        } catch (\Exception $e) {
            // Handle any unexpected errors
            return response()->json([
                'success' => false,
                'message' => 'Error creating rental: ' . $e->getMessage()
            ], 500);
        }
    }

    public function show($id)
    {
        $rental = Rental::findOrFail($id);
        return response()->json([
            'success' => true,
            'data' => $rental
        ]);
    }

    public function update(Request $request, $id)
    {
        $rental = Rental::findOrFail($id);
        
        $validator = Validator::make($request->all(), [
            'status' => 'in:pending,approved,rejected,completed'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 400);
        }

        $rental->update($request->all());

        return response()->json([
            'success' => true,
            'data' => $rental
        ]);
    }
    
    public function cancel($id)
    {
        $rental = Rental::findOrFail($id);
        
        // Only allow cancellation if the rental is pending or approved
        if (!in_array($rental->status, ['pending', 'approved'])) {
            return response()->json([
                'success' => false,
                'message' => 'This rental cannot be cancelled at this stage'
            ], 400);
        }
        
        $rental->status = 'cancelled';
        $rental->save();
        
        return response()->json([
            'success' => true,
            'message' => 'Rental cancelled successfully',
            'data' => $rental
        ]);
    }
}