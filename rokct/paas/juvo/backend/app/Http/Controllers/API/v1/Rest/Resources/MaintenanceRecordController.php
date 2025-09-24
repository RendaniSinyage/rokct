<?php

namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreMaintenanceRecordRequest;
use App\Http\Resources\Api\MaintenanceRecordResource;
use App\Models\Resources\MaintenanceRecord;
use App\Models\Resources\ROSystem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class MaintenanceRecordController extends Controller
{
    /**
     * Get maintenance records for a shop
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = MaintenanceRecord::where('shop_id', $request->shop_id);

            // Filter by type if provided
            if ($request->has('type')) {
                $query->where('type', $request->type);
            }

            // Filter by reference_id if provided
            if ($request->has('reference_id')) {
                $query->where('reference_id', $request->reference_id);
            }

            // Get the latest records first
            $records = $query->latest()
                           ->paginate($request->per_page ?? 15);

            return response()->json([
                'data' => MaintenanceRecordResource::collection($records),
                'meta' => [
                    'current_page' => $records->currentPage(),
                    'last_page' => $records->lastPage(),
                    'per_page' => $records->perPage(),
                    'total' => $records->total()
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching maintenance records: ' . $e->getMessage(), [
                'shop_id' => $request->shop_id,
                'type' => $request->type ?? null,
                'error' => $e
            ]);

            return response()->json([
                'message' => 'Error fetching maintenance records',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a new maintenance record
     *
     * @param StoreMaintenanceRecordRequest $request
     * @return JsonResponse
     */
    public function store(StoreMaintenanceRecordRequest $request): JsonResponse
    {
        try {
            $record = MaintenanceRecord::create([
                'shop_id' => $request->shop_id,
                'type' => $request->type,
                'reference_id' => $request->reference_id,
                'maintenance_date' => $request->maintenance_date
            ]);

            // Update related models based on maintenance type
            $this->updateRelatedModels($record);

            return response()->json([
                'data' => new MaintenanceRecordResource($record),
                'message' => 'Maintenance record created successfully'
            ], 201);
        } catch (\Exception $e) {
            Log::error('Error creating maintenance record: ' . $e->getMessage(), [
                'shop_id' => $request->shop_id,
                'type' => $request->type,
                'reference_id' => $request->reference_id,
                'error' => $e
            ]);

            return response()->json([
                'message' => 'Error creating maintenance record',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get a specific maintenance record
     *
     * @param MaintenanceRecord $record
     * @return JsonResponse
     */
    public function show(MaintenanceRecord $record): JsonResponse
    {
        try {
            return response()->json([
                'data' => new MaintenanceRecordResource($record)
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching maintenance record: ' . $e->getMessage(), [
                'record_id' => $record->id,
                'error' => $e
            ]);

            return response()->json([
                'message' => 'Error fetching maintenance record',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update related models based on maintenance type
     *
     * @param MaintenanceRecord $record
     * @return void
     */
    private function updateRelatedModels(MaintenanceRecord $record): void
    {
        try {
            switch ($record->type) {
                case 'vessel':
                    $roSystem = ROSystem::whereHas('vessels', function ($query) use ($record) {
                        $query->where('external_id', $record->reference_id);
                    })->first();

                    if ($roSystem) {
                        $vessel = $roSystem->vessels()
                            ->where('external_id', $record->reference_id)
                            ->first();
                        
                        if ($vessel) {
                            $vessel->update([
                                'last_maintenance_date' => $record->maintenance_date,
                                'current_stage' => null,
                                'maintenance_start_time' => null
                            ]);
                        }
                    }
                    break;

                case 'membrane':
                    $roSystem = ROSystem::where('shop_id', $record->shop_id)->first();
                    if ($roSystem) {
                        $roSystem->update([
                            'membrane_installation_date' => $record->maintenance_date
                        ]);
                    }
                    break;

                case 'filter':
                    $roSystem = ROSystem::whereHas('filters', function ($query) use ($record) {
                        $query->where('external_id', $record->reference_id);
                    })->first();

                    if ($roSystem) {
                        $filter = $roSystem->filters()
                            ->where('external_id', $record->reference_id)
                            ->first();
                        
                        if ($filter) {
                            $filter->update([
                                'installation_date' => $record->maintenance_date
                            ]);
                        }
                    }
                    break;
            }
        } catch (\Exception $e) {
            Log::error('Error updating related models: ' . $e->getMessage(), [
                'record_id' => $record->id,
                'type' => $record->type,
                'reference_id' => $record->reference_id,
                'error' => $e
            ]);
            
            throw $e;
        }
    }

    /**
     * Get maintenance statistics
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function getStats(Request $request): JsonResponse
    {
        try {
            $stats = MaintenanceRecord::where('shop_id', $request->shop_id)
                ->selectRaw('type, COUNT(*) as count, MAX(maintenance_date) as last_maintenance')
                ->groupBy('type')
                ->get();

            return response()->json([
                'data' => $stats,
                'meta' => [
                    'total_records' => $stats->sum('count')
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching maintenance stats: ' . $e->getMessage(), [
                'shop_id' => $request->shop_id,
                'error' => $e
            ]);

            return response()->json([
                'message' => 'Error fetching maintenance statistics',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // PUT - Full update
public function update(UpdateMaintenanceRecordRequest $request, int $id): JsonResponse
{
    try {
        $record = MaintenanceRecord::findOrFail($id);
        $record->update($request->validated());
        return response()->json(['data' => new MaintenanceRecordResource($record)]);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Failed to update maintenance record',
            'error' => $e->getMessage()
        ], 500);
    }
}

// PATCH - Partial update
public function partialUpdate(Request $request, int $id): JsonResponse
{
    try {
        $record = MaintenanceRecord::findOrFail($id);
        // Only update provided fields
        return response()->json(['data' => new MaintenanceRecordResource($record)]);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Failed to update maintenance record',
            'error' => $e->getMessage()
        ], 500);
    }
}

// DELETE
public function destroy(int $id): JsonResponse
{
    try {
        $record = MaintenanceRecord::findOrFail($id);
        $record->delete();
        return response()->json(null, 204);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Failed to delete maintenance record',
            'error' => $e->getMessage()
        ], 500);
    }
}

// Batch Store
public function batchStore(BatchStoreMaintenanceRecordRequest $request): JsonResponse
{
    try {
        $records = collect($request->records)->map(function ($recordData) {
            return MaintenanceRecord::create($recordData);
        });
        return response()->json([
            'data' => MaintenanceRecordResource::collection($records)
        ], 201);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Failed to create maintenance records',
            'error' => $e->getMessage()
        ], 500);
    }
}
}
