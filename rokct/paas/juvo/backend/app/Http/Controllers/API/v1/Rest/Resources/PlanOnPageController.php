<?php
// app/Http/Controllers/API/v1/Rest/Resources/PlanOnPageController.php
namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Models\Vision;
use Illuminate\Http\Request;

class PlanOnPageController extends Controller
{
    /**
     * Get the complete Plan on a Page data structure
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request, $shop_id = null)
    {
        // Get the active vision for this shop (or the latest one if none is specified as active)
        $vision = Vision::with([
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
            ])
            ->when($shop_id, function($query) use ($shop_id) {
                return $query->where('shop_id', $shop_id);
            })
            ->where('is_active', true)
            ->latest()
            ->first();
        
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
}
