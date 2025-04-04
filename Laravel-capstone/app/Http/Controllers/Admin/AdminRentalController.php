<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Rental;
use App\Models\User;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AdminRentalController extends Controller
{
    // Get all rentals with filtering options
    public function index(Request $request)
    {
        $query = Rental::with(['user', 'product']);
        
        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        
        // Filter by farmer
        if ($request->has('farmer_id')) {
            $query->where('user_id', $request->farmer_id);
        }
        
        // Filter by product
        if ($request->has('product_id')) {
            $query->where('product_id', $request->product_id);
        }
        
        // Filter by date range
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('rental_date', [$request->start_date, $request->end_date]);
        }
        
        // Get pending rentals only
        if ($request->has('pending') && $request->pending) {
            $query->where('status', 'pending');
        }
        
        // Order by date or creation
        $orderBy = $request->order_by ?? 'created_at';
        $orderDir = $request->order_dir ?? 'desc';
        
        $rentals = $query->orderBy($orderBy, $orderDir)->paginate(10);
        
        return response()->json([
            'success' => true,
            'data' => $rentals
        ]);
    }
    
    // Get pending rentals
    public function pendingRentals()
    {
        $rentals = Rental::with(['user', 'product'])
                       ->where('status', 'pending')
                       ->orderBy('created_at', 'desc')
                       ->paginate(10);
        
        return response()->json([
            'success' => true,
            'data' => $rentals
        ]);
    }
    
    // Get rental details
    public function show($id)
    {
        $rental = Rental::with(['user', 'product'])->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $rental
        ]);
    }
    
    // Approve a rental
    public function approveRental(Request $request, $id)
    {
        $rental = Rental::findOrFail($id);
        
        // Check if rental is in pending status
        if ($rental->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Only pending rentals can be approved'
            ], 400);
        }
        
        // Check if the product is available during the requested period
        $product = Product::findOrFail($rental->product_id);
        
        if (!$product->is_available) {
            return response()->json([
                'success' => false,
                'message' => 'Product is not available for rental'
            ], 400);
        }
        
        // Check for conflicting rentals
        $conflictingRentals = Rental::where('product_id', $rental->product_id)
                                   ->where('id', '!=', $rental->id)
                                   ->where('status', 'approved')
                                   ->where(function ($query) use ($rental) {
                                       $query->whereBetween('rental_date', [$rental->rental_date, $rental->return_date])
                                           ->orWhereBetween('return_date', [$rental->rental_date, $rental->return_date])
                                           ->orWhere(function ($query) use ($rental) {
                                               $query->where('rental_date', '<=', $rental->rental_date)
                                                   ->where('return_date', '>=', $rental->return_date);
                                           });
                                   })
                                   ->exists();
        
        if ($conflictingRentals) {
            return response()->json([
                'success' => false,
                'message' => 'Product is already booked during this period'
            ], 400);
        }
        
        // Update rental status to approved
        $rental->status = 'approved';
        $rental->admin_notes = $request->admin_notes ?? null;
        $rental->approved_by = $request->user()->id;
        $rental->approved_at = now();
        $rental->save();
        
        // Send notification to farmer (placeholder for actual implementation)
        // $this->sendApprovalNotification($rental);
        
        return response()->json([
            'success' => true,
            'message' => 'Rental approved successfully',
            'data' => $rental
        ]);
    }
    
    // Reject a rental
    public function rejectRental(Request $request, $id)
    {
        $rental = Rental::findOrFail($id);
        
        // Check if rental is in pending status
        if ($rental->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Only pending rentals can be rejected'
            ], 400);
        }
        
        // Validate request
        $validator = Validator::make($request->all(), [
            'rejection_reason' => 'required|string|max:255'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }
        
        // Update rental status to rejected
        $rental->status = 'rejected';
        $rental->admin_notes = $request->rejection_reason;
        $rental->rejected_by = $request->user()->id;
        $rental->rejected_at = now();
        $rental->save();
        
        // Send notification to farmer (placeholder for actual implementation)
        // $this->sendRejectionNotification($rental);
        
        return response()->json([
            'success' => true,
            'message' => 'Rental rejected successfully',
            'data' => $rental
        ]);
    }
    
    // Mark rental as completed
    public function completeRental($id)
    {
        $rental = Rental::findOrFail($id);
        
        // Check if rental is in approved status
        if ($rental->status !== 'approved') {
            return response()->json([
                'success' => false,
                'message' => 'Only approved rentals can be marked as completed'
            ], 400);
        }
        
        // Update rental status to completed
        $rental->status = 'completed';
        $rental->completed_at = now();
        $rental->save();
        
        return response()->json([
            'success' => true,
            'message' => 'Rental marked as completed',
            'data' => $rental
        ]);
    }
    
    // Get rental analytics
    public function getRentalAnalytics(Request $request)
    {
        // Date range filtering
        $startDate = $request->start_date ?? Carbon::now()->subMonths(6)->format('Y-m-d');
        $endDate = $request->end_date ?? Carbon::now()->format('Y-m-d');
        
        // Total rentals count by status
        $totalRentals = Rental::count();
        $pendingRentals = Rental::where('status', 'pending')->count();
        $approvedRentals = Rental::where('status', 'approved')->count();
        $completedRentals = Rental::where('status', 'completed')->count();
        $rejectedRentals = Rental::where('status', 'rejected')->count();
        $cancelledRentals = Rental::where('status', 'cancelled')->count();
        
        // Revenue stats
        $totalRevenue = Rental::where('status', 'completed')->sum('total_price');
        $revenueInRange = Rental::where('status', 'completed')
                                ->whereBetween('rental_date', [$startDate, $endDate])
                                ->sum('total_price');
        
        // Most popular products
        $popularProducts = Rental::select('product_id')
                                ->selectRaw('COUNT(*) as rental_count')
                                ->with('product:id,name')
                                ->groupBy('product_id')
                                ->orderByDesc('rental_count')
                                ->take(5)
                                ->get();
        
        // Monthly revenue data for chart
        $monthlyRevenue = Rental::where('status', 'completed')
                               ->whereBetween('rental_date', [$startDate, $endDate])
                               ->selectRaw('YEAR(rental_date) as year, MONTH(rental_date) as month, SUM(total_price) as total')
                               ->groupBy('year', 'month')
                               ->orderBy('year')
                               ->orderBy('month')
                               ->get()
                               ->map(function ($item) {
                                   return [
                                       'month' => Carbon::createFromDate($item->year, $item->month, 1)->format('M Y'),
                                       'total' => $item->total
                                   ];
                               });
        
        return response()->json([
            'success' => true,
            'data' => [
                'totalRentals' => $totalRentals,
                'pendingRentals' => $pendingRentals,
                'approvedRentals' => $approvedRentals,
                'completedRentals' => $completedRentals,
                'rejectedRentals' => $rejectedRentals,
                'cancelledRentals' => $cancelledRentals,
                'totalRevenue' => $totalRevenue,
                'revenueInRange' => $revenueInRange,
                'popularProducts' => $popularProducts,
                'monthlyRevenue' => $monthlyRevenue
            ]
        ]);
    }
}