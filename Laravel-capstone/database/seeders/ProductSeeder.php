<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    public function run()
    {
        $products = [
            [
                'name' => 'Compact Tractor',
                'description' => '25HP diesel tractor with loader',
                'price' => 18500.00,
                'category' => 'machinery',
                'stock' => 3,
                'image_url' => 'tractor.jpg'
            ],
            [
                'name' => 'Rotary Tiller',
                'description' => '5ft wide soil preparation implement',
                'price' => 1200.00,
                'category' => 'implements', 
                'stock' => 7,
                'image_url' => 'tiller.jpg'
            ],
            [
                'name' => 'Seed Drill',
                'description' => '12-row precision seeder',
                'price' => 4500.00,
                'category' => 'planting',
                'stock' => 2,
                'image_url' => 'seeder.jpg'
            ]
        ];

        foreach ($products as $product) {
            Product::updateOrCreate(
                ['name' => $product['name']], // Match by name
                $product                      // Update or create with all data
            );
        }
    }
}