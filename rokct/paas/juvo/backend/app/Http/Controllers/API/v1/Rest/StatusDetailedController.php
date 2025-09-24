<?php

namespace App\Http\Controllers\API\v1\Rest;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class StatusController extends Controller
{
    public function status(): JsonResponse
    {
        $juvoStatus = $this->getJuvoStatus();
        $payfastStatus = $this->getPayfastStatus();
        $paystackStatus = $this->getPaystackStatus();
        $flutterwaveStatus = $this->getFlutterwaveStatus();

        $responseData = [
            'juvo_platform' => $juvoStatus,
            'payfast' => $payfastStatus,
            'paystack' => $paystackStatus,
            'flutterwave' => $flutterwaveStatus,
        ];

        return response()->json($responseData);
    }

    private function getJuvoStatus(): array
    {
        return [
            'status' => 'OK',
            'uptime' => $this->getUptime(),
            'last_restart' => $this->getLastRestart(),
            'version' => env('PROJECT_V', 'unknown'),
            'maintenance' => $this->getMaintenanceInfo(),
            'juvo_web' => $this->getNextJsStatus(),
            'main_website' => $this->getMainWebsiteStatus(),
            'admin_panel' => $this->getAdminPanelStatus(),
            'juvo_agency' => $this->getAgencyWebsiteStatus(),
            'one_platform' => $this->getOnePlatformStatus(),
            'juvo_one_landing' => $this->getOneLandingStatus(),
            'wateros' => $this->getWaterOsStatus(),
            'image_server' => $this->getImageServerStatus(),
        ];
    }

    private function getUptime(): string
    {
        $uptime = shell_exec('cut -d. -f1 /proc/uptime');
        $uptimeSeconds = (int)$uptime;
        $days = floor($uptimeSeconds / 86400);
        $hours = floor(($uptimeSeconds % 86400) / 3600);
        $minutes = floor(($uptimeSeconds % 3600) / 60);
        $seconds = $uptimeSeconds % 60;

        return sprintf('%02d:%02d:%02d:%02d', $days, $hours, $minutes, $seconds);
    }

    private function getLastRestart(): string
    {
        $bootTime = $this->getServerBootTime();
        return Carbon::createFromTimestamp($bootTime)->diffForHumans();
    }

    private function getServerBootTime(): int
    {
        if (PHP_OS_FAMILY === 'Linux') {
            return (int) shell_exec('stat -c %Y /proc/1');
        } elseif (PHP_OS_FAMILY === 'Darwin') {  // macOS
            $bootTime = shell_exec('sysctl -n kern.boottime | cut -d" " -f4 | cut -d"," -f1');
            return (int) $bootTime;
        } elseif (PHP_OS_FAMILY === 'Windows') {
            $wmi = new \COM('WinMgmts:\\\\.');
            $query = "SELECT LastBootUpTime FROM Win32_OperatingSystem";
            $result = $wmi->ExecQuery($query);
            foreach ($result as $item) {
                $bootTime = substr($item->LastBootUpTime, 0, 14);
                return strtotime($bootTime);
            }
        }
        
        return 0;
    }

    private function getMaintenanceInfo(): array
    {
        $isDown = app()->isDownForMaintenance();
        $lastMaintenanceStart = Cache::get('last_maintenance_start');
        $lastMaintenanceEnd = Cache::get('last_maintenance_end');

        if ($isDown) {
            if (!$lastMaintenanceStart) {
                Cache::forever('last_maintenance_start', now());
            }

            return [
                'status' => 'Active',
                'started' => $lastMaintenanceStart ? Carbon::parse($lastMaintenanceStart)->diffForHumans() : 'Just now',
            ];
        }

        if ($lastMaintenanceStart && !$lastMaintenanceEnd) {
            Cache::forever('last_maintenance_end', now());
        }

        if ($lastMaintenanceStart && $lastMaintenanceEnd) {
            return [
                'status' => 'Inactive',
                'last_maintenance' => [
                    'started' => Carbon::parse($lastMaintenanceStart)->diffForHumans(),
                    'ended' => Carbon::parse($lastMaintenanceEnd)->diffForHumans(),
                    'duration' => Carbon::parse($lastMaintenanceStart)->diffInMinutes($lastMaintenanceEnd) . ' minutes',
                ],
            ];
        }

        return [
            'status' => 'Inactive',
            'last_maintenance' => null,
        ];
    }

