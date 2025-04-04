<?php

namespace App\Http\Middleware;

use Closure;
use Firebase\Auth\Token\Exception\InvalidToken;
use Kreait\Firebase\Auth as FirebaseAuth;

class VerifyFirebaseToken
{
    protected $auth;

    public function __construct(FirebaseAuth $auth)
    {
        $this->auth = $auth;
    }

    public function handle($request, Closure $next)
    {
        $bearer = $request->bearerToken();
        
        if (!$bearer) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        try {
            $verifiedIdToken = $this->auth->verifyIdToken($bearer);
            $uid = $verifiedIdToken->claims()->get('sub');
            
            // Add Firebase UID to request for controllers to use
            $request->merge(['firebase_uid' => $uid]);
            
            return $next($request);
        } catch (InvalidToken $e) {
            return response()->json(['message' => 'Invalid token: ' . $e->getMessage()], 401);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Unauthorized: ' . $e->getMessage()], 401);
        }
    }
}