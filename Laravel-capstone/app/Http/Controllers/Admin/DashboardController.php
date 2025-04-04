<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Video;
use App\Models\Product;
use App\Models\Rental;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    // Get dashboard statistics
    public function getStats()
    {
        // Get user counts
        $totalAdmins = User::whereIn('role', ['admin', 'super_admin'])->count();
        $totalFarmers = User::where('role', 'farmer')->count();
        $newFarmersThisMonth = User::where('role', 'farmer')
                                  ->whereMonth('created_at', now()->month)
                                  ->whereYear('created_at', now()->year)
                                  ->count();
        $pendingAdmins = User::where('role', 'admin')
                            ->where('approved', 0)
                            ->count();

        // Get product and rental stats
        $totalProducts = Product::count();
        $totalRentals = Rental::count();
        $activeRentals = Rental::whereIn('status', ['pending', 'approved'])->count();
        $pendingRentals = Rental::where('status', 'pending')->count();
        $completedRentals = Rental::where('status', 'completed')->count();
        $cancelledRentals = Rental::where('status', 'cancelled')->count();

        // Get revenue stats
        $totalRevenue = Rental::where('status', 'completed')->sum('total_price');
        $revenueThisMonth = Rental::where('status', 'completed')
                                 ->whereMonth('created_at', now()->month)
                                 ->whereYear('created_at', now()->year)
                                 ->sum('total_price');

        // Get video stats
        $totalVideos = Video::count();
        $newVideosThisMonth = Video::whereMonth('created_at', now()->month)
                                  ->whereYear('created_at', now()->year)
                                  ->count();

        // Get monthly rentals for chart
        $monthlyRentals = $this->getMonthlyRentalsData();

        return response()->json([
            'success' => true,
            'data' => [
                // User stats
                'adminAccount' => $totalAdmins,
                'totalFarmers' => $totalFarmers,
                'newFarmersThisMonth' => $newFarmersThisMonth,
                'pendingAdmins' => $pendingAdmins,
                
                // Product stats
                'totalMachines' => $totalProducts,
                
                // Rental stats
                'totalRentals' => $totalRentals,
                'activeRentals' => $activeRentals,
                'pendingRentals' => $pendingRentals,
                'completedRentals' => $completedRentals,
                'cancelledRentals' => $cancelledRentals,
                
                // Revenue stats
                'totalRevenue' => $totalRevenue,
                'revenueThisMonth' => $revenueThisMonth,
                
                // Video stats
                'totalVideos' => $totalVideos,
                'newVideosThisMonth' => $newVideosThisMonth,
                
                // Chart data
                'monthlyRentals' => $monthlyRentals,
            ]
        ]);
    }

    // Get recent activity for dashboard
    public function getRecentActivity()
    {
        // Get recent rentals
        $recentRentals = Rental::with(['user', 'product'])
                              ->orderBy('created_at', 'desc')
                              ->take(5)
                              ->get()
                              ->map(function ($rental) {
                                  return [
                                      'type' => 'rental',
                                      'id' => $rental->id,
                                      'title' => "{$rental->user->name} rented {$rental->product->name}",
                                      'date' => $rental->created_at->format('Y-m-d H:i:s'),
                                      'status' => $rental->status
                                  ];
                              });

        // Get recent user registrations
        $recentUsers = User::where('role', 'farmer')
                         ->orderBy('created_at', 'desc')
                         ->take(5)
                         ->get()
                         ->map(function ($user) {
                             return [
                                 'type' => 'user',
                                 'id' => $user->id,
                                 'title' => "New farmer registered: {$user->name}",
                                 'date' => $user->created_at->format('Y-m-d H:i:s'),
                             ];
                         });

        // Get recent videos
        $recentVideos = Video::orderBy('created_at', 'desc')
                           ->take(5)
                           ->get()
                           ->map(function ($video) {
                               return [
                                   'type' => 'video',
                                   'id' => $video->id,
                                   'title' => "New video added: {$video->title}",
                                   'date' => $video->created_at->format('Y-m-d H:i:s'),
                               ];
                           });

        // Combine and sort by date
        $activities = collect()
                      ->merge($recentRentals)
                      ->merge($recentUsers)
                      ->merge($recentVideos)
                      ->sortByDesc('date')
                      ->take(10)
                      ->values()
                      ->all();

        return response()->json([
            'success' => true,
            'data' => $activities
        ]);
    }

    // Get upcoming rentals
    public function getUpcomingRentals()
    {
        $upcomingRentals = Rental::with(['user', 'product'])
                                ->where('status', 'approved')
                                ->where('rental_date', '>=', now())
                                ->orderBy('rental_date', 'asc')
                                ->take(5)
                                ->get();

        return response()->json([
            'success' => true,
            'data' => $upcomingRentals
        ]);
    }

    // Helper method to get monthly rentals data for chart
    private function getMonthlyRentalsData()
    {
        $months = collect();
        
        // Get data for the last 6 months
        for ($i = 5; $i >= 0; $i--) {
            $date = Carbon::now()->subMonths($i);
            $monthName = $date->format('M');
            $year = $date->format('Y');
            
            $count = Rental::whereMonth('created_at', $date->month)
                          ->whereYear('created_at', $date->year)
                          ->count();
            
            $months->push([
                'month' => "{$monthName} {$year}",
                'count' => $count
            ]);
        }
        
        return $months;
    }
}