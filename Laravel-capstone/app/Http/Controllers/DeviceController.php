<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\Device;

class DeviceController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validatedData = $request->validate([
            'user_id' => 'nullable|string',
            'device_token' => 'required|string',
            'platform' => 'required|string'
        ]);

        try {
            $device = Device::create($validatedData);

            return response()->json([
                'success' => true,
                'message' => 'Device registered successfully',
                'device' => $device
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Device registration failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}