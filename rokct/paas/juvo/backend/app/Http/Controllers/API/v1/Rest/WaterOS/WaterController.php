<?php

namespace App\Http\Controllers\API\v1\Rest\WaterOS;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\MeterReading;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\App;

class WaterController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'meterId' => 'required|string|max:50',
            'reading' => 'required|integer',
            'timestamp' => 'required|date_format:Y-m-d\TH:i:s\Z',
            'userId' => 'required|string|max:50',
            'shopId' => 'required|integer',
            'imagePath' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 400);
        }

        $meterReading = MeterReading::create($request->all());

        return response()->json(['message' => 'Meter reading saved successfully', 'meter_reading' => $meterReading], 201);
    }

    public function index(Request $request)
    {
        $meterId = $request->query('meterId');
        $startDate = $request->query('startDate');
        $endDate = $request->query('endDate');
        $perPage = $request->query('perPage', 15);
        $page = $request->query('page', 1);

        $query = MeterReading::query();

        if ($meterId) {
            $query->where('meterId', $meterId);
        }

        if ($startDate && $endDate) {
            $query->whereBetween('timestamp', [$startDate, $endDate]);
        }

        // Get the raw SQL query
        $sqlQuery = $query->toSql();
        $bindings = $query->getBindings();

        $readings = $query->paginate($perPage, ['*'], 'page', $page);

        // Get the total count of records in the database
        $totalCount = MeterReading::count();

        // Get table schema
        $tableSchema = Schema::getColumnListing('meter_readings');

        $response = [
            'meter_reading' => $readings->toArray(),
        ];

        // Include debug info and full pagination details only in non-production environments
        if (!App::environment('production')) {
            $response['debug_info'] = [
                'sql_query' => $sqlQuery,
                'bindings' => $bindings,
                'total_count_in_db' => $totalCount,
                'table_schema' => $tableSchema,
            ];
        } else {
            // In production, simplify the meter_reading structure
            $response['meter_reading'] = [
                'current_page' => $readings->currentPage(),
                'data' => $readings->items(),
                'per_page' => $readings->perPage(),
                'total' => $readings->total(),
            ];
        }

        return response()->json($response, 200);
    }

    public function show($id)
    {
        $meterReading = MeterReading::find($id);

        if (!$meterReading) {
            return response()->json(['message' => 'Meter reading not found'], 404);
        }

        return response()->json(['meter_reading' => $meterReading], 200);
    }

    // You can add update and delete methods here if needed

    public function update(Request $request, $id)
    {
        $meterReading = MeterReading::find($id);

        if (!$meterReading) {
            return response()->json(['message' => 'Meter reading not found'], 404);
        }

        $validator = Validator::make($request->all(), [
            'meterId' => 'string|max:50',
            'reading' => 'integer',
            'timestamp' => 'date_format:Y-m-d\TH:i:s\Z',
            'userId' => 'string|max:50',
            'shopId' => 'integer',
            'imagePath' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 400);
        }

        $meterReading->update($request->all());

        return response()->json(['message' => 'Meter reading updated successfully', 'meter_reading' => $meterReading], 200);
    }

    public function destroy($id)
    {
        $meterReading = MeterReading::find($id);

        if (!$meterReading) {
            return response()->json(['message' => 'Meter reading not found'], 404);
        }

        $meterReading->delete();

        return response()->json(['message' => 'Meter reading deleted successfully'], 200);
    }
}
