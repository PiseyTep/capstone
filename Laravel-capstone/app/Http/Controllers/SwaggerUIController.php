<?php

namespace App\Http\Controllers;

class SwaggerUIController extends Controller
{
    public function index()
    {
        return view('swagger-ui');
    }
}