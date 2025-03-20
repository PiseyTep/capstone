<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});
Route::prefix('admin')->group(function () {
    Route::post('/register', [AuthController::class, 'adminRegister']);
    Route::post('/login', [AuthController::class, 'login']); // Web dashboard login

    // Admin-only routes
    Route::middleware(['auth:sanctum', 'role:admin,super_admin'])->group(function () {
        Route::get('/user', [AuthController::class, 'userDetails']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});