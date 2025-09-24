<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class SecureLoanDocumentAccess
{
    public function handle($request, Closure $next)
    {
        $user = Auth::user();
        $loanId = $request->route('loanId');

        // Verify user has access to this loan document
        $loanApplication = LoanApplication::where('id', $loanId)
            ->where('user_id', $user->id)
            ->first();

        if (!$loanApplication) {
            return response()->json([
                'error' => 'Unauthorized document access'
            ], 403);
        }

        return $next($request);
    }
}
