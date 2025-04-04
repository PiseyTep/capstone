<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProductController extends Controller
{
    // Get all products
    public function index()
    {
        $products = Product::orderBy('created_at', 'desc')->paginate(10);
        
        return response()->json([
            'success' => true,
            'data' => $products
        ]);
    }
    
    // Get products for public access
    public function publicIndex()
    {
        $products = Product::where('is_available', true)
                    ->orderBy('created_at', 'desc')
                    ->paginate(10);
        
        return response()->json([
            'success' => true,
            'data' => $products
        ]);
    }
    
    // Get a specific product
    public function show($id)
    {
        $product = Product::findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $product
        ]);
    }
    
    // Create a new product
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price_per_day' => 'required|numeric|min:0',
            'price_per_acre' => 'nullable|numeric|min:0',
            'type' => 'required|string|max:100',
            'image_url' => 'nullable|url'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $product = Product::create($request->all());
        
        return response()->json([
            'success' => true,
            'message' => 'Product created successfully',
            'data' => $product
        ], 201);
    }
    
    // Update a product
    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);
        
        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'price_per_day' => 'sometimes|numeric|min:0',
            'price_per_acre' => 'nullable|numeric|min:0',
            'type' => 'sometimes|string|max:100',
            'image_url' => 'nullable|url',
            'is_available' => 'sometimes|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $product->update($request->all());
        
        return response()->json([
            'success' => true,
            'message' => 'Product updated successfully',
            'data' => $product
        ]);
    }
    
    // Delete a product
    public function destroy($id)
    {
        $product = Product::findOrFail($id);
        
        // Check if product has any active rentals
        $activeRentals = $product->rentals()->whereIn('status', ['pending', 'approved'])->exists();
        
        if ($activeRentals) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot delete product with active rentals'
            ], 400);
        }
        
        $product->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Product deleted successfully'
        ]);
    }
    
    // Get product categories
    public function getCategories()
    {
        $categories = Product::select('type')->distinct()->get()->pluck('type');
        
        return response()->json([
            'success' => true,
            'data' => $categories
        ]);
    }
}