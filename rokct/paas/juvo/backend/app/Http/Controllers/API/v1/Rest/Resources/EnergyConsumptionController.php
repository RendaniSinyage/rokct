<?php

namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Models\Shop;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use App\Http\Controllers\Controller;

class EnergyConsumptionController extends Controller
{
    public function index($shopId)
    {
        try {
            // Validate shop exists
            $shop = Shop::findOrFail($shopId);

            // Check energy type exists
            $energyTypeId = DB::table('expenses_type')
                ->where('name', 'energy')
                ->value('id');

            if (!$energyTypeId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Energy expense type not configured'
                ], 404);
            }

            $now = Carbon::now();
            $lastMonth = $now->copy()->subMonth();

            // Get all energy expenses for this shop, ordered by date
            $energyExpenses = DB::table('expenses')
                ->where('shop_id', $shopId)
                ->where('type_id', $energyTypeId)
                ->orderBy('created_at')
                ->get();

            // Calculate monthly consumptions
            $thisMonthConsumption = DB::table('expenses')
                ->where('shop_id', $shopId)
                ->where('type_id', $energyTypeId)
                ->whereYear('created_at', $now->year)
                ->whereMonth('created_at', $now->month)
                ->sum('kwh');

            $lastMonthConsumption = DB::table('expenses')
                ->where('shop_id', $shopId)
                ->where('type_id', $energyTypeId)
                ->whereYear('created_at', $lastMonth->year)
                ->whereMonth('created_at', $lastMonth->month)
                ->sum('kwh');

            // Calculate total consumption
            $totalConsumption = $energyExpenses->sum('kwh');

            // Calculate daily average
            $dailyAverage = $this->calculateDailyAverage($energyExpenses);

            return response()->json([
                'success' => true,
                'data' => [
                    'daily_average' => round($dailyAverage, 2),
                    'total_consumption' => round($totalConsumption, 2),
                    'this_month' => round($thisMonthConsumption, 2),
                    'last_month' => round($lastMonthConsumption, 2),
                    'consumption_entries' => $energyExpenses->count(),
                    'details' => $energyExpenses->map(function($expense) {
                        return [
                            'date' => $expense->created_at,
                            'kwh' => $expense->kwh
                        ];
                    })
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Energy Consumption Error', [
                'shop_id' => $shopId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Error processing request: ' . $e->getMessage()
            ], 500);
        }
    }

    private function calculateDailyAverage($energyExpenses)
    {
        if ($energyExpenses->isEmpty()) {
            return 0;
        }

        $totalDailyAverage = 0;
        $previousExpense = null;

        foreach ($energyExpenses as $expense) {
            $currentDate = Carbon::parse($expense->created_at);
            
            if ($previousExpense) {
                $previousDate = Carbon::parse($previousExpense->created_at);
                $daysBetween = $previousDate->diffInDays($currentDate);
                
                // Calculate daily average for previous expense
                $dailyAverage = $daysBetween > 0 
                    ? $previousExpense->kwh / $daysBetween 
                    : $previousExpense->kwh;
                
                $totalDailyAverage += $dailyAverage;
            }

            $previousExpense = $expense;
        }

        // Handle the last expense (use a default period if no subsequent expense)
        if ($previousExpense) {
            $lastDate = Carbon::parse($previousExpense->created_at);
            $nowDate = Carbon::now();
            $daysSinceLastExpense = $lastDate->diffInDays($nowDate);
            
            $lastDailyAverage = $daysSinceLastExpense > 0
                ? $previousExpense->kwh / $daysSinceLastExpense
                : $previousExpense->kwh;
            
            $totalDailyAverage += $lastDailyAverage;
        }

        // Average out the daily averages
        $averageCount = $energyExpenses->count() > 1 
            ? $energyExpenses->count() - 1 
            : 1;
        
        return $totalDailyAverage / $averageCount;
    }
}
