<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Rental;
use App\Models\Product;
use App\Models\Video;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AdminController extends Controller
{
    /**
     * Display admin profile
     */
    public function profile()
    {
        try {
            $user = auth()->user();
            return response()->json([
                'success' => true,
                'data' => [
                    'user' => $user,
                    'permissions' => $user->getPermissions()
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Admin profile error: '.$e->getMessage());
            return $this->errorResponse();
        }
    }

    /**
     * Get admin dashboard stats
     */
    public function getStats()
    {
        try {
            return response()->json([
                'success' => true,
                'data' => [
                    'total_users' => User::count(),
                    'total_farmers' => User::where('role', 'farmer')->count(),
                    'active_rentals' => Rental::where('status', 'active')->count(),
                    'pending_rentals' => Rental::where('status', 'pending')->count(),
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Admin stats error: '.$e->getMessage());
            return $this->errorResponse();
        }
    }

    /**
     * Get pending rentals for approval
     */
    public function pendingRentals()
    {
        try {
            $rentals = Rental::with(['user', 'product'])
                ->where('status', 'pending')
                ->paginate(10);

            return response()->json([
                'success' => true,
                'data' => $rentals
            ]);
        } catch (\Exception $e) {
            Log::error('Pending rentals error: '.$e->getMessage());
            return $this->errorResponse();
        }
    }

    /**
     * Approve a rental
     */
    public function approveRental($id)
    {
        try {
            $rental = Rental::findOrFail($id);
            $rental->update(['status' => 'approved']);
            
            return response()->json([
                'success' => true,
                'message' => 'Rental approved successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('Approve rental error: '.$e->getMessage());
            return $this->errorResponse();
        }
    }

    /**
     * Send notification to users
     */
    public function sendNotification(Request $request)
    {
        try {
            $validated = $request->validate([
                'title' => 'required|string',
                'message' => 'required|string',
                'user_ids' => 'nullable|array',
                'user_ids.*' => 'exists:users,id'
            ]);

            // Implementation depends on your notification system
            // Example: dispatch notification jobs
            
            return response()->json([
                'success' => true,
                'message' => 'Notifications sent successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('Send notification error: '.$e->getMessage());
            return $this->errorResponse();
        }
    }

    /**
     * Manage farmers (CRUD operations)
     */
    public function index()
    {
        try {
            $farmers = User::where('role', 'farmer')
                ->paginate(10);

            return response()->json([
                'success' => true,
                'data' => $farmers
            ]);
        } catch (\Exception $e) {
            Log::error('List farmers error: '.$e->getMessage());
            return $this->errorResponse();
        }
    }

    // ... Add other CRUD methods (show, update, destroy) similarly

    private function errorResponse($message = 'Server error', $code = 500)
    {
        return response()->json([
            'success' => false,
            'message' => $message
        ], $code);
    }
    // Add these methods to your existing AdminController

/**
 * Update a farmer's details
 */
public function updateFarmer(Request $request, $id)
{
    try {
        $farmer = User::where('role', 'farmer')->findOrFail($id);
        
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,'.$id,
            'phone_number' => 'sometimes|string|max:20',
            'status' => 'sometimes|in:active,suspended'
        ]);

        $farmer->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Farmer updated successfully',
            'data' => $farmer
        ]);

    } catch (\Exception $e) {
        Log::error('Update farmer error: '.$e->getMessage());
        return $this->errorResponse();
    }
}

/**
 * Delete a farmer
 */
public function deleteFarmer($id)
{
    try {
        $farmer = User::where('role', 'farmer')->findOrFail($id);
        $farmer->delete();

        return response()->json([
            'success' => true,
            'message' => 'Farmer deleted successfully'
        ]);

    } catch (\Exception $e) {
        Log::error('Delete farmer error: '.$e->getMessage());
        return $this->errorResponse();
    }
}
}