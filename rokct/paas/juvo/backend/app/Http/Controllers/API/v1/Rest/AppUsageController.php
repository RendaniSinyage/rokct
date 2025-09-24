<?php

namespace App\Http\Controllers\API\v1\Rest;

use App\Http\Controllers\Controller;
use App\Models\AppUsage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class AppUsageController extends Controller
{
    /**
     * Record app usage for the current user and date
     */
    public function recordUsage(Request $request)
    {
        $validated = $request->validate([
            'platform' => 'nullable|string|max:30',
            'app_version' => 'nullable|string|max:20',
            'build_number' => 'nullable|string|max:20',
        ]);

        // Get authenticated user
        $user = Auth::user();
        
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }
        
        $today = Carbon::today();
        
        // Create or update the usage record for today
        AppUsage::updateOrCreate(
            [
                'user_id' => $user->id,
                'usage_date' => $today,
            ],
            [
                'year' => $today->year,
                'platform' => $validated['platform'] ?? null,
                'app_version' => $validated['app_version'] ?? null,
                'build_number' => $validated['build_number'] ?? null,
            ]
        );

        // Get stats for the current year
        $yearlyStats = $this->getYearlyStats($user->id);
        
        return response()->json([
            'success' => true,
            'data' => $yearlyStats
        ]);
    }
    
    /**
     * Get app usage statistics for the current year
     */
    public function getYearlyStats($userId = null)
    {
        if ($userId === null) {
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthenticated',
                ], 401);
            }
            $userId = $user->id;
        }
        
        $currentYear = Carbon::now()->year;
        
        // Count unique days for current year
        $daysCount = AppUsage::where('user_id', $userId)
            ->where('year', $currentYear)
            ->count();
            
        // Get first usage date for this year
        $firstUsage = AppUsage::where('user_id', $userId)
            ->where('year', $currentYear)
            ->orderBy('usage_date', 'asc')
            ->first();
            
        // Get most recent usage date (excluding today)
        $lastUsage = AppUsage::where('user_id', $userId)
            ->where('year', $currentYear)
            ->where('usage_date', '<', Carbon::today())
            ->orderBy('usage_date', 'desc')
            ->first();
            
        return [
            'days_in_app_this_year' => $daysCount,
            'first_usage_date' => $firstUsage ? $firstUsage->usage_date->format('Y-m-d') : null,
            'last_usage_date' => $lastUsage ? $lastUsage->usage_date->format('Y-m-d') : null,
            'current_year' => $currentYear,
        ];
    }
    
    /**
     * Get app usage statistics
     */
    public function getStats()
    {
        $user = Auth::user();
        
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }
        
        $yearlyStats = $this->getYearlyStats($user->id);
        
        return response()->json([
            'success' => true,
            'data' => $yearlyStats
        ]);
    }
}
