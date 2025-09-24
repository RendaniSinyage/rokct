<?php
// app/Http/Controllers/API/v1/Rest/Resources/RoadmapVersionController.php
namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Models\RoadmapVersion;
use App\Models\App;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RoadmapVersionController extends Controller
{
    public function index(Request $request)
    {
        $app_id = $request->query('app_id');
        $status = $request->query('status');
        
        $query = RoadmapVersion::with(['app']);
        
        if ($app_id) {
            $query->where('app_id', $app_id);
        }
        
        if ($status) {
            $query->where('status', $status);
        }
        
        // Order versions by semantic versioning (as much as possible in SQL)
        // This is a simplified approach, for complex version numbers, ordering should be handled in application code
        $versions = $query->orderByRaw('LENGTH(version_number), version_number DESC')->get();
        
        return response()->json([
            'success' => true,
            'data' => $versions
        ]);
    }
    
    public function show($uuid)
    {
        $version = RoadmapVersion::with(['app'])
            ->where('uuid', $uuid)
            ->first();
            
        if (!$version) {
            return response()->json([
                'success' => false,
                'message' => 'Roadmap version not found'
            ], 404);
        }
        
        return response()->json([
            'success' => true,
            'data' => $version
        ]);
    }
    
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'app_id' => 'required|exists:apps,id',
            'version_number' => 'required|string|max:50',
            'status' => 'in:Planning,Development,Testing,Released',
            'description' => 'nullable|string',
            'features' => 'nullable|array',
            'features.*' => 'string',
            'release_date' => 'nullable|date'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        // Check if this version number already exists for this app
        $existingVersion = RoadmapVersion::where('app_id', $request->app_id)
            ->where('version_number', $request->version_number)
            ->first();
            
        if ($existingVersion) {
            return response()->json([
                'success' => false,
                'message' => 'This version number already exists for this app'
            ], 422);
        }
        
        $version = RoadmapVersion::create($request->all());
        
        // If this is a released version, update the app's current version
        if ($request->status === 'Released') {
            $app = App::find($request->app_id);
            $app->current_version = $request->version_number;
            $app->save();
        }
        
        return response()->json([
            'success' => true,
            'message' => 'Roadmap version created successfully',
            'data' => $version
        ], 201);
    }
    
    public function update(Request $request, $uuid)
    {
        $version = RoadmapVersion::where('uuid', $uuid)->first();
        
        if (!$version) {
            return response()->json([
                'success' => false,
                'message' => 'Roadmap version not found'
            ], 404);
        }
        
        $validator = Validator::make($request->all(), [
            'version_number' => 'string|max:50',
            'status' => 'in:Planning,Development,Testing,Released',
            'description' => 'nullable|string',
            'features' => 'nullable|array',
            'features.*' => 'string',
            'release_date' => 'nullable|date'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        // If changing version number, verify it doesn't conflict
        if ($request->has('version_number') && $request->version_number !== $version->version_number) {
            $existingVersion = RoadmapVersion::where('app_id', $version->app_id)
                ->where('version_number', $request->version_number)
                ->first();
                
            if ($existingVersion) {
                return response()->json([
                    'success' => false,
                    'message' => 'This version number already exists for this app'
                ], 422);
            }
        }
        
        $version->update($request->only([
            'version_number',
            'status',
            'description',
            'features',
            'release_date'
        ]));
        
        // If this is now a released version, update the app's current version
        if ($request->status === 'Released') {
            $app = App::find($version->app_id);
            $app->current_version = $version->version_number;
            $app->save();
        }
        
        return response()->json([
            'success' => true,
            'message' => 'Roadmap version updated successfully',
            'data' => $version
        ]);
    }
    
    public function destroy($uuid)
    {
        $version = RoadmapVersion::where('uuid', $uuid)->first();
        
        if (!$version) {
            return response()->json([
                'success' => false,
                'message' => 'Roadmap version not found'
            ], 404);
        }
        
        // Check if tasks are linked to this version
        $tasksCount = $version->tasks()->count();
        if ($tasksCount > 0) {
            return response()->json([
                'success' => false,
                'message' => "Cannot delete version with $tasksCount associated tasks"
            ], 422);
        }
        
        $version->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Roadmap version deleted successfully'
        ]);
    }
}
