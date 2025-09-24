<?php
// app/Http/Controllers/API/v1/Rest/Resources/AppController.php
namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Models\App;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AppController extends Controller
{
    public function index(Request $request)
    {
        $shop_id = $request->query('shop_id');
        
        $query = App::with(['roadmapVersions' => function($query) {
            $query->orderBy('version_number', 'desc');
        }]);
        
        if ($shop_id) {
            $query->where('shop_id', $shop_id);
        }
        
        $apps = $query->orderBy('name')->get();
        
        return response()->json([
            'success' => true,
            'data' => $apps
        ]);
    }
    
    public function show($uuid)
    {
        $app = App::with(['roadmapVersions' => function($query) {
                $query->orderBy('version_number', 'desc');
            }])
            ->where('uuid', $uuid)
            ->first();
            
        if (!$app) {
            return response()->json([
                'success' => false,
                'message' => 'App not found'
            ], 404);
        }
        
        return response()->json([
            'success' => true,
            'data' => $app
        ]);
    }
    
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'shop_id' => 'nullable|exists:shops,id',
            'name' => 'required|string|max:100',
            'package_name' => 'nullable|string|max:100',
            'description' => 'nullable|string',
            'platform' => 'in:iOS,Android,Web,Cross-Platform',
            'icon' => 'nullable|string|max:255',
            'current_version' => 'nullable|string|max:50'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $app = App::create($request->all());
        
        return response()->json([
            'success' => true,
            'message' => 'App created successfully',
            'data' => $app
        ], 201);
    }
    
    public function update(Request $request, $uuid)
    {
        $app = App::where('uuid', $uuid)->first();
        
        if (!$app) {
            return response()->json([
                'success' => false,
                'message' => 'App not found'
            ], 404);
        }
        
        $validator = Validator::make($request->all(), [
            'name' => 'string|max:100',
            'package_name' => 'nullable|string|max:100',
            'description' => 'nullable|string',
            'platform' => 'in:iOS,Android,Web,Cross-Platform',
            'icon' => 'nullable|string|max:255',
            'current_version' => 'nullable|string|max:50'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $app->update($request->only([
            'name',
            'package_name',
            'description',
            'platform',
            'icon',
            'current_version'
        ]));
        
        return response()->json([
            'success' => true,
            'message' => 'App updated successfully',
            'data' => $app
        ]);
    }
    
    public function destroy($uuid)
    {
        $app = App::where('uuid', $uuid)->first();
        
        if (!$app) {
            return response()->json([
                'success' => false,
                'message' => 'App not found'
            ], 404);
        }
        
        $app->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'App deleted successfully'
        ]);
    }
}


