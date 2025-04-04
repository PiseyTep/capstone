<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Authentication Defaults
    |--------------------------------------------------------------------------
    */
    'defaults' => [
        'guard' => env('AUTH_GUARD', 'api'), // Changed default to 'api'
        'passwords' => env('AUTH_PASSWORD_BROKER', 'users'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Authentication Guards
    |--------------------------------------------------------------------------
    */
    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],
        
        'api' => [
            'driver' => 'sanctum', // Using Sanctum for API auth
            'provider' => 'users',
            'hash' => false,
        ],
        
        'admin' => [ // Separate guard for admin routes
            'driver' => 'sanctum',
            'provider' => 'admins',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | User Providers
    |--------------------------------------------------------------------------
    */
    'providers' => [
        'users' => [
            'driver' => 'eloquent',
            'model' => App\Models\User::class,
        ],
        
        'admins' => [ // Separate provider for admin users
            'driver' => 'eloquent',
            'model' => App\Models\Admin::class, // Assuming you have an Admin model
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Resetting Passwords
    |--------------------------------------------------------------------------
    */
    'passwords' => [
        'users' => [
            'provider' => 'users',
            'table' => 'password_reset_tokens',
            'expire' => 60,
            'throttle' => 60,
        ],
        
        'admins' => [ // Separate password reset for admins
            'provider' => 'admins',
            'table' => 'admin_password_reset_tokens',
            'expire' => 30, // Shorter expiry for admin accounts
            'throttle' => 120,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Security Enhancements
    |--------------------------------------------------------------------------
    */
    'security' => [
        'password_requirements' => [
            'min_length' => env('PASSWORD_MIN_LENGTH', 10),
            'require_mixed_case' => true,
            'require_numbers' => true,
            'require_symbols' => true,
            'not_compromised' => true, // Check against breached passwords
        ],
        'login' => [
            'max_attempts' => env('LOGIN_MAX_ATTEMPTS', 5),
            'decay_minutes' => env('LOGIN_DECAY_MINUTES', 15),
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Email Verification
    |--------------------------------------------------------------------------
    */
    'verification' => [
        'expire' => env('EMAIL_VERIFY_EXPIRE', 1440), // 24 hours
        'throttle' => env('EMAIL_VERIFY_THROTTLE', 60), // 1 minute
    ],

    /*
    |--------------------------------------------------------------------------
    | Session Configuration
    |--------------------------------------------------------------------------
    */
    'session' => [
        'lifetime' => env('SESSION_LIFETIME', 120),
        'expire_on_close' => false,
        'encrypt' => true,
        'same_site' => 'lax',
    ],

    /*
    |--------------------------------------------------------------------------
    | Password Confirmation Timeout
    |--------------------------------------------------------------------------
    */
    'password_timeout' => env('AUTH_PASSWORD_TIMEOUT', 10800), // 3 hours

    /*
    |--------------------------------------------------------------------------
    | Must Verify Email
    |--------------------------------------------------------------------------
    */
    'must_verify_email' => env('MUST_VERIFY_EMAIL', true),
];