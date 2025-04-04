<?php
// app/Http/Controllers/TestController.php
namespace App\Http\Controllers;

use Illuminate\Http\Request;

class TestController extends Controller
{
    public function testMethod()
    {
        return response()->json(['message' => 'API connection successful']);
    }
}
