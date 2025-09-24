<?php

namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreROSystemRequest;
use App\Http\Requests\Api\UpdateROSystemRequest;
use App\Http\Requests\Api\UpdateMembraneRequest;
use App\Http\Resources\Api\ROSystemResource;
use App\Models\Resources\ROSystem;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class ROSystemController extends Controller
{
    public function show(int $shopId): JsonResponse
    {
        $system = ROSystem::with(['vessels', 'filters'])
            ->where('shop_id', $shopId)
            ->first();

        if (!$system) {
            return response()->json(['data' => null], 200);
        }

        return response()->json([
            'data' => new ROSystemResource($system)
        ]);
    }

    public function store(StoreROSystemRequest $request): JsonResponse
{
    try {
        $result = DB::transaction(function () use ($request) {
            // Create or update RO System
            $system = ROSystem::updateOrCreate(
                ['shop_id' => $request->shop_id],
                [
                    'membrane_count' => $request->membrane_count,
                    'membrane_installation_date' => $request->membrane_installation_date,
                ]
            );

            // Delete existing vessels and filters
            $system->vessels()->delete();
            $system->filters()->delete();

            // Create vessels
            foreach ($request->vessels as $vesselData) {
                $system->vessels()->create([
                    'external_id' => $vesselData['id'],
                    'type' => $vesselData['type'],
                    'installation_date' => $vesselData['installation_date'],
                ]);
            }

            // Create filters
            foreach ($request->filters as $filterData) {
                $system->filters()->create([
                    'external_id' => $filterData['id'],
                    'type' => $filterData['type'],
                    'location' => $filterData['location'],
                    'installation_date' => $filterData['installation_date'],
                ]);
            }

            return $system->load(['vessels', 'filters']);
        });

        return response()->json([
            'data' => new ROSystemResource($result)
        ], 201);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Failed to create RO system',
            'error' => $e->getMessage()
        ], 500);
    }
}

public function updateVesselStage(UpdateVesselStageRequest $request, string $vesselId): JsonResponse 
    {
        try {
            $vessel = Vessel::where('external_id', $vesselId)->firstOrFail();
            
            $vessel->update([
                'current_stage' => $request->stage,
                'maintenance_start_time' => $request->start_time
            ]);

            return response()->json([
                'data' => new VesselResource($vessel),
                'message' => 'Vessel stage updated successfully'
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error updating vessel stage',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // PUT - Full update
public function update(UpdateROSystemRequest $request, int $id): JsonResponse
{
    try {
        $system = ROSystem::findOrFail($id);
        // Similar to store but updates existing
        return response()->json(['data' => new ROSystemResource($system)]);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Failed to update RO system',
            'error' => $e->getMessage()
        ], 500);
    }
}

// PATCH - Partial update
public function partialUpdate(Request $request, int $id): JsonResponse 
{
    try {
        $system = ROSystem::findOrFail($id);
        // Only update provided fields
        return response()->json(['data' => new ROSystemResource($system)]);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Failed to update RO system',
            'error' => $e->getMessage()
        ], 500);
    }
}

// DELETE
public function destroy(int $id): JsonResponse
{
    try {
        $system = ROSystem::findOrFail($id);
        $system->delete();
        return response()->json(null, 204);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Failed to delete RO system',
            'error' => $e->getMessage()
        ], 500);
    }
}

// Get Efficiency
public function getEfficiency(int $id): JsonResponse
{
    try {
        $system = ROSystem::findOrFail($id);
        $efficiency = ROSystemEfficiency::calculateSystemEfficiency($system);
        return response()->json(['data' => $efficiency]);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Failed to get efficiency',
            'error' => $e->getMessage()
        ], 500);
    }
}

// Get Maintenance History
public function getMaintenanceHistory(int $id): JsonResponse
{
    try {
        $system = ROSystem::findOrFail($id);
        $history = MaintenanceRecord::where('shop_id', $system->shop_id)->get();
        return response()->json(['data' => MaintenanceRecordResource::collection($history)]);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Failed to get maintenance history',
            'error' => $e->getMessage()
        ], 500);
    }
}

public function updateMembrane(UpdateMembraneRequest $request, int $systemId): JsonResponse 
{
    try {
        $system = ROSystem::findOrFail($systemId);
        
        $system->update([
            'membrane_count' => $request->membrane_count,
            'membrane_installation_date' => $request->membrane_installation_date
        ]);

        // Reload relations before returning
        $system->load(['vessels', 'filters']);

        return response()->json([
            'data' => new ROSystemResource($system),
            'message' => 'Membrane settings updated successfully'
        ]);
        
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Error updating membrane settings',
            'error' => $e->getMessage()
        ], 500);
    }
}
}


