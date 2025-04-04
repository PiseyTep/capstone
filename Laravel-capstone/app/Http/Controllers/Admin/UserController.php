<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    // List all users (with optional filters)
    public function index(Request $request)
    {
        $query = User::query();
        
        // Filter by role if specified
        if ($request->has('role')) {
            $query->where('role', $request->role);
        }
        
        // Filter by approval status if specified
        if ($request->has('approved')) {
            $query->where('approved', (bool)$request->approved);
        }
        
        // Search by name or email
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }
        
        $users = $query->orderBy('created_at', 'desc')->paginate(15);
        
        return response()->json([
            'success' => true,
            'data' => $users
        ]);
    }
    
    // Get user details
    public function show($id)
    {
        $user = User::findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $user
        ]);
    }
    
    // Create a new user
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6',
            'role' => 'required|in:farmer,admin,super_admin',
            'phone_number' => 'nullable|string|max:20'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }
        
        // Only super_admin can create other admins or super_admins
        if (in_array($request->role, ['admin', 'super_admin'])) {
            if ($request->user()->role !== 'super_admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Only super admins can create admin accounts.'
                ], 403);
            }
        }
        
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'phone_number' => $request->phone_number ?? '',
            'approved' => $request->role === 'farmer' ? 1 : ($request->approved ?? 0)
        ]);
        
        return response()->json([
            'success' => true,
            'message' => 'User created successfully',
            'data' => $user
        ], 201);
    }
    
    // Update user
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,'.$id,
            'role' => 'sometimes|in:farmer,admin,super_admin',
            'approved' => 'sometimes|boolean',
            'phone_number' => 'nullable|string|max:20'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }
        
        // Role change restrictions
        if ($request->has('role') && $request->role !== $user->role) {
            if ($request->user()->role !== 'super_admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Only super admins can change user roles.'
                ], 403);
            }
            
            // Prevent changing the role of a super_admin
            if ($user->role === 'super_admin' && $request->role !== 'super_admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot change role of a super admin.'
                ], 403);
            }
        }
        
        // Approval restrictions
        if ($request->has('approved') && $request->user()->role !== 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Only super admins can approve/unapprove users.'
            ], 403);
        }
        
        // Update password if provided
        if ($request->has('password') && !empty($request->password)) {
            $request->merge([
                'password' => Hash::make($request->password)
            ]);
        } else {
            $request->request->remove('password');
        }
        
        $user->update($request->all());
        
        return response()->json([
            'success' => true,
            'message' => 'User updated successfully',
            'data' => $user
        ]);
    }
    
    // Delete user
    public function destroy(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        // Prevent deleting a super_admin
        if ($user->role === 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Cannot delete a super admin account.'
            ], 403);
        }
        
        // Only super_admin can delete admin accounts
        if ($user->role === 'admin' && $request->user()->role !== 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Only super admins can delete admin accounts.'
            ], 403);
        }
        
        $user->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'User deleted successfully'
        ]);
    }
    
    // Approve user
    public function approve($id)
    {
        // Only super_admin can approve users (middleware will handle this)
        $user = User::findOrFail($id);
        $user->approved = 1;
        $user->save();
        
        return response()->json([
            'success' => true,
            'message' => 'User approved successfully',
            'data' => $user
        ]);
    }
    
    // Get dashboard stats
    public function getStats()
    {
        $stats = [
            'adminAccount' => User::whereIn('role', ['admin', 'super_admin'])->count(),
            'totalFarmers' => User::where('role', 'farmer')->count(),
            'totalMachines' => 0, // You'll need to connect this to your products table
            'activeRentals' => 0, // You'll need to connect this to your rentals table
            'pendingAdmins' => User::where('role', 'admin')->where('approved', 0)->count(),
        ];
        
        return response()->json([
            'success' => true,
            'data' => $stats
        ]);
    }
    
    // Get pending admin count
    public function getPendingAdmins()
    {
        $count = User::where('role', 'admin')->where('approved', 0)->count();
        
        return response()->json([
            'success' => true,
            'data' => [
                'count' => $count
            ]
        ]);
    }
}