    private function getPayfastStatus(): array
    {
        try {
            $status = Http::get('https://status.payfast.io/api/v2/status.json')->json();
            $components = Http::get('https://status.payfast.io/api/v2/components.json')->json();
            $scheduledMaintenance = Http::get('https://status.payfast.io/api/v2/scheduled-maintenances/upcoming.json')->json();
            $incidents = Http::get('https://status.payfast.io/api/v2/incidents.json')->json();

            $filteredComponents = $this->filterPayfastComponents($components['components']);
            $filteredScheduledMaintenance = $this->filterPayfastScheduledMaintenance($scheduledMaintenance['scheduled_maintenances']);
            $filteredIncidents = $this->filterPayfastIncidents($incidents['incidents']);

            return [
                'status' => $status['status'],
                'components' => $filteredComponents,
                'scheduled_maintenance' => $filteredScheduledMaintenance,
                'incidents' => $filteredIncidents,
            ];
        } catch (\Exception $e) {
            Log::error('PayFast Status Error: ' . $e->getMessage());
            return [
                'status' => ['description' => 'Status Unavailable'],
                'components' => [],
                'scheduled_maintenance' => [],
                'incidents' => [],
            ];
        }
    }

    private function getPaystackStatus(): array
    {
        try {
            $status = Http::get('https://status.paystack.com/api/v2/status.json')->json();
            $components = Http::get('https://status.paystack.com/api/v2/components.json')->json();
            $scheduledMaintenance = Http::get('https://status.paystack.com/api/v2/scheduled-maintenances/upcoming.json')->json();
            $incidents = Http::get('https://status.paystack.com/api/v2/incidents.json')->json();

            $filteredComponents = $this->filterPaystackComponents($components['components']);
            $filteredScheduledMaintenance = $this->filterPaystackScheduledMaintenance($scheduledMaintenance['scheduled_maintenances']);
            $filteredIncidents = $this->filterPaystackIncidents($incidents['incidents']);

            return [
                'status' => $status['status'],
                'components' => $filteredComponents,
                'scheduled_maintenance' => $filteredScheduledMaintenance,
                'incidents' => $filteredIncidents,
            ];
        } catch (\Exception $e) {
            Log::error('Paystack Status Error: ' . $e->getMessage());
            return [
                'status' => ['description' => 'Status Unavailable'],
                'components' => [],
                'scheduled_maintenance' => [],
                'incidents' => [],
            ];
        }
    }

    private function getFlutterwaveStatus(): array
    {
        try {
            $status = Http::get('https://status.flutterwave.com/api/v2/status.json')->json();
            $components = Http::get('https://status.flutterwave.com/api/v2/components.json')->json();
            $scheduledMaintenance = Http::get('https://status.flutterwave.com/api/v2/scheduled-maintenances/upcoming.json')->json();
            $incidents = Http::get('https://status.flutterwave.com/api/v2/incidents.json')->json();

            $filteredComponents = $this->filterFlutterwaveComponents($components['components']);
            $filteredScheduledMaintenance = $this->filterFlutterwaveScheduledMaintenance($scheduledMaintenance['scheduled_maintenances']);
            $filteredIncidents = $this->filterFlutterwaveIncidents($incidents['incidents']);

            return [
                'status' => $status['status'],
                'components' => $filteredComponents,
                'scheduled_maintenance' => $filteredScheduledMaintenance,
                'incidents' => $filteredIncidents,
            ];
        } catch (\Exception $e) {
            Log::error('Flutterwave Status Error: ' . $e->getMessage());
            return [
                'status' => ['description' => 'Status Unavailable'],
                'components' => [],
                'scheduled_maintenance' => [],
                'incidents' => [],
            ];
        }
    }

    private function filterPayfastComponents(array $components): array
    {
        $allowedComponents = [
            'Credit & Cheque cards', 'Debit Cards', 'InstantEFT', 'Recurring payments',
            'Momo Pay', 'MoreTyme', 'WooCommerce', 'Mukuru Cash', 'PayPal', 'SCode',
            'Snapscan', 'General', 'Store Cards', 'Visa Checkout', 'Zapper'
        ];

        return array_filter($components, function ($component) use ($allowedComponents) {
            return in_array($component['name'], $allowedComponents);
        });
    }

    private function filterPaystackComponents(array $components): array
    {
        $allowedComponents = [
            'Card Payments', 'Bank Transfers', 'USSD', 'Payment Links',
            'Subscriptions', 'Split Payments', 'Developer API', 'Dashboard',
            'Mobile Money', 'Bank Account Verification', 'Terminal'
        ];

        return array_filter($components, function ($component) use ($allowedComponents) {
            return in_array($component['name'], $allowedComponents);
        });
    }

    private function filterFlutterwaveComponents(array $components): array
    {
        $allowedComponents = [
            'Card Payments', 'Bank Transfers', 'Mobile Money', 'USSD',
            'Virtual Cards', 'Bill Payments', 'API Services', 'Dashboard',
            'Tokenization', 'Disbursements', 'Collections'
        ];

        return array_filter($components, function ($component) use ($allowedComponents) {
            return in_array($component['name'], $allowedComponents);
        });
    }

