<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Disable foreign key constraints temporarily
        DB::statement('SET FOREIGN_KEY_CHECKS=0');
        
        // Clear existing data
        $this->truncateTables();
        
        // Create test users
        $this->createTestUsers();
        
        // Call additional seeders
        $this->callSeeders();
        
        // Re-enable foreign key constraints
        DB::statement('SET FOREIGN_KEY_CHECKS=1');
    }

    protected function truncateTables(): void
    {
        User::truncate();
        // Add other tables if needed
        // \App\Models\Product::truncate();
    }

    protected function createTestUsers(): void
    {

            // Clear existing users if any
    User::query()->delete();

        // Create specific test users
        User::create([
            'name' => 'Admin User',
            'email' => 'admin@agritech.com',
            'password' => Hash::make('SecureAdmin123!'),
            'role' => 'admin',
            'phone_number' => '85512345678',
            'approved' => true,
            'email_verified_at' => now(),
            'approved_at' => now()
        ]);
    
        User::create([
            'name' => 'Demo Farmer',
            'email' => 'farmer@agritech.com',
            'password' => Hash::make('FarmerPass123!'),
            'role' => 'farmer',
            'phone_number' => '85587654321',
            'approved' => true,
            'email_verified_at' => now(),
            'approved_at' => now()
        ]);
         // Create test users WITHOUT factory for now
    for ($i = 1; $i <= 5; $i++) {
        User::create([
            'name' => 'Test Farmer '.$i,
            'email' => 'farmer'.$i.'@agritech.com',
            'password' => Hash::make('Password123!'),
            'role' => 'farmer',
            'phone_number' => '855'.rand(10000000, 99999999),
            'approved' => true,
            'email_verified_at' => now(),
            'approved_at' => now()
        ]);
    }
    
// Create test users with factory
try {
    \App\Models\User::factory()->count(5)->create();
    \App\Models\User::factory()->count(2)->admin()->create();
} catch (\Exception $e) {
    logger()->error('User seeding failed: '.$e->getMessage());
}
    }

    protected function callSeeders(): void
    {
        $this->call([
            ProductSeeder::class,
            VideoSeeder::class,
            RentalSeeder::class,
            // TestDataSeeder::class, // Only include if needed
        ]);
    }
}