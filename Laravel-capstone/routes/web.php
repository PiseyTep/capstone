<?php

use App\Http\Controllers\SwaggerUIController;
use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

// Route::get('api/docs', [SwaggerUIController::class, 'index']);

Route::get('/', function () {
    return view('welcome');
});

// Route::get('/api-docs.json', function() {
//     return response()->file(storage_path('api-docs/api-docs.json'));
// });

// Route::prefix('admin')->group(function () {
//     Route::post('/register', [AuthController::class, 'adminRegister']);
//     Route::post('/login', [AuthController::class, 'login']);

//     Route::middleware(['auth:sanctum', 'role:admin,super_admin'])->group(function () {
//         Route::get('/dashboard', function () {
//             return view('admin.dashboard');
//         })->name('admin.dashboard');

//         Route::get('/user', [AuthController::class, 'userDetails']);
//         Route::post('/logout', [AuthController::class, 'logout']);
//     });
// });
// Route::get('/hello', function () {
//     return 'Hello World!';
// });
// Route::get('/api-debug', function () {
//     return response()->json([
//         'api_routes_file' => file_exists(base_path('routes/api.php')),
//         'provider_exists' => class_exists('App\Providers\RouteServiceProvider'),
//         'sample_routes' => collect(Route::getRoutes())->take(10)->map(function ($route) {
//             return [
//                 'uri' => $route->uri(),
//                 'methods' => $route->methods(),
//             ];
//         })
//     ]);
// });
// Route::get('/direct-api-test', function () {
//     return response()->json([
//         'message' => 'Direct API test from web routes',
//         'timestamp' => now()
//     ]);
// });


// // Add the auth endpoints that your Flutter app needs
// Route::post('/api/login', [AuthController::class, 'login']);
// Route::post('/api/register', [AuthController::class, 'register']);
// Route::get('/api/user', function (Request $request) {
//     return $request->user();
// })->middleware('auth:sanctum');
// Route::get('/provider-debug', function () {
//     $routeProvider = new \ReflectionClass(\App\Providers\RouteServiceProvider::class);
//     return response()->json([
//         'provider_methods' => collect($routeProvider->getMethods())
//             ->map(fn($method) => $method->getName())
//             ->toArray(),
//         'routes_directory_exists' => is_dir(base_path('routes')),
//         'api_file_exists' => file_exists(base_path('routes/api.php')),
//         'some_routes' => collect(\Illuminate\Support\Facades\Route::getRoutes())
//             ->take(5)
//             ->map(fn($route) => [
//                 'uri' => $route->uri(),
//                 'action' => $route->getActionName()
//             ])
//             ->toArray()
//     ]);
// });