    private function filterPayfastScheduledMaintenance(array $maintenances): array
    {
        return array_map(function ($maintenance) {
            return [
                'id' => $maintenance['id'],
                'name' => $maintenance['name'],
                'status' => $maintenance['status'],
                'scheduled_for' => $maintenance['scheduled_for'],
                'scheduled_until' => $maintenance['scheduled_until'],
                'impact' => $maintenance['impact'],
                'shortlink' => $maintenance['shortlink'],
            ];
        }, $maintenances);
    }

    private function filterPaystackScheduledMaintenance(array $maintenances): array
    {
        return array_map(function ($maintenance) {
            return [
                'id' => $maintenance['id'],
                'name' => $maintenance['name'],
                'status' => $maintenance['status'],
                'scheduled_for' => $maintenance['scheduled_for'],
                'scheduled_until' => $maintenance['scheduled_until'],
                'impact' => $maintenance['impact'],
                'shortlink' => $maintenance['shortlink'],
            ];
        }, $maintenances);
    }

    private function filterFlutterwaveScheduledMaintenance(array $maintenances): array
    {
        return array_map(function ($maintenance) {
            return [
                'id' => $maintenance['id'],
                'name' => $maintenance['name'],
                'status' => $maintenance['status'],
                'scheduled_for' => $maintenance['scheduled_for'],
                'scheduled_until' => $maintenance['scheduled_until'],
                'impact' => $maintenance['impact'],
                'shortlink' => $maintenance['shortlink'],
            ];
        }, $maintenances);
    }

    private function filterPayfastIncidents(array $incidents): array
    {
        if (empty($incidents)) {
            return [];
        }

        $incident = $incidents[0];
        return [[
            'id' => $incident['id'],
            'name' => $incident['name'],
            'status' => $incident['status'],
            'created_at' => $incident['created_at'],
            'updated_at' => $incident['updated_at'],
            'impact' => $incident['impact'],
            'shortlink' => $incident['shortlink'],
        ]];
    }

    private function filterPaystackIncidents(array $incidents): array
    {
        if (empty($incidents)) {
            return [];
        }

        $incident = $incidents[0];
        return [[
            'id' => $incident['id'],
            'name' => $incident['name'],
            'status' => $incident['status'],
            'created_at' => $incident['created_at'],
            'updated_at' => $incident['updated_at'],
            'impact' => $incident['impact'],
            'shortlink' => $incident['shortlink'],
        ]];
    }

    private function filterFlutterwaveIncidents(array $incidents): array
    {
        if (empty($incidents)) {
            return [];
        }

        $incident = $incidents[0];
        return [[
            'id' => $incident['id'],
            'name' => $incident['name'],
            'status' => $incident['status'],
            'created_at' => $incident['created_at'],
            'updated_at' => $incident['updated_at'],
            'impact' => $incident['impact'],
            'shortlink' => $incident['shortlink'],
        ]];
    }

    private function getWebsiteStatus(string $url): array
    {
        try {
            $response = Http::timeout(10)->get($url);
            
            if ($response->successful()) {
                return [
                    'status' => 'OK',
                    'status_code' => $response->status(),
                ];
            }
            
            return [
                'status' => 'Error',
                'status_code' => $response->status(),
                'error_message' => 'HTTP request failed',
            ];
        } catch (\Exception $e) {
            Log::error('Website Status Error: ' . $e->getMessage());
            return [
                'status' => 'Error',
                'error_code' => 'UNKNOWN_ERROR',
                'error_message' => $e->getMessage(),
            ];
        }
    }

    private function getNextJsStatus(): array
    {
        return $this->getWebsiteStatus('https://web.juvo.app');
    }

    private function getMainWebsiteStatus(): array
    {
        return $this->getWebsiteStatus('https://juvo.app');
    }

    private function getAdminPanelStatus(): array
    {
        return $this->getWebsiteStatus('https://admin.juvo.app');
    }

    private function getAgencyWebsiteStatus(): array
    {
        return $this->getWebsiteStatus('https://agency.juvo.app');
    }

    private function getOnePlatformStatus(): array
    {
        return $this->getWebsiteStatus('https://one.juvo.app');
    }

    private function getOneLandingStatus(): array
    {
        return $this->getWebsiteStatus('https://platform.juvo.app');
    }

    private function getWaterOsStatus(): array
    {
        return $this->getWebsiteStatus('https://os.juvo.app');
    }

    private function getImageServerStatus(): array
    {
        return $this->getWebsiteStatus('https://s3.juvo.app');
    }

}
