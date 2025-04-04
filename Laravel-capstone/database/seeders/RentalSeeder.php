<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class RentalSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    // database/seeders/RentalSeeder.php
public function run()
{
    \App\Models\Rental::factory(10)->create();
}
}
