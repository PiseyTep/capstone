<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rental;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RentalController extends Controller
{
    public function store(Request $request)
    {
        // Validate the incoming request
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
            'tractor_id' => 'required|string',
            'farmer_name' => 'required|string',
            'product_name' => 'required|string',
            'rental_date' => 'required|date',
            'farmer_phone' => 'nullable|string',
            'farmer_address' => 'nullable|string',
            'land_size' => 'nullable|numeric',
            'land_size_unit' => 'nullable|string',
            'total_price' => 'nullable|numeric',
            'status' => 'nullable|in:pending,approved,rejected,completed'
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
            // Create the rental
            $rental = Rental::create($request->all());

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

    // Add methods for listing, updating, and deleting rentals as needed
    public function index()
    {
        $rentals = Rental::with('user')->get();
        return response()->json([
            'success' => true,
            'data' => $rentals
        ]);
    }

    public function show($id)
    {
        $rental = Rental::with('user')->findOrFail($id);
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
}