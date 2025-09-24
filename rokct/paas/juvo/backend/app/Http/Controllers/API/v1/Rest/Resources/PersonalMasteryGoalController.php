<?php
// app/Http/Controllers/API/v1/Rest/Resources/PersonalMasteryGoalController.php
namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Models\PersonalMasteryGoal;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PersonalMasteryGoalController extends Controller
{
    public function index(Request $request)
    {
        $user_id = $request->query('user_id');
        $area = $request->query('area');
        $status = $request->query('status');
        
        $query = PersonalMasteryGoal::with(['strategicObjective']);
        
        if ($user_id) {
            $query->where('user_id', $user_id);
        }
        
        if ($area) {
            $query->where('area', $area);
        }
        
        if ($status) {
            $query->where('status', $status);
        }
        
        $goals = $query->orderBy('created_at', 'desc')->get();
        
        return response()->json([
            'success' => true,
            'data' => $goals
        ]);
    }
    
    public function show($uuid)
    {
        $goal = PersonalMasteryGoal::with(['strategicObjective'])
            ->where('uuid', $uuid)
            ->first();
            
        if (!$goal) {
            return response()->json([
                'success' => false,
                'message' => 'Personal mastery goal not found'
            ], 404);
        }
        
        return response()->json([
            'success' => true,
            'data' => $goal
        ]);
    }
    
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
            'area' => 'required|in:Financial,Vocation/Work,Family,Friends,Spiritual,Physical,Learning & Skills',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'related_objective_id' => 'nullable|exists:strategic_objectives,id',
            'target_date' => 'nullable|date',
            'status' => 'in:Not Started,In Progress,Completed'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $goal = PersonalMasteryGoal::create($request->all());
        
        return response()->json([
            'success' => true,
            'message' => 'Personal mastery goal created successfully',
            'data' => $goal
        ], 201);
    }
    
    public function update(Request $request, $uuid)
    {
        $goal = PersonalMasteryGoal::where('uuid', $uuid)->first();
        
        if (!$goal) {
            return response()->json([
                'success' => false,
                'message' => 'Personal mastery goal not found'
            ], 404);
        }
        
        $validator = Validator::make($request->all(), [
            'area' => 'in:Financial,Vocation/Work,Family,Friends,Spiritual,Physical,Learning & Skills',
            'title' => 'string|max:255',
            'description' => 'nullable|string',
            'related_objective_id' => 'nullable|exists:strategic_objectives,id',
            'target_date' => 'nullable|date',
            'status' => 'in:Not Started,In Progress,Completed'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $goal->update($request->only([
            'area',
            'title',
            'description',
            'related_objective_id',
            'target_date',
            'status'
        ]));
        
        return response()->json([
            'success' => true,
            'message' => 'Personal mastery goal updated successfully',
            'data' => $goal
        ]);
    }
    
    public function destroy($uuid)
    {
        $goal = PersonalMasteryGoal::where('uuid', $uuid)->first();
        
        if (!$goal) {
            return response()->json([
                'success' => false,
                'message' => 'Personal mastery goal not found'
            ], 404);
        }
        
        $goal->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Personal mastery goal deleted successfully'
        ]);
    }
}
