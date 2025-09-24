<?php

namespace App\Http\Controllers\API\v1\Dashboard;


use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use App\Services\ERPGoIntegrationService;
use App\Http\Controllers\Controller;

class ERPGoController extends Controller
{
    private $integrationService;

    public function __construct(ERPGoIntegrationService $integrationService)
    {
        $this->integrationService = $integrationService;
    }

    /**
     * Connect seller to ERPGo with password confirmation
     * This is called from Flutter app
     */
    public function connect(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'password' => 'required|string',
            'confirm_connection' => 'required|boolean',
	    'shop_name' => 'nullable|string|max:255'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => 'validation_failed',
                'message' => $validator->errors()->first()
            ], 400);
        }

        $seller = auth()->user(); // This is the seller from Juvo
        
        // Check if already connected
        if ($seller->erpgo_connected) {
            return response()->json([
                'success' => false,
                'error' => 'already_connected',
                'message' => 'Already connected to ERPGo',
                'erpgo_login_url' => config('services.sling.base_url') . '/login'
            ]);
        }

        // Validate Juvo password (not Slingbolt password)
        if (!Hash::check($request->password, $seller->password)) {
            return response()->json([
                'success' => false,
                'error' => 'invalid_foodyman_password',
                'message' => 'Incorrect password. Please enter your Juvo account password.'
            ], 401);
        }

        // Password confirmed, proceed with ERPGo connection
        $result = $this->integrationService->connectSellerWithPassword($seller, $request->password, $request->shop_name);

        if ($result['success']) {
            $response = [
                'success' => true,
                'action' => $result['action'],
                'message' => $result['message'],
                'connected_at' => now()->toISOString()
            ];

            // If new account was created, provide ERPGo credentials
            if (isset($result['erpgo_credentials'])) {
                $response['erpgo_credentials'] = $result['erpgo_credentials'];
                $response['show_credentials'] = true;
            }

            return response()->json($response);
        }

        return response()->json($result, 400);
    }

    /**
     * Get ERPGo connection status
     */
    public function status(Request $request)
    {
        $seller = auth()->user();
        
        if (!$seller->erpgo_connected) {
            return response()->json([
                'connected' => false,
                'message' => 'Not connected to ERPGo'
            ]);
        }

        return response()->json([
            'connected' => true,
            'connected_at' => $seller->erpgo_connected_at,
            'erpgo_user_id' => $seller->erpgo_user_id,
            'erpgo_dashboard_url' => config('services.erpgo.base_url') . '/dashboard',
            'features_available' => [
                'inventory_management',
                'financial_reports',
                'employee_management',
                'project_tracking',
                'advanced_analytics'
            ]
        ]);
    }

    /**
     * Disconnect from ERPGo
     */
    public function disconnect(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'password' => 'required|string',
            'confirm_disconnect' => 'required|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => 'validation_failed',
                'message' => $validator->errors()->first()
            ], 400);
        }

        $seller = auth()->user();
        
        if (!$seller->erpgo_connected) {
            return response()->json([
                'success' => false,
                'error' => 'not_connected',
                'message' => 'Not connected to ERPGo'
            ]);
        }

        // Validate Juvo password for security
        if (!Hash::check($request->password, $seller->password)) {
            return response()->json([
                'success' => false,
                'error' => 'invalid_password',
                'message' => 'Incorrect password'
            ], 401);
        }

        $result = $this->integrationService->disconnectSeller($seller);

        return response()->json($result);
    }

    /**
     * Get Slingbolt dashboard data for display in Juvo
     */
    public function getDashboardData(Request $request)
    {
        $seller = auth()->user();
        
        if (!$seller->erpgo_connected) {
            return response()->json([
                'success' => false,
                'error' => 'not_connected',
                'message' => 'Not connected to ERPGo'
            ], 403);
        }

        try {
            $this->integrationService->refreshAccessToken();
            
            $client = new \GuzzleHttp\Client();
            $response = $client->get(config('services.erpgo.base_url') . '/api/external/dashboard', [
                'query' => [
                    'external_id' => $seller->id,
                    'external_platform' => 'juvo'
                ],
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->integrationService->getAccessToken(),
                    'Accept' => 'application/json',
                ]
            ]);

            $dashboardData = json_decode($response->getBody(), true);
            
            return response()->json([
                'success' => true,
                'dashboard_data' => $dashboardData,
                'last_updated' => now()->toISOString()
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get ERPGo dashboard data: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'dashboard_fetch_failed',
                'message' => 'Failed to load ERPGo dashboard data'
            ], 500);
        }
    }

    /**
     * Sync Juvo orders to Slingbolt
     */
    public function syncOrders(Request $request)
    {
        $seller = auth()->user();
        
        if (!$seller->erpgo_connected) {
            return response()->json([
                'success' => false,
                'error' => 'not_connected',
                'message' => 'Not connected to ERPGo'
            ], 403);
        }

        // Get recent orders from Juvo
        $orders = $seller->orders()
                        ->with(['items', 'customer'])
                        ->where('created_at', '>=', now()->subDays(30))
                        ->get();

        $syncData = [];
        foreach ($orders as $order) {
            $syncData[] = [
                'external_order_id' => $order->id,
                'customer_name' => $order->customer->name ?? 'Guest',
                'customer_email' => $order->customer->email ?? null,
                'total_amount' => $order->total_amount,
                'order_date' => $order->created_at->toISOString(),
                'status' => $order->status,
                'items' => $order->items->map(function ($item) {
                    return [
                        'name' => $item->name,
                        'quantity' => $item->quantity,
                        'price' => $item->price
                    ];
                })
            ];
        }

        try {
            $client = new \GuzzleHttp\Client();
            $response = $client->post(config('services.erpgo.base_url') . '/api/external/orders/sync', [
                'json' => [
                    'external_id' => $seller->id,
                    'external_platform' => 'juvo',
                    'orders' => $syncData
                ],
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->integrationService->getAccessToken(),
                    'Accept' => 'application/json',
                ]
            ]);

            $result = json_decode($response->getBody(), true);
            
            return response()->json([
                'success' => true,
                'synced_orders' => count($syncData),
                'message' => 'Orders synchronized successfully with ERPGo'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to sync orders to ERPGo: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'sync_failed',
                'message' => 'Failed to sync orders with ERPGo'
            ], 500);
        }
    }
}
