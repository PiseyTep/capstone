<?php

namespace Database\Seeders;

use App\Models\Rental;
use App\Models\User;
use Illuminate\Database\Seeder;

class TestDataSeeder extends Seeder
{
    public function run()
    {
        // Get the test farmer
        $farmer = User::where('email', 'farmer@example.com')->first();

        // Create test rentals
        Rental::create([
            'user_id' => $farmer->id,
            'tractor_id' => 'TRAC001',
            'farmer_name' => 'Test Farmer',
            'product_name' => 'Tractor Model X',
            'rental_date' => now()->addDays(7),
            'status' => 'pending'
        ]);

        Rental::create([
            'user_id' => $farmer->id,
            'tractor_id' => 'TRAC002',
            'farmer_name' => 'Test Farmer',
            'product_name' => 'Tractor Model Y',
            'rental_date' => now()->addDays(14),
            'status' => 'approved',
            'land_size' => 2.5,
            'land_size_unit' => 'hectare',
            'total_price' => 150.00
        ]);
    }
}