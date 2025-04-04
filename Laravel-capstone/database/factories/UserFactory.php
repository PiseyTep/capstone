<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class UserFactory extends Factory
{
    protected $model = User::class;

    public function definition()
    {
        return [
            'name' => $this->faker->name(),
            'email' => $this->faker->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => bcrypt('password'),
            'remember_token' => Str::random(10),
            'role' => 'farmer',
            'phone_number' => '855'.rand(10000000, 99999999),
            'approved' => true,
            'approved_at' => now(),
        ];
    }

    public function admin()
    {
        return $this->state([
            'role' => 'admin',
            'email' => 'admin_'.$this->faker->unique()->safeEmail()
        ]);
    }
}