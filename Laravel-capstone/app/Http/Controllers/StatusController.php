<?php
namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;

class StatusController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'timestamp' => now()->toIso8601String(),
            'environment' => app()->environment(),
        ]);
    }

    public function ping(): JsonResponse
    {
        return response()->json([
            'status' => 'pong',
            'timestamp' => now()->toIso8601String()
        ]);
    }
}