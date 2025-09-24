<?php

namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreTankRequest;
use App\Http\Requests\Api\UpdateTankRequest;
use App\Http\Resources\Api\TankResource;
use App\Enums\TankStatus;
use App\Models\Resources\Tank;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TankController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = Tank::query();
            
            // Filter by shop_id if provided
            if ($request->has('shop_id')) {
                $query->where('shop_id', $request->shop_id);
            }
            
            $tanks = $query->get();
            
            return response()->json([
                'data' => TankResource::collection($tanks)
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to fetch tanks',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // Rest of the controller methods remain unchanged
    public function store(StoreTankRequest $request): JsonResponse
    {
        try {
            $tank = Tank::create($request->validated());

            return response()->json([
                'data' => new TankResource($tank)
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to create tank',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function update(UpdateTankRequest $request, Tank $tank): JsonResponse
    {
        try {
            $tank->update($request->validated());

            return response()->json([
                'data' => new TankResource($tank)
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to update tank',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function destroy(Tank $tank): JsonResponse
    {
        try {
            $tank->delete();
            return response()->json(null, 204);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to delete tank',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function updateStatus(Tank $tank, UpdateTankRequest $request)
    {
        $validated = $request->validated();
        \Log::info('Update Status Request', [
            'validated' => $validated,
            'tank_before' => $tank->toArray()
        ]);
        \Log::info('Time Debug', [
        'server_time' => date('Y-m-d H:i:s'),
        'laravel_now' => now(),
        'configured_timezone' => config('app.timezone')
    ]);
        
        $updateData = [
            'status' => $validated['status']
        ];
        
        if ($validated['status'] === TankStatus::Full->value) {
            $updateData['last_full'] = now();
        }

        $tank->update($updateData);
        
        \Log::info('Tank After Update', [
            'tank_after' => $tank->fresh()->toArray()
        ]);

        return new TankResource($tank);
    }

    public function updatePumpStatus(Tank $tank, UpdateTankRequest $request): JsonResponse
    {
        try {
            \Log::info('Update Pump Status Request', [
                'validated' => $request->validated(),
                'tank_before' => $tank->toArray()
            ]);
            
            $tank->update([
                'pump_status' => $request->validated()['pump_status']
            ]);
            
            \Log::info('Tank After Pump Update', [
                'tank_after' => $tank->fresh()->toArray()
            ]);

            return response()->json([
                'data' => new TankResource($tank)
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to update pump status',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
