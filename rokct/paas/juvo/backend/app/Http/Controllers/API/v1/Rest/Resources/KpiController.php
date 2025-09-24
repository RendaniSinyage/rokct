<?php
// app/Http/Controllers/API/v1/Rest/Resources/KpiController.php
namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Models\Kpi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class KpiController extends Controller
{
    public function index(Request $request)
    {
        $shop_id = $request->query('shop_id');
        $objective_id = $request->query('objective_id');
        $status = $request->query('status');
        
        $query = Kpi::with(['strategicObjective']);
        
        if ($shop_id) {
            $query->where('shop_id', $shop_id);
        }
        
        if ($objective_id) {
            $query->where('objective_id', $objective_id);
        }
        
        if ($status) {
            $query->where('status', $status);
        }
        
        $kpis = $query->orderBy('due_date')->get();
        
        return response()->json([
            'success' => true,
            'data' => $kpis
        ]);
    }
    
    public function show($uuid)
    {
        $kpi = Kpi::with(['strategicObjective', 'tasks'])
            ->where('uuid', $uuid)
            ->first();
            
        if (!$kpi) {
            return response()->json([
                'success' => false,
                'message' => 'KPI not found'
            ], 404);
        }
        
        return response()->json([
            'success' => true,
            'data' => $kpi
        ]);
    }
    
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'shop_id' => 'nullable|exists:shops,id',
            'objective_id' => 'required|exists:strategic_objectives,id',
            'metric' => 'required|string|max:255',
            'target_value' => 'nullable|string|max:100',
            'current_value' => 'nullable|string|max:100',
            'unit' => 'nullable|string|max:50',
            'due_date' => 'required|date',
            'status' => 'in:Not Started,In Progress,Completed,Overdue',
            'completion_date' => 'nullable|date'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $kpi = Kpi::create($request->all());
        
        return response()->json([
            'success' => true,
            'message' => 'KPI created successfully',
            'data' => $kpi
        ], 201);
    }
    
    public function update(Request $request, $uuid)
    {
        $kpi = Kpi::where('uuid', $uuid)->first();
        
        if (!$kpi) {
            return response()->json([
                'success' => false,
                'message' => 'KPI not found'
            ], 404);
        }
        
        $validator = Validator::make($request->all(), [
            'metric' => 'string|max:255',
            'target_value' => 'nullable|string|max:100',
            'current_value' => 'nullable|string|max:100',
            'unit' => 'nullable|string|max:50',
            'due_date' => 'date',
            'status' => 'in:Not Started,In Progress,Completed,Overdue',
            'completion_date' => 'nullable|date'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $kpi->update($request->only([
            'metric', 
            'target_value', 
            'current_value',
            'unit',
            'due_date',
            'status',
            'completion_date'
        ]));
        
        return response()->json([
            'success' => true,
            'message' => 'KPI updated successfully',
            'data' => $kpi
        ]);
    }
    
    public function destroy($uuid)
    {
        $kpi = Kpi::where('uuid', $uuid)->first();
        
        if (!$kpi) {
            return response()->json([
                'success' => false,
                'message' => 'KPI not found'
            ], 404);
        }
        
        $kpi->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'KPI deleted successfully'
        ]);
    }
}
