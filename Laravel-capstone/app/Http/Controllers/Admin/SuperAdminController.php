<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class SuperAdminController extends Controller
{
    /**
     * Get system settings
     */
    public function getSettings()
    {
        try {
            return response()->json([
                'success' => true,
                'data' => [
                    'system_name' => config('app.name'),
                    'maintenance_mode' => app()->isDownForMaintenance(),
                    'email_verification' => config('auth.must_verify_email'),
                    // Add other system settings
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Get settings error: '.$e->getMessage());
            return $this->errorResponse();
        }
    }

    /**
     * Update system settings
     */
    public function updateSettings(Request $request)
    {
        try {
            $validated = $request->validate([
                'email_verification' => 'boolean',
                'maintenance_mode' => 'boolean',
                // Add other validatable settings
            ]);

            // Implementation depends on how you store settings
            // Example: update config files or database
            
            return response()->json([
                'success' => true,
                'message' => 'Settings updated successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('Update settings error: '.$e->getMessage());
            return $this->errorResponse();
        }
    }

    /**
     * Get advanced statistics
     */
    public function getAdvancedStats()
    {
        try {
            return response()->json([
                'success' => true,
                'data' => [
                    'growth_metrics' => $this->getGrowthMetrics(),
                    'user_activity' => $this->getUserActivity(),
                    // Add other advanced stats
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Advanced stats error: '.$e->getMessage());
            return $this->errorResponse();
        }
    }

    /**
     * Manage admins (CRUD operations)
     */
    public function index()
    {
        try {
            $admins = User::where('role', 'admin')
                ->paginate(10);

            return response()->json([
                'success' => true,
                'data' => $admins
            ]);
        } catch (\Exception $e) {
            Log::error('List admins error: '.$e->getMessage());
            return $this->errorResponse();
        }
    }

    // ... Add other CRUD methods (show, store, update, destroy) similarly

    private function getGrowthMetrics()
    {
        // Implement your growth metrics logic
        return [
            'user_growth' => 25, // percentage
            'rental_growth' => 40,
        ];
    }

    private function getUserActivity()
    {
        // Implement user activity tracking
        return [
            'active_users' => User::active()->count(),
            'new_users' => User::newThisWeek()->count(),
        ];
    }

    private function errorResponse($message = 'Server error', $code = 500)
    {
        return response()->json([
            'success' => false,
            'message' => $message
        ], $code);
    }
    // Add these methods to your existing SuperAdminController

/**
 * Create a new admin
 */
public function createAdmin(Request $request)
{
    try {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:8|confirmed'
        ]);

        $admin = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => 'admin',
            'approved' => false // Requires super admin approval
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Admin created successfully. Pending approval.',
            'data' => $admin
        ], 201);

    } catch (\Exception $e) {
        Log::error('Create admin error: '.$e->getMessage());
        return $this->errorResponse();
    }
}

/**
 * Update an admin
 */
public function updateAdmin(Request $request, $id)
{
    try {
        $admin = User::where('role', 'admin')->findOrFail($id);
        
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,'.$id,
            'password' => 'sometimes|string|min:8|confirmed',
            'approved' => 'sometimes|boolean'
        ]);

        if (isset($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        }

        $admin->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Admin updated successfully',
            'data' => $admin
        ]);

    } catch (\Exception $e) {
        Log::error('Update admin error: '.$e->getMessage());
        return $this->errorResponse();
    }
}
}