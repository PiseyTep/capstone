<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    // Register a new user
    public function register(Request $request)
    {
        $validatedData = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:6',
            'phone_number' => 'nullable|string|max:20',
            'role' => 'nullable|in:farmer,admin,super_admin',
        ]);

        $user = User::create([
            'name' => $validatedData['name'],
            'email' => $validatedData['email'],
            'password' => Hash::make($validatedData['password']),
            'phone_number' => $request->input('phone_number'),
            'role' => $request->input('role', 'farmer'), // Default to farmer if not specified
        ]);

        $token = $user->createToken('authToken')->plainTextToken;

        return response()->json([
            'message' => 'User registered successfully!',
            'token' => $token,
            'user' => $this->formatUserResponse($user)
        ], 201);
    }

    // Login user
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        // Enforce login restrictions
        if ($request->is('api/*')) {
            // Mobile app login (only farmers allowed)
            if ($user->role !== 'farmer') {
                return response()->json(['message' => 'Unauthorized: Only farmers can access the mobile app'], 403);
            }
        } else {
            // Web login (only admin and super_admin allowed)
            if (!in_array($user->role, ['admin', 'super_admin'])) {
                return response()->json(['message' => 'Unauthorized: Only admins can access the web dashboard'], 403);
            }
        }

        // Revoke all existing tokens for this user
        $user->tokens()->delete();

        $token = $user->createToken('authToken')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->formatUserResponse($user)
        ]);
    }

    // Get authenticated user details
    public function userDetails(Request $request)
    {
        $user = $request->user();
        return response()->json($this->formatUserResponse($user));
    }

    // Logout user
    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();
        
        return response()->json(['message' => 'Logged out successfully']);
    }

    // Helper method to format user response
    private function formatUserResponse($user)
    {
        $userResponse = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
        ];

        // Add phone number if exists
        if ($user->phone_number) {
            $userResponse['phone_number'] = $user->phone_number;
        }

        return $userResponse;
    }

    public function adminRegister(Request $request)
    {
        // Validate the incoming request
        $validatedData = $request->validate([
            'fName' => 'required|string|max:255',
            'lName' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
        ]);
    
        // Check if email already exists (though unique validation should handle this)
        $existingUser = User::where('email', $validatedData['email'])->first();
        if ($existingUser) {
            return response()->json([
                'message' => 'Email Address Already Exists!'
            ], 400);
        }
    
        // Create the user
        $user = User::create([
            'name' => $validatedData['fName'] . ' ' . $validatedData['lName'],
            'email' => $validatedData['email'],
            'password' => Hash::make($validatedData['password']),
            'role' => 'admin', // Default to admin
            'approved' => 0, // Set to unapproved
        ]);
    
        return response()->json([
            'message' => 'Registration successful! Your account requires approval from a super admin before you can log in.'
        ], 201);
    }
}