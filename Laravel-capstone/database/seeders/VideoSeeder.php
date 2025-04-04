<?php

namespace Database\Seeders;

use Illuminate\Support\Facades\DB; // Add this import
use Illuminate\Database\Seeder;

class VideoSeeder extends Seeder
{
    public function run()
    {
        // First clear existing data (optional)
        DB::table('videos')->truncate();

        // Then insert new data
        DB::table('videos')->insert([
            [
                'title' => 'Sample Video 1',
                'description' => 'Test description 1',
                'url' => 'https://example.com/video1',
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'title' => 'Sample Video 2',
                'description' => 'Test description 2',
                'url' => 'https://example.com/video2',
                'created_at' => now(),
                'updated_at' => now()
            ]
        ]);
    }
}