<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\SuperAdminController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\VideoController;
use App\Http\Controllers\RentalController;
use App\Http\Controllers\BookingController;
use App\Http\Controllers\FarmerController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Models\Rental;
use Illuminate\Support\Facades\Hash;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public Routes - No Authentication Required
Route::prefix('api')->group(function () {
    // Farmer (Flutter app) endpoints
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    
    // Admin (Web dashboard) endpoints
    Route::post('/admin/login', [AuthController::class, 'adminLogin']);
    Route::post('/admin/register', [AuthController::class, 'adminRegister']);
    
    // Public endpoints for both interfaces
    Route::get('/products/public', [ProductController::class, 'publicIndex']);
    Route::get('/videos/public', [VideoController::class, 'publicIndex']);
});

// Farmer Routes - For Flutter App
Route::middleware(['auth:sanctum', 'farmer'])->prefix('api')->group(function () {
    // Authentication
    Route::get('/user', [AuthController::class, 'userDetails']);
    Route::post('/logout', [AuthController::class, 'logout']);
    
    // Farmer profile
    Route::get('/profile', [FarmerController::class, 'profile']);
    Route::put('/profile', [FarmerController::class, 'updateProfile']);
    
    // Bookings
    // Route::get('/bookings', [BookingController::class, 'index']);
    // Route::post('/bookings', [BookingController::class, 'store']);
    // Route::get('/bookings/{id}', [BookingController::class, 'show']);
    
    // Rentals
    Route::get('/rentals', [RentalController::class, 'farmerIndex']);
    Route::post('/rentals', [RentalController::class, 'store']);
    
    // Products for farmers to view
    Route::get('/products', [ProductController::class, 'index']);
    Route::get('/products/{id}', [ProductController::class, 'show']);
    
    // Videos for farmers to view
    Route::get('/videos', [VideoController::class, 'index']);
    Route::get('/videos/{id}', [VideoController::class, 'show']);
    
    // Device registration for notifications
    Route::post('/register-device', [FarmerController::class, 'registerDevice']);
});

// Admin Routes - For Web Dashboard
Route::middleware(['auth:sanctum', 'admin'])->prefix('api/admin')->group(function () {
    // Admin authentication
    Route::get('/profile', [AdminController::class, 'profile']);
    Route::post('/logout', [AuthController::class, 'adminLogout']);
    
    // Dashboard stats
    Route::get('/stats', [AdminController::class, 'getStats']);
    
    // User management
    Route::get('/farmers', [AdminController::class, 'getFarmers']);
    Route::get('/farmers/{id}', [AdminController::class, 'getFarmer']);
    Route::put('/farmers/{id}', [AdminController::class, 'updateFarmer']);
    Route::delete('/farmers/{id}', [AdminController::class, 'deleteFarmer']);
    
    // Product management
    Route::get('/products', [ProductController::class, 'adminIndex']);
    Route::post('/products', [ProductController::class, 'store']);
    Route::get('/products/{id}', [ProductController::class, 'adminShow']);
    Route::put('/products/{id}', [ProductController::class, 'update']);
    Route::delete('/products/{id}', [ProductController::class, 'destroy']);
    
    // Video management
    Route::get('/videos', [VideoController::class, 'adminIndex']);
    Route::post('/videos', [VideoController::class, 'store']);
    Route::get('/videos/{id}', [VideoController::class, 'adminShow']);
    Route::put('/videos/{id}', [VideoController::class, 'update']);
    Route::delete('/videos/{id}', [VideoController::class, 'destroy']);
    
    // Rental management
    
        Route::get('/rentals', [RentalController::class, 'index']);
        Route::get('/rentals/{id}', [RentalController::class, 'show']);
        Route::put('/rentals/{id}', [RentalController::class, 'update']);
  
    
    // Booking management
    // Route::get('/bookings', [BookingController::class, 'adminIndex']);
    // Route::get('/bookings/{id}', [BookingController::class, 'adminShow']);
    // Route::put('/bookings/{id}/approve', [BookingController::class, 'approve']);
    // Route::put('/bookings/{id}/reject', [BookingController::class, 'reject']);
    
    // Send notifications to farmers
    Route::post('/send-notification', [AdminController::class, 'sendNotification']);
});

// Super Admin Routes - For Web Dashboard (Super Admin Only)
Route::middleware(['auth:sanctum', 'super_admin'])->prefix('api/admin')->group(function () {
    // Admin user management
    Route::get('/admins', [SuperAdminController::class, 'getAdmins']);
    Route::post('/admins', [SuperAdminController::class, 'createAdmin']);
    Route::get('/admins/{id}', [SuperAdminController::class, 'getAdmin']);
    Route::put('/admins/{id}', [SuperAdminController::class, 'updateAdmin']);
    Route::delete('/admins/{id}', [SuperAdminController::class, 'deleteAdmin']);
    
    // System settings
    Route::get('/settings', [SuperAdminController::class, 'getSettings']);
    Route::put('/settings', [SuperAdminController::class, 'updateSettings']);
    
    // Advanced analytics
    Route::get('/advanced-stats', [SuperAdminController::class, 'getAdvancedStats']);
});

// For backwards compatibility with your existing routes
// You can keep these temporarily and migrate to the structured routes above
Route::post('/admin/login', function (Request $request) {
    $credentials = $request->validate([
        'email' => 'required|email',
        'password' => 'required'
    ]);

    $user = User::where('email', $credentials['email'])->first();

    if (!$user || !Hash::check($credentials['password'], $user->password)) {
        return response()->json(['message' => 'Invalid credentials'], 401);
    }

    // Check if user is admin or super_admin
    if (!in_array($user->role, ['admin', 'super_admin'])) {
        return response()->json(['message' => 'Unauthorized access'], 403);
    }

    $token = $user->createToken('adminToken')->plainTextToken;
    return response()->json(['token' => $token, 'user' => $user]);
});

Route::post('/admin/register', function (Request $request) {
    $validatedData = $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users',
        'password' => 'required|min:6'
    ]);

    $user = User::create([
        'name' => $validatedData['name'],
        'email' => $validatedData['email'],
        'password' => Hash::make($validatedData['password']),
        'role' => 'admin'
    ]);

    return response()->json(['message' => 'Admin registered successfully!'], 201);
});

Route::get('/admin/stats', function () {
    return response()->json([
        'totalUsers' => User::count(),
        'totalFarmers' => User::where('role', 'farmer')->count(),
        'totalMachines' => Rental::count(),
        'weeklyReport' => [10, 15, 25, 18, 12, 14, 20]
    ]);
});