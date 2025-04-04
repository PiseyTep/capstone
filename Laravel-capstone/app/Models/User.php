<?php

namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasFactory;
    use HasApiTokens, Notifiable;

    // Role constants
    const ROLE_FARMER = 'farmer';
    const ROLE_ADMIN = 'admin';
    const ROLE_SUPER_ADMIN = 'super_admin';

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'phone_number',
        'approved',
        'approved_at',
        'firebase_uid', // Add this field to make it fillable
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'approved' => 'boolean',
        'approved_at' => 'datetime'
    ];

    // Relationship to rentals
    public function rentals()
    {
        return $this->hasMany(Rental::class);
    }

    // Helper methods for roles
    public function isFarmer()
    {
        return $this->role === self::ROLE_FARMER;
    }

    public function isAdmin()
    {
        return $this->role === self::ROLE_ADMIN;
    }

    public function isSuperAdmin()
    {
        return $this->role === self::ROLE_SUPER_ADMIN;
    }
    
    // In User model
    public function scopeActive($query)
    {
        return $query->where('last_active_at', '>=', now()->subDays(30));
    }

    public function scopeNewThisWeek($query)
    {
        return $query->where('created_at', '>=', now()->startOfWeek());
    }
}