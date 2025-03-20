<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Rental extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'tractor_id',
        'farmer_name',
        'farmer_phone',
        'farmer_address',
        'product_name',
        'rental_date',
        'land_size',
        'land_size_unit',
        'total_price',
        'status'
    ];

    // Relationship with User
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}