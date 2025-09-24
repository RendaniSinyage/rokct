<?php
// app/Http/Controllers/API/v1/Rest/Resources/TodoTaskController.php
namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Models\TodoTask;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class TodoTaskController extends Controller
{
    public function index(Request $request)
    {
        $shop_id = $request->query('shop_id');
        $kpi_id = $request->query('kpi_id');
        $objective_id = $request->query('objective_id');
        $assigned_to = $request->query('assigned_to');
        $status = $request->query('status');
        $app_id = $request->query('app_id');
        
        $query = TodoTask::with(['kpi', 'strategicObjective', 'assignee', 'app']);
        
        if ($shop_id) {
            $query->where('shop_id', $shop_id);
        }
        
        if ($kpi_id) {
            $query->where('kpi_id', $kpi_id);
        }
        
        if ($objective_id) {
            $query->where('objective_id', $objective_id);
        }
        
        if ($assigned_to) {
            $query->where('assigned_to', $assigned_to);
        }
        
        if ($status) {
            $query->where('status', $status);
        }
        
        if ($app_id) {
            $query->where('app_id', $app_id);
        }
        
        $tasks = $query->orderBy('due_date')->get();
        
        return response()->json([
            'success' => true,
            'data' => $tasks
        ]);
    }
    
    public function show($uuid)
    {
        $task = TodoTask::with(['kpi', 'strategicObjective', 'assignee', 'app'])
            ->where('uuid', $uuid)
            ->first();
            
        if (!$task) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found'
            ], 404);
        }
        
        return response()->json([
            'success' => true,
            'data' => $task
        ]);
    }
    
    public function store(Request $request)
{
    $validator = Validator::make($request->all(), [
        'shop_id' => 'nullable|exists:shops,id',
        'kpi_id' => 'nullable|exists:kpis,id',
        'objective_id' => 'nullable|exists:strategic_objectives,id',
        'title' => 'required|string|max:255',
        'description' => 'nullable|string',
        'due_date' => 'nullable|date',
        'assigned_to' => 'nullable|exists:users,id',
        'status' => 'in:Todo,In Progress,Done,Blocked',
        'priority' => 'in:Low,Medium,High,Urgent',
        'app_id' => 'nullable|exists:apps,id',
        'roadmap_version' => 'nullable|string|max:50',
        'platforms' => 'nullable|array', // Make sure this validation is added
        'platforms.*' => 'string', // Validate each array element
    ]);
    
    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'message' => 'Validation failed',
            'errors' => $validator->errors()
        ], 422);
    }
    
    $task = TodoTask::create($request->all());
    
    return response()->json([
        'success' => true,
        'message' => 'Task created successfully',
        'data' => $task
    ], 201);
}
    
    public function update(Request $request, $uuid)
    {
        $task = TodoTask::where('uuid', $uuid)->first();
        
        if (!$task) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found'
            ], 404);
        }
        
        $validator = Validator::make($request->all(), [
            'kpi_id' => 'nullable|exists:kpis,id',
            'objective_id' => 'nullable|exists:strategic_objectives,id',
            'title' => 'string|max:255',
            'description' => 'nullable|string',
            'due_date' => 'nullable|date',
            'assigned_to' => 'nullable|exists:users,id',
            'status' => 'in:Todo,In Progress,Done,Blocked',
            'priority' => 'in:Low,Medium,High,Urgent',
            'app_id' => 'nullable|exists:apps,id',
            'roadmap_version' => 'nullable|string|max:50'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $task->update($request->only([
            'kpi_id', 
            'objective_id', 
            'title',
            'description',
            'due_date',
            'assigned_to',
            'status',
            'priority',
            'app_id',
            'roadmap_version'
        ]));
        
        return response()->json([
            'success' => true,
            'message' => 'Task updated successfully',
            'data' => $task
        ]);
    }
    
    public function destroy($uuid)
    {
        $task = TodoTask::where('uuid', $uuid)->first();
        
        if (!$task) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found'
            ], 404);
        }
        
        $task->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Task deleted successfully'
        ]);
    }
}
