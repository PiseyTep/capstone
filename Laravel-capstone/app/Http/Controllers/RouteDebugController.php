<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Log;

class RouteDebugController extends Controller
{    public function echoRouteInfo(Request $request)
    {
        return response()->json([
            'full_url' => $request->fullUrl(),
            'path' => $request->path(),
            'method' => $request->method(),
            'request_headers' => $request->headers->all()
        ]);
    }

    public function testApiConnectivity()
    {
        // Log all current routes for debugging
        $allRoutes = Route::getRoutes();
        $routeList = [];

        foreach ($allRoutes as $route) {
            $routeList[] = [
                'uri' => $route->uri(),
                'methods' => $route->methods(),
                'action' => $route->getActionName()
            ];
        }

        Log::info('Current Routes', $routeList);

        return response()->json([
            'message' => 'API connectivity test successful!',
            'routes' => $routeList,
            'status' => 'online',
            'timestamp' => now()->toIso8601String()
        ]);
    }

}