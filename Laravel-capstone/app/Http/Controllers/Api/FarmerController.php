<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;

class FarmerController extends Controller
{
    public function profile(): JsonResponse
    {
        // Retrieve the authenticated farmer's profile
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not authenticated'
            ], 401);
        }

        return response()->json([
            'success' => true,
            'message' => 'Farmer profile retrieved',
            'profile' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone_number' => $user->phone_number,
                // Add other relevant profile details
            ]
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not authenticated'
            ], 401);
        }

        $validatedData = $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone_number' => 'sometimes|string|max:20',
            // Add other fields as needed
        ]);

        try {
            $user->update($validatedData);

            return response()->json([
                'success' => true,
                'message' => 'Profile updated successfully',
                'profile' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone_number' => $user->phone_number,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Profile update failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function registerDevice(Request $request): JsonResponse
    {
        $validatedData = $request->validate([
            'device_token' => 'required|string',
            'platform' => 'required|string|in:ios,android,web,flutter',
            'device_model' => 'nullable|string',
            'device_os_version' => 'nullable|string'
        ]);

        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not authenticated'
            ], 401);
        }

        try {
            // Create or update device registration
            $device = $user->devices()->updateOrCreate(
                ['device_token' => $validatedData['device_token']],
                [
                    'platform' => $validatedData['platform'],
                    'device_model' => $validatedData['device_model'] ?? null,
                    'device_os_version' => $validatedData['device_os_version'] ?? null
                ]
            );

            return response()->json([
                'success' => true,
                'message' => 'Device registered successfully',
                'device' => $device
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Device registration failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}