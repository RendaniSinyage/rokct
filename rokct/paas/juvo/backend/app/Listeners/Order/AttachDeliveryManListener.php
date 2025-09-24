<?php

namespace App\Listeners\Order;

use App\Events\Order\AttachDeliveryMan;
use App\Helpers\NotificationHelper;
use App\Models\Order;
use App\Models\Settings;
use App\Models\User;
use App\Traits\Loggable;
use Exception;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AttachDeliveryManListener
{
    use Loggable;

    /**
     * Create the event listener.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event
     * @param AttachDeliveryMan $event
     * @return void
     */
    public function handle(AttachDeliveryMan $event): void
    {
        try {
            $order = $event->order;
            $second = Settings::where('key', 'deliveryman_order_acceptance_time')->first();

            if (!Cache::get('tvoirifgjn.seirvjrc') || data_get(Cache::get('tvoirifgjn.seirvjrc'), 'active') != 1) {
                abort(403);
            }

            if (empty($order) || $order->delivery_type === Order::DELIVERY) {
                return;
            }

            // SMART VEHICLE FILTERING BASED ON SHOP TYPE
            $shop = $order->shop;
            $requiredVehicles = $shop->getRequiredVehicleTypes();

            $users = User::with([
                'deliveryManSetting',
                'invitations' => fn($q) => $q->where('shop_id', $order->shop_id)
            ])
            ->whereHas('deliveryManSetting', function(Builder $query) use ($requiredVehicles) {
                $query->where('online', 1)
                      ->whereIn('type_of_technique', $requiredVehicles) // FILTER BY SHOP TYPE HERE
                      ->where(function ($q) {
                          $q->where('created_at', '>=', date('Y-m-d H:i', strtotime('-15 minutes')))
                            ->where('created_at', '<=', date('Y-m-d H:i'));
                      })
                      ->orWhere(function ($q) {
                          $q->where('updated_at', '>=', date('Y-m-d H:i', strtotime('-15 minutes')))
                            ->where('updated_at', '<=', date('Y-m-d H:i'));
                      })
                      ->orWhereBetween('updated_at', [
                          date('Y-m-d H:i', strtotime('-15 minutes')),
                          date('Y-m-d H:i')
                      ]);
            })
            ->whereHas('invitations', fn($q) => $q->where('shop_id', $order->shop_id))
            ->where('firebase_token', '!=', null)
            ->select(['firebase_token', 'id'])
            ->get();

            $serverKey = Settings::where('key', 'server_key')->pluck('value')->first();

            $headers = [
                'Authorization' => "key=$serverKey",
                'Content-Type'  => 'application/json'
            ];

            $result = [];
            $items = [];

            foreach ($users as $user) {
                /** @var User $user */
                if (!empty($order->deliveryman) ||
                    !$user->firebase_token ||
                    $user->invitations?->where('shop_id', $order->shop_id)?->first()?->shop_id !== $order->shop_id
                ) {
                    continue;
                }

                $items[] = [
                    'firebase_token' => $user->firebase_token,
                    'user' =>  $user,
                ];
            }

            // Notification based on shop type
            $shopType = $shop->type ?? 'retail';
            $shopTypeDisplay = $shop->type_display;
            
            foreach (collect($items)->sort(SORT_ASC) as $item) {
                $data = [
                    'registration_ids'  => is_array(data_get($item, 'firebase_token')) ? data_get($item, 'firebase_token') : [data_get($item, 'firebase_token')],
                    'notification'      => [
                        'title'         => "$shopTypeDisplay Order #$order->id",
                        'body'          => 'New delivery assignment available',
                    ],
                    'data'              => (new NotificationHelper)->deliveryManOrder($order)
                ];

                $result[] = Http::withHeaders($headers)->post('https://fcm.googleapis.com/fcm/send', $data)->json();

                sleep(data_get($second, 'value', 30));
            }

            Log::info("DELIVERY ATTACH TO ORDER #$order->id (Shop Type: $shopType, Vehicles: " . implode(',', $requiredVehicles) . ")", [
                'available_drivers' => count($items),
                'required_vehicles' => $requiredVehicles
            ]);
            
        } catch (Exception $e) {
            $this->error($e);
        }
    }
}
