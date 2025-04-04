<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Device extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'device_token',
        'platform',
        'device_model',
        'device_os_version'
    ];

    protected $hidden = [
        'id',
        'created_at',
        'updated_at'
    ];

    // Optional: Relationship with User
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}