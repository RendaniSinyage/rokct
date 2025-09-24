<?php

namespace App\Http\Controllers\API\v1\Dashboard\Admin;

use App\Http\Controllers\Controller;
use App\Models\Shop;
use App\Models\Order;
use App\Models\Resources\Tank;
use App\Models\Resources\ROSystem;
use App\Models\StockVolume;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class ShopDashboardController extends Controller
{
    /**
     * Get summary data for all shops with RO systems
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function summary(Request $request)
{
    try {
        // Get all shops that have RO systems
        $shopIds = ROSystem::pluck('shop_id')->unique();
        
        $result = [];

        foreach ($shopIds as $shopId) {
            // Basic shop info
            $shop = Shop::find($shopId);
            if (!$shop) continue;

            // Get RO system
            $roSystem = ROSystem::where('shop_id', $shopId)->first();
            if (!$roSystem) continue;

            // Get tanks
            $tanks = Tank::where('shop_id', $shopId)->get();

            // Calculate tank statuses
            $tankStatuses = [
                'raw' => [],
                'purified' => []
            ];

            // Group raw tanks by type
            $rawTanks = $tanks->where('type', 'raw');
            $tankStatuses['raw']['tank_count'] = $rawTanks->count();
            $tankStatuses['raw']['tanks'] = $rawTanks->map(function($tank) {
                return [
                    'id' => $tank->id,
                    'number' => $tank->number,
                    'status' => $tank->status,
                    'capacity' => $tank->capacity
                ];
            });

            // Group purified tanks
            $purifiedTanks = $tanks->where('type', 'purified');
            $tankStatuses['purified']['tank_count'] = $purifiedTanks->count();
            
            // Calculate total capacity of all purified tanks
            $totalPurifiedCapacity = $purifiedTanks->sum('capacity');
            
            // Calculate monthly usage (for statistics)
            $thisMonthUsage = $this->calculateWaterUsageFromStockVolumes(
                $shopId, 
                now()->startOfMonth(), 
                now()
            );
            
            $lastMonth = now()->subMonth();
            $lastMonthUsage = $this->calculateWaterUsageFromStockVolumes(
                $shopId, 
                $lastMonth->startOfMonth(), 
                $lastMonth->endOfMonth()
            );
            
            // Create tank details for each purified tank
            $purifiedTankDetails = [];
            
            foreach ($purifiedTanks as $tank) {
                $tankCapacity = (float)$tank->capacity;
                
                // Calculate usage since this tank was last full
                $lastFullDate = $tank->last_full ?? now()->startOfMonth();
                $tankUsageFromLastFull = $this->calculateWaterUsageFromStockVolumes(
                    $shopId, 
                    $lastFullDate, 
                    now()
                );
                
                // Each tank has its own usage calculation based on its last_full date
                $tankUsedCapacity = min($tankUsageFromLastFull, $tankCapacity);
                $tankRemainingCapacity = max(0, $tankCapacity - $tankUsedCapacity);
                
                $purifiedTankDetails[$tank->number] = [
                    'id' => $tank->id,
                    'number' => $tank->number,
                    'total_capacity' => $tankCapacity,
                    'remaining_capacity' => $tankRemainingCapacity,
                    'used_capacity' => $tankUsedCapacity,
                    'last_full' => $lastFullDate->toIso8601String() // Include this for reference
                ];
            }
            
            $tankStatuses['purified']['tanks'] = $purifiedTankDetails;

            // Prepare shop data to return
            $shopData = [
                'id' => $shop->id,
                'name' => $shop->translation ? $shop->translation->title : ($shop->name ?? 'Unknown Shop'),
                'logo_img' => $shop->logo_img ?? '',
                'tank_statuses' => $tankStatuses,
                'usage_this_month' => $thisMonthUsage,
                'last_month_usage' => $lastMonthUsage,
                'system_efficiency' => null,
                'order_count' => Order::where('shop_id', $shopId)
                    ->where('created_at', '>=', now()->subDays(30))
                    ->count()
            ];

            $result[] = $shopData;
        }

        return response()->json([
            'success' => true,
            'data' => $result
        ]);
    } catch (\Exception $e) {
        Log::error('Shop Dashboard Summary Error', [
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);

        return response()->json([
            'success' => false,
            'message' => 'Error retrieving shop dashboard summary: ' . $e->getMessage()
        ], 500);
    }
}


private function calculateWaterUsageFromStockVolumes($shopId, $startDate, $endDate)
{
    try {
        // Log the date range for debugging
        Log::info('Calculating water usage', [
            'shop_id' => $shopId, 
            'start_date' => $startDate->toDateTimeString(), 
            'end_date' => $endDate->toDateTimeString()
        ]);
        
        // Get StockVolumes for this shop
        $stockVolumes = StockVolume::where('shop_id', $shopId)->get();
        
        // Find orders for the specific shop and time period
        $orders = Order::where('shop_id', $shopId)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->with('orderDetails')
            ->get();
            
        Log::info('Found orders', ['count' => $orders->count()]);

        $totalUsage = 0;

        foreach ($orders as $order) {
            foreach ($order->orderDetails as $detail) {
                $stockId = (string)$detail->stock_id;
                $quantity = $detail->quantity ?? 0;

                // Find matching volume from stock volumes
                $matchingVolume = $stockVolumes->first(function ($volume) use ($stockId) {
                    return in_array($stockId, explode(', ', $volume->stock_ids));
                });

                $waterVolume = $matchingVolume ? $matchingVolume->volume : 0;
                $itemUsage = $waterVolume * $quantity;
                $totalUsage += $itemUsage;
                
                Log::info('Order detail usage', [
                    'order_id' => $order->id,
                    'stock_id' => $stockId,
                    'quantity' => $quantity,
                    'volume' => $waterVolume,
                    'usage' => $itemUsage
                ]);
            }
        }
        
        Log::info('Total usage calculated', ['total' => $totalUsage]);
        return $totalUsage;
    } catch (\Exception $e) {
        Log::error('Water Usage Calculation Error', [
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        return 0;
    }
}

    /**
     * Calculate water usage for a shop in a specific month
     *
     * @param int $shopId
     * @param int $year
     * @param int $month
     * @return float
     */
    private function calculateWaterUsage($shopId, $year, $month)
{
    try {
        // Find orders for the specific shop and time period
        $orders = Order::where('shop_id', $shopId)
            ->whereYear('created_at', $year)
            ->whereMonth('created_at', $month)
            ->get();

        // Fetch stock volumes for this specific shop
        $stockVolumes = StockVolume::where('shop_id', $shopId)->get();

        $totalUsage = 0;

        foreach ($orders as $order) {
            $orderDetails = $order->orderDetails;

            foreach ($orderDetails as $detail) {
                $stockId = (string)$detail->stock_id;
                $quantity = $detail->quantity ?? 0;

                // Find matching volume from database
                $matchingVolume = $stockVolumes->first(function ($volume) use ($stockId) {
                    return in_array($stockId, explode(', ', $volume->stock_ids));
                });

                $waterVolume = $matchingVolume ? $matchingVolume->volume : 0;
                $totalUsage += $waterVolume * $quantity;
            }
        }

        return $totalUsage;
    } catch (\Exception $e) {
        Log::error('Water Usage Calculation Error', [
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        return 0;
    }
}


    /**
     * Calculate RO system efficiency
     *
     * @param ROSystem $roSystem
     * @return float
     */
    private function calculateSystemEfficiency(ROSystem $roSystem)
{
    try {
        $now = Carbon::now();
        
        // Check vessel efficiency
        $vesselEfficiency = 0;
        $vesselCount = $roSystem->vessels->count();
        if ($vesselCount > 0) {
            foreach ($roSystem->vessels as $vessel) {
                $installationAge = $now->diffInDays($vessel->installation_date);
                $maintenanceAge = $vessel->last_maintenance_date ? 
                    $now->diffInDays($vessel->last_maintenance_date) : $installationAge;
                
                // Vessels lose efficiency over time
                $ageEfficiency = max(0, 100 - ($installationAge / 365 * 20)); // 20% drop per year
                
                // Maintenance improves efficiency
                $maintEfficiency = max(0, 100 - ($maintenanceAge / 30 * 10)); // 10% drop per month since last maintenance
                
                $vesselEfficiency += ($ageEfficiency * 0.7) + ($maintEfficiency * 0.3); // Weighted average
            }
            $vesselEfficiency /= $vesselCount;
        }
        
        // Check filter efficiency
        // ... [rest of the method]
    } catch (\Exception $e) {
        Log::error('Error calculating system efficiency: ' . $e->getMessage());
        return 0;
    }
}
}
