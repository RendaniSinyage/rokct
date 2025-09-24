<?php

namespace App\Http\Controllers\API\v1\Dashboard\User;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\PayfastUserCredentialResource;
use App\Models\Resources\PayfastCredential;
use Illuminate\Support\Facades\Log;

class PayfastCredentialController extends Controller
{
    public function getUserCredentials()
    {
        try {
            // Get the current environment credentials
            $credentials = PayfastCredential::currentEnvironment()->firstOrFail();

            return response()->json([
                'status' => true,
                'message' => 'Success',
                'data' => new PayfastUserCredentialResource($credentials),
            ]);
        } catch (\Exception $e) {
            Log::error('PayFast User Credentials Fetch Error: ' . $e->getMessage());

            return response()->json([
                'status' => false,
                'message' => 'Unable to retrieve PayFast credentials',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
