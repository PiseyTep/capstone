<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{
    AuthController,
    Admin\AdminController,
    Admin\SuperAdminController,
    Api\ProductController,
    Api\VideoController,
    Api\RentalController,
    Api\FarmerController,
    DeviceController,
    StatusController
};
use Illuminate\Http\Request;
use App\Http\Controllers\RouteDebugController;

// echo "Test";
// Route::get('/status', function() {
//     return response()->json(['success' => true, 'message' => 'API is running']);
// });



// Comprehensive API test routes

Route::get('/api/route-info', [RouteDebugController::class, 'echoRouteInfo']);

// Alternative route definitions for testing
// Route::any('/api/connectivity-test', function (Request $request) {
//     return response()->json([
//         'message' => 'Alternative API connection test',
//         'method' => $request->method(),
//         'path' => $request->path(),
//         'status' => 'online',
//         'timestamp' => now()->toIso8601String(),
//     ]);
// });


// /*
// |--------------------------------------------------------------------------
// | API Routes
// |--------------------------------------------------------------------------
// */


// // Test endpoints for API connectivity verification
Route::get('test', function () {
    return response()->json([
        'message' => 'API connection successful!',
        'status' => 'online',
        'timestamp' => now()->toIso8601String(),
    ]);
});




// Auth endpoints user farmer 
Route::post('register', [AuthController::class, 'register']);
Route::post('login', [AuthController::class, 'login']);
Route::post('admin/login', [AuthController::class, 'adminLogin']);
Route::post('admin/register', [AuthController::class, 'adminRegister']);

// Device endpoints
Route::get('devices', function() {
    return response()->json([
        'devices' => [],
        'message' => 'Device endpoint accessible',
        'status' => 'online'
    ]);
});
Route::post('devices', [DeviceController::class, 'register']);

// Public Content Routes
Route::get('products/public', [ProductController::class, 'publicIndex']);
Route::get('videos/public', [VideoController::class, 'publicIndex']);
Route::get('welcome', function() {
    return response()->json(['message' => 'Welcome to AgriTech API']);
});

// Authenticated User Routes
Route::middleware('auth:sanctum')->group(function () {
    // Common Authenticated Routes
    Route::post('logout', [AuthController::class, 'logout']);
    Route::get('user', [AuthController::class, 'userDetails']);
    Route::post('logout-device', [AuthController::class, 'logoutCurrentDevice']);
});


// Farmer Mobile App Routes
Route::middleware(['auth:sanctum', 'role:farmer'])->prefix('user')->group(function () {
    // Profile Management
    Route::prefix('profile')->group(function () {
        Route::get('/', [FarmerController::class, 'profile']);
        Route::put('/', [FarmerController::class, 'updateProfile']);
    });
    
    // Videos
    Route::get('videos', [VideoController::class, 'index']);
    Route::get('videos/{id}', [VideoController::class, 'show']);
    
    // Products
    Route::get('products', [ProductController::class, 'index']);
    Route::get('products/{id}', [ProductController::class, 'show']);
    
    // Rentals
    Route::get('rentals', [RentalController::class, 'index']);
    Route::post('rentals', [RentalController::class, 'store']);
    
    // Device Registration
    Route::post('register-device', [FarmerController::class, 'registerDevice']);
});

// Admin Routes
Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {
    // Admin Profile
    Route::get('profile', [AdminController::class, 'profile']);
    Route::post('logout', [AuthController::class, 'logout']);
    
    // Dashboard
    Route::get('stats', [AdminController::class, 'getStats']);
    
    // Resource Management
    Route::apiResource('farmers', AdminController::class)->except(['create', 'edit']);
    Route::apiResource('products', ProductController::class)->except(['create', 'edit']);
    Route::apiResource('videos', VideoController::class)->except(['create', 'edit']);
    
    // Rental Management
    Route::get('rentals/pending', [AdminController::class, 'pendingRentals']);
    Route::apiResource('rentals', RentalController::class)->except(['create', 'store', 'destroy']);
    Route::put('rentals/{id}/approve', [AdminController::class, 'approveRental']);
    
    // Notifications
    Route::post('send-notification', [AdminController::class, 'sendNotification']);
});

// Super Admin Routes
Route::middleware(['auth:sanctum', 'role:super_admin'])->prefix('admin')->group(function () {
    Route::apiResource('admins', SuperAdminController::class)->except(['create', 'edit']);
    
    Route::prefix('settings')->group(function () {
        Route::get('/', [SuperAdminController::class, 'getSettings']);
        Route::put('/', [SuperAdminController::class, 'updateSettings']);
    });
    
    Route::get('advanced-stats', [SuperAdminController::class, 'getAdvancedStats']);
});

// // Fallback Route - MUST BE LAST
// Route::fallback(function () {
//     $path = request()->path();
    
//     return response()->json([
//         'success' => false,
//         'message' => "API route not found: /$path",
//         'requested_url' => request()->url(),
//         'method' => request()->method(),
//     ], 404);
// });