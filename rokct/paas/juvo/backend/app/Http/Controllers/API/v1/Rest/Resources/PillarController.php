<?php
// app/Http/Controllers/API/v1/Rest/Resources/PillarController.php
namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Models\Pillar;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PillarController extends Controller
{
    public function index(Request $request)
    {
        $shop_id = $request->query('shop_id');
        $vision_id = $request->query('vision_id');
        
        $query = Pillar::with(['strategicObjectives']);
        
        if ($shop_id) {
            $query->where('shop_id', $shop_id);
        }
        
        if ($vision_id) {
            $query->where('vision_id', $vision_id);
        }
        
        $pillars = $query->orderBy('display_order')->get();
        
        return response()->json([
            'success' => true,
            'data' => $pillars
        ]);
    }
    
    public function show($uuid)
    {
        $pillar = Pillar::with(['strategicObjectives.kpis'])
            ->where('uuid', $uuid)
            ->first();
            
        if (!$pillar) {
            return response()->json([
                'success' => false,
                'message' => 'Pillar not found'
            ], 404);
        }
        
        return response()->json([
            'success' => true,
            'data' => $pillar
        ]);
    }
    
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'shop_id' => 'nullable|exists:shops,id',
            'vision_id' => 'required|exists:visions,id',
            'name' => 'required|string|max:100',
            'description' => 'nullable|string',
            'icon' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:20',
            'display_order' => 'nullable|integer'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $pillar = Pillar::create($request->all());
        
        return response()->json([
            'success' => true,
            'message' => 'Pillar created successfully',
            'data' => $pillar
        ], 201);
    }
    
    public function update(Request $request, $uuid)
    {
        $pillar = Pillar::where('uuid', $uuid)->first();
        
        if (!$pillar) {
            return response()->json([
                'success' => false,
                'message' => 'Pillar not found'
            ], 404);
        }
        
        $validator = Validator::make($request->all(), [
            'name' => 'string|max:100',
            'description' => 'nullable|string',
            'icon' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:20',
            'display_order' => 'nullable|integer'
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $pillar->update($request->only([
            'name', 
            'description', 
            'icon', 
            'color', 
            'display_order'
        ]));
        
        return response()->json([
            'success' => true,
            'message' => 'Pillar updated successfully',
            'data' => $pillar
        ]);
    }
    
    public function destroy($uuid)
    {
        $pillar = Pillar::where('uuid', $uuid)->first();
        
        if (!$pillar) {
            return response()->json([
                'success' => false,
                'message' => 'Pillar not found'
            ], 404);
        }
        
        $pillar->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Pillar deleted successfully'
        ]);
    }
}


