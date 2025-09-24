<?php
// app/Http/Controllers/API/v1/Rest/Resources/VisionController.php
namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use Illuminate\Support\Str;
use App\Models\Vision;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class VisionController extends Controller
{
    public function index(Request $request)
{
    $shop_id = $request->query('shop_id');
    $user = auth()->user();
    $isAdmin = $user && ($user->role === 'admin' || $user->isAdmin);
    
    $query = Vision::with(['pillars']);
    
    // If shop_id is provided, filter by it
    if ($shop_id) {
        $query->where('shop_id', $shop_id);
    } 
    // If user is not admin and no shop_id provided, filter by user's shop
    else if (!$isAdmin && $user && $user->shop_id) {
        $query->where('shop_id', $user->shop_id);
    }
    // For admins with no shop_id, return all or most recent visions
    // No additional filters needed here - they get all visions
    
    $visions = $query->orderBy('created_at', 'desc')->get();
    
    return response()->json([
        'success' => true,
        'data' => $visions
    ]);
}
    
    public function show($uuid)
    {
        $vision = Vision::with(['pillars.strategicObjectives.kpis'])
            ->where('uuid', $uuid)
            ->first();
            
        if (!$vision) {
            return response()->json([
                'success' => false,
                'message' => 'Vision not found'
            ], 404);
        }
        
        return response()->json([
            'success' => true,
            'data' => $vision
        ]);
    }
    
   public function store(Request $request)
{
    // Validate the request
    $validated = $request->validate([
        'shop_id' => 'nullable|exists:shops,id',
        'statement' => 'required|string',
        'effective_date' => 'required|date',
        'end_date' => 'nullable|date',
        'is_active' => 'boolean',
        'created_by' => 'required|integer|exists:users,id',
    ]);
    
    // Debug what's being received
    \Log::info('Vision creation request:', $request->all());
    
    // Get the current authenticated user
    $user = auth()->user();
    
    // Create the vision with explicit assignment
    $vision = new Vision();
    
    // If shop_id is not provided but user has a shop, use user's shop_id
    if (empty($request->shop_id) && $user && $user->shop_id) {
        $vision->shop_id = $user->shop_id;
    } else {
        $vision->shop_id = $request->shop_id;
    }
    
    $vision->statement = $request->statement;
    $vision->effective_date = $request->effective_date;
    $vision->end_date = $request->end_date;
    $vision->is_active = $request->is_active;
    $vision->created_by = $request->created_by;
    $vision->uuid = Str::uuid();
    $vision->save();
    
    // Return the response
    return response()->json([
        'success' => true,
        'data' => $vision,
        'message' => 'Vision created successfully'
    ], 201);
}

public function getPlanOnPage($shop_id = null)
{
    $user = auth()->user();
    $isAdmin = $user && ($user->role === 'admin' || $user->isAdmin);
    
    // Get the active vision for this shop (or the latest one if none is specified as active)
    $query = Vision::with([
        'pillars' => function($query) {
            $query->orderBy('display_order');
        },
        'pillars.strategicObjectives' => function($query) {
            $query->where('status', '!=', 'Deferred')
                  ->orderBy('created_at', 'desc');
        },
        'pillars.strategicObjectives.kpis' => function($query) {
            $query->where('status', '!=', 'Completed')
                  ->orderBy('due_date');
        }
    ]);
    
    // Apply shop_id filter if provided or user is not admin
    if ($shop_id) {
        $query->where('shop_id', $shop_id);
    } else if (!$isAdmin && $user && $user->shop_id) {
        $query->where('shop_id', $user->shop_id);
    }
    
    // For active vision
    $query->where('is_active', true);
    
    // Get the latest vision
    $vision = $query->latest()->first();
    
    if (!$vision) {
        return response()->json([
            'success' => false,
            'message' => 'No active vision found'
        ], 404);
    }
    
    return response()->json([
        'success' => true,
        'data' => $vision
    ]);
}
    
    public function update(Request $request, $uuid)
    {
        $vision = Vision::where('uuid', $uuid)->first();
        
        if (!$vision) {
            return response()->json([
                'success' => false,
                'message' => 'Vision not found'
            ], 404);
        }
        
        $validator = Validator::make($request->all(), [
            'statement' => 'string',
            'effective_date' => 'date',
            'end_date' => 'nullable|date|after:effective_date',
            'is_active' => 'boolean'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $vision->update($request->only([
            'statement', 
            'effective_date', 
            'end_date', 
            'is_active'
        ]));
        
        return response()->json([
            'success' => true,
            'message' => 'Vision updated successfully',
            'data' => $vision
        ]);
    }
    
    public function destroy($uuid)
    {
        $vision = Vision::where('uuid', $uuid)->first();
        
        if (!$vision) {
            return response()->json([
                'success' => false,
                'message' => 'Vision not found'
            ], 404);
        }
        
        $vision->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Vision deleted successfully'
        ]);
    }
}


