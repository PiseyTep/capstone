<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Firebase\Auth\Token\Exception\InvalidToken;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Auth as FirebaseAuth;
class AuthController extends Controller
{
    protected $auth;

    public function __construct()
    {
        $firebaseCredentials = storage_path('firebase_credentials.json');
        $firebase = (new Factory)->withServiceAccount($firebaseCredentials);
        $this->auth = $firebase->createAuth();
    }

    public function register(Request $request)
{
    $validator = Validator::make($request->all(), [
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users,email',
        'password' => 'required|string|min:6',
        'phone_number' => 'nullable|string',
        'firebase_uid' => 'nullable|string',
        'firebase_token' => 'required|string',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'message' => $validator->errors()->first(),
        ], 400);
    }

    try {
        // Verify Firebase ID token
        $verifiedIdToken = $this->auth->verifyIdToken($request->firebase_token);
        $firebaseUid = $verifiedIdToken->getClaim('sub');

        // Optionally check if firebase_uid in request matches token
        if ($request->firebase_uid && $request->firebase_uid !== $firebaseUid) {
            return response()->json([
                'success' => false,
                'message' => 'Firebase UID mismatch',
            ], 403);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone_number' => $request->phone_number,
            'firebase_uid' => $firebaseUid,
            'role' => 'farmer',
        ]);

        $token = $user->createToken('mobile-app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registration successful',
            'token' => $token,
            'data' => ['user' => $user],
        ], 201);
    } catch (\Throwable $e) {
        return response()->json([
            'success' => false,
            'message' => 'Registration failed: ' . $e->getMessage(),
        ], 500);
    }
}

public function login(Request $request)
{
    $validator = Validator::make($request->all(), [
        'email' => 'required|email',
        'password' => 'required|string',
        'firebase_token' => 'required|string',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'message' => $validator->errors()->first(),
        ], 400);
    }

    try {
        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials',
            ], 401);
        }

        $verifiedIdToken = $this->auth->verifyIdToken($request->firebase_token);
        $firebaseUid = $verifiedIdToken->getClaim('sub');

        // Update Firebase UID if needed
        if ($user->firebase_uid !== $firebaseUid) {
            $user->firebase_uid = $firebaseUid;
            $user->save();
        }

        $token = $user->createToken('mobile-app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'token' => $token,
            'user' => $user,
        ]);
    } catch (\Throwable $e) {
        return response()->json([
            'success' => false,
            'message' => 'Login failed: ' . $e->getMessage(),
        ], 500);
    }
}


            

    
    // Admin-specific login
    public function adminLogin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $credentials = $request->only('email', 'password');
        
        if (Auth::attempt($credentials)) {
            $user = Auth::user();
            
            // Verify user is admin or super_admin
            if (!in_array($user->role, ['admin', 'super_admin'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Admin access required.'
                ], 403);
            }
            
            // Check if admin account is approved
            if ($user->approved !== 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Your account is pending approval.'
                ], 403);
            }
            
            $token = $user->createToken('admin_token')->plainTextToken;
            
            return response()->json([
                'success' => true,
                'message' => 'Admin login successful',
                'token' => $token,
                'user' => $user
            ]);
        }
        
        return response()->json([
            'success' => false,
            'message' => 'Invalid credentials'
        ], 401);
    }
    
    // Register a new admin (requires approval)
    public function adminRegister(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => 'admin',
            'approved' => 0 // Requires super admin approval
        ]);
        
        return response()->json([
            'success' => true,
            'message' => 'Admin registration successful. Your account requires super admin approval.',
            'user' => $user
        ], 201);
    }
    
    // Log out
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully'
        ]);
    }
    
    // Get authenticated user details
    public function userDetails(Request $request)
    {
        return response()->json([
            'success' => true,
            'user' => $request->user()
        ]);
    }
}