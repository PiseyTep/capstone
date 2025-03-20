<?php
// app/Http/Middleware/FarmerMiddleware.php
namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class FarmerMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        if (!auth()->check() || auth()->user()->role !== 'farmer') {
            return response()->json(['message' => 'Unauthorized access'], 403);
        }

        return $next($request);
    }
}