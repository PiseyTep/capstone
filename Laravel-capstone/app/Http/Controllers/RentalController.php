<?php

namespace App\Http\Controllers;

use App\Models\Rental;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RentalController extends Controller
{
    // Get all rentals (admin access)
    public function index(Request $request)
    {
        $query = Rental::with(['user', 'product']);
        
        // Filter by status if specified
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        // Filter by user if specified
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        
        $rentals = $query->orderBy('created_at', 'desc')->paginate(10);
        
        return response()->json([
            'success' => true,
            'data' => $rentals
        ]);
    }
    
    // Get rentals for current user
    public function userRentals(Request $request)
    {
        $rentals = Rental::with('product')
                    ->where('user_id', $request->user()->id)
                    ->orderBy('created_at', 'desc')
                    ->get();
        
        return response()->json([
            'success' => true,
            'data' => $rentals
        ]);
    }
    
    // Get a specific rental
    public function show($id)
    {
        $rental = Rental::with(['user', 'product'])->findOrFail($id);
        
        // Check if user is authorized to view this rental
        if ($rental->user_id !== auth()->id() && auth()->user()->role === 'farmer') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }
        
        return response()->json([
            'success' => true,
            'data' => $rental
        ]);
    }
    
    // Create a new rental
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'product_id' => 'required|exists:products,id',
            'rental_date' => 'required|date|after_or_equal:today',
            'return_date' => 'required|date|after_or_equal:rental_date',
            'land_size' => 'nullable|numeric|min:0',
            'land_size_unit' => 'nullable|string',
            'notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }
        
        // Calculate total price based on product pricing and rental days
        $product = Product::findOrFail($request->product_id);
        $rentalDate = new \DateTime($request->rental_date);
        $returnDate = new \DateTime($request->return_date);
        $days = $rentalDate->diff($returnDate)->days + 1; // Include both start and end days
        
        $totalPrice = $product->price_per_day * $days;
        
        // Add land size price if applicable
        if ($request->has('land_size') && $request->land_size > 0 && $product->price_per_acre > 0) {
            // Convert to acres if needed
            $sizeInAcres = $request->land_size;
            if ($request->land_size_unit === 'Hectares') {
                $sizeInAcres = $request->land_size * 2.47105;
            } elseif ($request->land_size_unit === 'Square Meters') {
                $sizeInAcres = $request->land_size * 0.000247105;
            }
            
            $totalPrice += $product->price_per_acre * $sizeInAcres;
        }
        
        $rental = Rental::create([
            'user_id' => $request->user()->id,
            'product_id' => $request->product_id,
            'rental_date' => $request->rental_date,
            'return_date' => $request->return_date,
            'land_size' => $request->land_size,
            'land_size_unit' => $request->land_size_unit,
            'total_price' => $totalPrice,
            'status' => 'pending',
            'notes' => $request->notes
        ]);
        
        return response()->json([
            'success' => true,
            'message' => 'Rental created successfully',
            'data' => $rental
        ], 201);
    }
    
    // Update a rental
    public function update(Request $request, $id)
    {
        $rental = Rental::findOrFail($id);
        
        // Only admins can update rentals after creation
        if (auth()->user()->role === 'farmer') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }
        
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:pending,approved,rejected,completed,cancelled'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $rental->update([
            'status' => $request->status
        ]);
        
        return response()->json([
            'success' => true,
            'message' => 'Rental updated successfully',
            'data' => $rental
        ]);
    }
    
    // Cancel a rental (for farmers)
    public function cancel(Request $request, $id)
    {
        $rental = Rental::findOrFail($id);
        
        // Check if user owns this rental
        if ($rental->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }
        
        // Check if rental can be cancelled
        if (!in_array($rental->status, ['pending', 'approved'])) {
            return response()->json([
                'success' => false,
                'message' => 'This rental cannot be cancelled'
            ], 400);
        }
        
        $rental->update([
            'status' => 'cancelled'
        ]);
        
        return response()->json([
            'success' => true,
            'message' => 'Rental cancelled successfully',
            'data' => $rental
        ]);
    }
    
    // Get pending rentals count
    public function getPendingRentalsCount()
    {
        $count = Rental::where('status', 'pending')->count();
        
        return response()->json([
            'success' => true,
            'data' => [
                'count' => $count
            ]
        ]);
    }
}