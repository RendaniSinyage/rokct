<?php
// app/Http/Controllers/API/v1/Rest/Resources/StrategicObjectiveController.php
namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Models\StrategicObjective;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class StrategicObjectiveController extends Controller
{
    public function index(Request $request)
    {
        $shop_id = $request->query('shop_id');
        $pillar_id = $request->query('pillar_id');
        $is_90_day_priority = $request->query('is_90_day_priority');
        $time_horizon = $request->query('time_horizon');
        
        $query = StrategicObjective::with(['kpis', 'pillar']);
        
        if ($shop_id) {
            $query->where('shop_id', $shop_id);
        }
        
        if ($pillar_id) {
            $query->where('pillar_id', $pillar_id);
        }
        
        if ($is_90_day_priority !== null) {
            $query->where('is_90_day_priority', $is_90_day_priority);
        }
        
        if ($time_horizon) {
            $query->where('time_horizon', $time_horizon);
        }
        
        $objectives = $query->orderBy('created_at', 'desc')->get();
        
        return response()->json([
            'success' => true,
            'data' => $objectives
        ]);
    }
    
    public function show($uuid)
    {
        $objective = StrategicObjective::with(['kpis', 'pillar', 'tasks'])
            ->where('uuid', $uuid)
            ->first();
            
        if (!$objective) {
            return response()->json([
                'success' => false,
                'message' => 'Strategic objective not found'
            ], 404);
        }
        
        return response()->json([
            'success' => true,
            'data' => $objective
        ]);
    }
    
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'shop_id' => 'nullable|exists:shops,id',
            'pillar_id' => 'required|exists:pillars,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'is_90_day_priority' => 'boolean',
            'time_horizon' => 'in:Short-term,Medium-term,Long-term',
            'status' => 'in:Not Started,In Progress,Completed,Deferred',
            'start_date' => 'nullable|date',
            'target_date' => 'nullable|date',
            'completion_date' => 'nullable|date'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $objective = StrategicObjective::create($request->all());
        
        return response()->json([
            'success' => true,
            'message' => 'Strategic objective created successfully',
            'data' => $objective
        ], 201);
    }
    
    public function update(Request $request, $uuid)
    {
        $objective = StrategicObjective::where('uuid', $uuid)->first();
        
        if (!$objective) {
            return response()->json([
                'success' => false,
                'message' => 'Strategic objective not found'
            ], 404);
        }
        
        $validator = Validator::make($request->all(), [
            'title' => 'string|max:255',
            'description' => 'nullable|string',
            'is_90_day_priority' => 'boolean',
            'time_horizon' => 'in:Short-term,Medium-term,Long-term',
            'status' => 'in:Not Started,In Progress,Completed,Deferred',
            'start_date' => 'nullable|date',
            'target_date' => 'nullable|date',
            'completion_date' => 'nullable|date'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $objective->update($request->only([
            'title', 
            'description', 
            'is_90_day_priority',
            'time_horizon',
            'status',
            'start_date',
            'target_date',
            'completion_date'
        ]));
        
        return response()->json([
            'success' => true,
            'message' => 'Strategic objective updated successfully',
            'data' => $objective
        ]);
    }
    
    public function destroy($uuid)
    {
        $objective = StrategicObjective::where('uuid', $uuid)->first();
        
        if (!$objective) {
            return response()->json([
                'success' => false,
                'message' => 'Strategic objective not found'
            ], 404);
        }
        
        $objective->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Strategic objective deleted successfully'
        ]);
    }
}


