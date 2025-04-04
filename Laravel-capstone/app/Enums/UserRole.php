<?php

namespace App\Enums;

enum UserRole: string {
    case FARMER = 'farmer';
    case ADMIN = 'admin';
    case SUPER_ADMIN = 'super_admin';
    
    public static function getValues(): array {
        return array_column(self::cases(), 'value');
    }
}