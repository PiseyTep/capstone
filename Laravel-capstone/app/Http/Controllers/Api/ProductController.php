<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class ProductController extends Controller
{
    public function index()
    {
        try {
            $products = Product::query()
                ->when(request('search'), fn($q, $search) => $q->where('name', 'like', "%$search%"))
                ->when(request('category'), fn($q, $cat) => $q->where('category', $cat))
                ->orderBy('created_at', 'desc')
                ->paginate(10);

            return response()->json([
                'success' => true,
                'data' => $products
            ]);

        } catch (\Exception $e) {
            Log::error('ProductController@index: ' . $e->getMessage());
            return $this->errorResponse();
        }
    }

    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'required|string',
                'price' => 'required|numeric|min:0',
                'category' => 'required|in:machinery,implements,planting',
                'stock' => 'required|integer|min:0',
                'image' => 'required|image|max:2048'
            ]);

            $validated['image_url'] = $request->file('image')->store('products', 'public');

            $product = Product::create($validated);

            return response()->json([
                'success' => true,
                'data' => $product
            ], 201);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('ProductController@store: ' . $e->getMessage());
            return $this->errorResponse();
        }
    }

    public function show(Product $product)
    {
        return response()->json([
            'success' => true,
            'data' => $product
        ]);
    }

    public function update(Request $request, Product $product)
    {
        try {
            $validated = $request->validate([
                'name' => 'sometimes|string|max:255',
                'description' => 'sometimes|string',
                'price' => 'sometimes|numeric|min:0',
                'category' => 'sometimes|in:machinery,implements,planting',
                'stock' => 'sometimes|integer|min:0',
                'image' => 'sometimes|image|max:2048'
            ]);

            if ($request->hasFile('image')) {
                Storage::delete($product->image_url);
                $validated['image_url'] = $request->file('image')->store('products', 'public');
            }

            $product->update($validated);

            return response()->json([
                'success' => true,
                'data' => $product
            ]);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('ProductController@update: ' . $e->getMessage());
            return $this->errorResponse();
        }
    }

    public function destroy(Product $product)
    {
        try {
            Storage::delete($product->image_url);
            $product->delete();

            return response()->json([
                'success' => true,
                'message' => 'Product deleted'
            ]);

        } catch (\Exception $e) {
            Log::error('ProductController@destroy: ' . $e->getMessage());
            return $this->errorResponse();
        }
    }

    protected function errorResponse($message = 'Server error', $code = 500)
    {
        return response()->json([
            'success' => false,
            'message' => $message
        ], $code);
    }
}