<?php

namespace App\Http\Controllers\API\v1\Dashboard\Admin;

use App\Helpers\ResponseError;
use App\Http\Requests\FilterParamsRequest;
use App\Http\Resources\DeliveryVehicleTypeResource;
use App\Models\DeliveryVehicleType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;
use Illuminate\Http\Request;

class DeliveryVehicleTypeController extends AdminBaseController
{
    /**
     * Display a listing of vehicle types
     */
    public function index(FilterParamsRequest $request): AnonymousResourceCollection
    {
        $vehicleTypes = DeliveryVehicleType::when($request->input('active'), function ($query, $active) {
                return $query->where('active', $active);
            })
            ->when($request->input('search'), function ($query, $search) {
                return $query->where('name', 'like', "%{$search}%")
                           ->orWhere('key', 'like', "%{$search}%");
            })
            ->orderBy($request->input('column', 'sort_order'), $request->input('sort', 'asc'))
            ->paginate($request->input('perPage', 15));

        return DeliveryVehicleTypeResource::collection($vehicleTypes);
    }

    /**
     * Store a new vehicle type
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'key' => [
                'required',
                'string',
                'max:50',
                'regex:/^[a-z_]+$/',
                Rule::unique('delivery_vehicle_types', 'key')
            ],
            'name' => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
            'active' => 'boolean',
            'sort_order' => 'integer|min:0',
            'max_weight_kg' => 'nullable|integer|min:1|max:50000',
            'base_rate' => 'nullable|numeric|min:0|max:9999.99'
        ]);

        $vehicleType = DeliveryVehicleType::create($request->all());

        return $this->successResponse(
            __('errors.' . ResponseError::RECORD_WAS_SUCCESSFULLY_CREATED, locale: $this->language),
            DeliveryVehicleTypeResource::make($vehicleType)
        );
    }

    /**
     * Display specific vehicle type
     */
    public function show(DeliveryVehicleType $vehicleType): JsonResponse
    {
        return $this->successResponse(
            __('errors.' . ResponseError::SUCCESS, locale: $this->language),
            DeliveryVehicleTypeResource::make($vehicleType->load('deliveryManSettings'))
        );
    }

    /**
     * Update vehicle type
     */
    public function update(DeliveryVehicleType $vehicleType, Request $request): JsonResponse
    {
        $request->validate([
            'key' => [
                'required',
                'string',
                'max:50',
                'regex:/^[a-z_]+$/',
                Rule::unique('delivery_vehicle_types', 'key')->ignore($vehicleType->id)
            ],
            'name' => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
            'active' => 'boolean',
            'sort_order' => 'integer|min:0',
            'max_weight_kg' => 'nullable|integer|min:1|max:50000',
            'base_rate' => 'nullable|numeric|min:0|max:9999.99'
        ]);

        $vehicleType->update($request->all());

        return $this->successResponse(
            __('errors.' . ResponseError::RECORD_WAS_SUCCESSFULLY_UPDATED, locale: $this->language),
            DeliveryVehicleTypeResource::make($vehicleType)
        );
    }

    /**
     * Toggle active status
     */
    public function toggleActive(DeliveryVehicleType $vehicleType): JsonResponse
    {
        $vehicleType->update(['active' => !$vehicleType->active]);

        return $this->successResponse(
            __('errors.' . ResponseError::RECORD_WAS_SUCCESSFULLY_UPDATED, locale: $this->language),
            DeliveryVehicleTypeResource::make($vehicleType)
        );
    }

    /**
     * Delete vehicle type
     */
    public function destroy(FilterParamsRequest $request): JsonResponse
    {
        $ids = $request->input('ids', []);

        // Check if any delivery personnel are using these vehicle types
        $inUse = \App\Models\DeliveryManSetting::whereIn('type_of_technique',
            DeliveryVehicleType::whereIn('id', $ids)->pluck('key')
        )->exists();

        if ($inUse) {
            return $this->onErrorResponse([
                'code' => ResponseError::ERROR_400,
                'message' => 'Cannot delete vehicle types that are in use by delivery personnel'
            ]);
        }

        DeliveryVehicleType::whereIn('id', $ids)->delete();

        return $this->successResponse(
            __('errors.' . ResponseError::RECORD_WAS_SUCCESSFULLY_DELETED, locale: $this->language)
        );
    }

    /**
     * Get vehicle types for dropdown (Enhanced version with weight/base data)
     */
    public function dropdown(): JsonResponse
    {
        $types = DeliveryVehicleType::where('active', true)
                                  ->orderBy('sort_order')
                                  ->get(['key', 'name', 'max_weight_kg', 'base_rate'])
                                  ->map(function ($type) {
                                      return [
                                          'key' => $type->key,
                                          'name' => $type->name,
                                          'maxWeight' => $type->max_weight_kg,
                                          'base' => $type->base_rate ? number_format($type->base_rate, 2, '.', '') : '0.00',
                                          // Also include alternative naming for flexibility
                                          'max_weight_kg' => $type->max_weight_kg,
                                          'base_rate' => $type->base_rate,
                                      ];
                                  });

        return response()->json([
            'success' => true,
            'data' => $types
        ]);
    }

    /**
     * Get simple dropdown (backward compatibility)
     */
    public function dropdownSimple(): JsonResponse
    {
        $types = DeliveryVehicleType::where('active', true)
                                  ->orderBy('sort_order')
                                  ->get(['key', 'name']);

        return response()->json([
            'success' => true,
            'data' => $types
        ]);
    }

    /**
     * Get retail vehicle types with enhanced data
     */
    public function retailTypes(): JsonResponse
    {
        $types = DeliveryVehicleType::where('active', true)
                                  ->where('max_weight_kg', '<=', 100)
                                  ->orderBy('sort_order')
                                  ->get(['key', 'name', 'max_weight_kg', 'base_rate'])
                                  ->map(function ($type) {
                                      return [
                                          'key' => $type->key,
                                          'name' => $type->name,
                                          'maxWeight' => $type->max_weight_kg,
                                          'base' => $type->base_rate ? number_format($type->base_rate, 2, '.', '') : '0.00',
                                          'max_weight_kg' => $type->max_weight_kg,
                                          'base_rate' => $type->base_rate,
                                      ];
                                  });

        return response()->json([
            'success' => true,
            'data' => $types
        ]);
    }

    /**
     * Get agricultural vehicle types with enhanced data
     */
    public function agricultureTypes(): JsonResponse
    {
        $types = DeliveryVehicleType::where('active', true)
                                  ->where('max_weight_kg', '>', 100)
                                  ->orderBy('sort_order')
                                  ->get(['key', 'name', 'max_weight_kg', 'base_rate'])
                                  ->map(function ($type) {
                                      return [
                                          'key' => $type->key,
                                          'name' => $type->name,
                                          'maxWeight' => $type->max_weight_kg,
                                          'base' => $type->base_rate ? number_format($type->base_rate, 2, '.', '') : '0.00',
                                          'max_weight_kg' => $type->max_weight_kg,
                                          'base_rate' => $type->base_rate,
                                      ];
                                  });

        return response()->json([
            'success' => true,
            'data' => $types
        ]);
    }
}

