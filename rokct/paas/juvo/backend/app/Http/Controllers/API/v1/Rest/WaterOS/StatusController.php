<?php

namespace App\Http\Controllers\API\v1\Rest\WaterOS;

use Illuminate\Http\JsonResponse;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Carbon\Carbon;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\RequestException;

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
            'version' => config('app.version', 'unknown'),
            'maintenance' => $this->getMaintenanceInfo(),
            'juvo_food' => $this->getNextJsStatus(),
            'main_website' => $this->getMainWebsiteStatus(),
            'admin_panel' => $this->getAdminPanelStatus(),
            'juvo_agency' => $this->getAgencyWebsiteStatus(),
            'juvo_one_landing' => $this->getWebsiteStatus('https://one.juvo.app'),
            'one_platform' => $this->getWebsiteStatus('https://platform.juvo.app'),
            'wateros' => $this->getWebsiteStatus('https://os.juvo.app'),
            'image_server' => $this->getWebsiteStatus('https://s3.juvo.app'),
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
        
        return 0; // fallback if we can't determine boot time
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
        } else {
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
            } else { 
                return [
                    'status' => 'Inactive',
                    'last_maintenance' => null,
                ];
            }
        }
    }

    private function getPayfastStatus(): array
    {
        $status = Http::withoutVerifying()->get('https://status.payfast.io/api/v2/status.json')->json();
        $components = Http::withoutVerifying()->get('https://status.payfast.io/api/v2/components.json')->json();
        $scheduledMaintenance = Http::withoutVerifying()->get('https://status.payfast.io/api/v2/scheduled-maintenances/upcoming.json')->json();
        $incidents = Http::withoutVerifying()->get('https://status.payfast.io/api/v2/incidents.json')->json();

        $filteredComponents = $this->filterPayfastComponents($components['components']);
        $filteredScheduledMaintenance = $this->filterPayfastScheduledMaintenance($scheduledMaintenance['scheduled_maintenances']);
        $filteredIncidents = $this->filterPayfastIncidents($incidents['incidents']);

        return [
            'status' => [
                'indicator' => $status['status']['indicator'],
                'description' => $status['status']['description'],
            ],
            'components' => $filteredComponents,
            'scheduled_maintenance' => $filteredScheduledMaintenance,
            'incidents' => $filteredIncidents,
        ];
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

    private function filterPayfastScheduledMaintenance(array $maintenances): array
    {
        return array_map(function ($maintenance) {
            unset($maintenance['created_at'], $maintenance['updated_at'], $maintenance['display_at']);
            unset($maintenance['deliver_notifications'], $maintenance['custom_tweet'], $maintenance['tweet_id'], $maintenance['components']);

            if (isset($maintenance['incident_updates']) && is_array($maintenance['incident_updates'])) {
                $maintenance['incident_updates'] = array_map(function ($update) {
                    unset($update['affected_components'], $update['deliver_notifications'], $update['custom_tweet'], $update['tweet_id']);
                    return $update;
                }, $maintenance['incident_updates']);
            }

            return $maintenance;
        }, $maintenances);
    }

    private function filterPayfastIncidents(array $incidents): array
    {
        if (empty($incidents)) {
            return [];
        }

        // Only return the latest incident
        $latestIncident = $incidents[0];
        return [[
            'id' => $latestIncident['id'],
            'name' => $latestIncident['name'],
            'status' => $latestIncident['status'],
            'created_at' => $latestIncident['created_at'],
            'updated_at' => $latestIncident['updated_at'],
            'impact' => $latestIncident['impact'],
        ]];
    }

    private function getPaystackStatus(): array
    {
        $status = Http::withoutVerifying()->get('https://status.paystack.com/api/v2/status.json')->json();
        $components = Http::withoutVerifying()->get('https://status.paystack.com/api/v2/components.json')->json();
        $scheduledMaintenance = Http::withoutVerifying()->get('https://status.paystack.com/api/v2/scheduled-maintenances/upcoming.json')->json();
        $incidents = Http::withoutVerifying()->get('https://status.paystack.com/api/v2/incidents.json')->json();

        $filteredComponents = $this->filterPaystackComponents($components['components']);
        $filteredScheduledMaintenance = $this->filterPaystackScheduledMaintenance($scheduledMaintenance['scheduled_maintenances']);
        $filteredIncidents = $this->filterPaystackIncidents($incidents['incidents']);

        return [
            'status' => [
                'indicator' => $status['status']['indicator'] ?? 'none',
                'description' => $status['status']['description'] ?? 'All Systems Operational',
            ],
            'components' => $filteredComponents,
            'scheduled_maintenance' => $filteredScheduledMaintenance,
            'incidents' => $filteredIncidents,
        ];
    }

    private function filterPaystackComponents(array $components): array
    {
        $allowedComponents = [
            'API', 'Webhooks', 'Checkout', 'Pay with Transfer/EFT', 'Cards',
            'Payment Page', 'USSD', 'QR', 'Mobile Money', 'Payment Pages'
        ];

        return array_filter($components, function ($component) use ($allowedComponents) {
            return in_array($component['name'], $allowedComponents);
        });
    }

    private function filterPaystackScheduledMaintenance(array $maintenances): array
    {
        return array_map(function ($maintenance) {
            return [
                'name' => $maintenance['name'],
                'status' => $maintenance['status'],
                'scheduled_for' => $maintenance['scheduled_for'],
                'scheduled_until' => $maintenance['scheduled_until'],
            ];
        }, $maintenances);
    }

    private function filterPaystackIncidents(array $incidents): array
    {
        $filteredIncidents = array_filter($incidents, function($incident) {
            return strpos($incident['name'], 'RSA') !== false 
                || strpos($incident['name'], 'South Africa') !== false
                || strpos($incident['name'], '1voucher') !== false;
        });

        if (empty($filteredIncidents)) {
            // If no incidents match the criteria, return the latest incident
            return empty($incidents) ? [] : [reset($incidents)];
        }

        // Return only the latest filtered incident
        return [reset($filteredIncidents)];
    }

    private function getFlutterwaveStatus(): array
    {
        $status = Http::withoutVerifying()->get('https://status.flutterwave.com/api/v2/status.json')->json();
        $components = Http::withoutVerifying()->get('https://status.flutterwave.com/api/v2/components.json')->json();
        $scheduledMaintenance = Http::withoutVerifying()->get('https://status.flutterwave.com/api/v2/scheduled-maintenances/upcoming.json')->json();
        $incidents = Http::withoutVerifying()->get('https://status.flutterwave.com/api/v2/incidents.json')->json();

        $filteredComponents = $this->filterFlutterwaveComponents($components['components']);
        $filteredScheduledMaintenance = $this->filterFlutterwaveScheduledMaintenance($scheduledMaintenance['scheduled_maintenances']);
        $filteredIncidents = $this->filterFlutterwaveIncidents($incidents['incidents']);

        return [
            'status' => [
                'indicator' => $status['status']['indicator'] ?? 'none',
                'description' => $status['status']['description'] ?? 'All Systems Operational',
            ],
            'components' => $filteredComponents,
            'scheduled_maintenance' => $filteredScheduledMaintenance,
            'incidents' => $filteredIncidents,
        ];
    }

    private function filterFlutterwaveComponents(array $components): array
    {
        $excludedComponents = [
            'Flutterwave Website',
            'Flutterwave Collections',
            'Checkout JS',
            'Virtual Account Numbers',
            'USSD Collections',
            'Flutterwave Store',
            'Merchant Stores',
            'Flutterwave Offline',
            'Point of Sale - POS',
            'Agency App',
            'Remittance Products',
            'SendApp',
            'Swap',
            'Tuition',
            'Shared Services',
            'Bank Verification Number (BVN)',
            'Servman',
            'Integration Tester',
            'Bill Payments (Airtime)',
            'Bill Payments (Cable TV)',
            'Windows Server Group',
            'Flutterwave Payouts',
            'Flutterwave for Business'
        ];

        return array_filter($components, function ($component) use ($excludedComponents) {
            return !in_array($component['name'], $excludedComponents);
        });
    }

    private function filterFlutterwaveScheduledMaintenance(array $maintenances): array
    {
        return array_map(function ($maintenance) {
            return [
                'name' => $maintenance['name'],
                'status' => $maintenance['status'],
                'scheduled_for' => $maintenance['scheduled_for'],
                'scheduled_until' => $maintenance['scheduled_until'],
            ];
        }, $maintenances);
    }

    private function filterFlutterwaveIncidents(array $incidents): array
    {
        $filteredIncidents = array_filter($incidents, function($incident) {
            return strpos($incident['name'], 'RSA') !== false 
                || strpos($incident['name'], 'South Africa') !== false
                || strpos($incident['name'], '1voucher') !== false;
        });

        if (empty($filteredIncidents)) {
            // If no incidents match the criteria, return the latest incident
            return empty($incidents) ? [] : [reset($incidents)];
        }

        // Return only the latest filtered incident
        $latestIncident = reset($filteredIncidents);
        return [[
            'name' => $latestIncident['name'],
            'status' => $latestIncident['status'],
            'created_at' => $latestIncident['created_at'],
            'updated_at' => $latestIncident['updated_at'],
            'impact' => $latestIncident['impact'],
        ]];
    }

    private function getNextJsStatus(): array
    {
        return $this->getWebsiteStatus('https://food.juvo.app');
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

    private function getWebsiteStatus(string $url): array
{
    $startTime = microtime(true);

    try {
        $client = new Client([
            'timeout' => 10,
            'verify' => true, // This enables SSL certificate verification
        ]);

        $response = $client->request('GET', $url);
        
        $endTime = microtime(true);
        $responseTime = round($endTime - $startTime, 3);
        
        $statusCode = $response->getStatusCode();
        $body = strtolower($response->getBody()->getContents());
        
        if ($statusCode >= 200 && $statusCode < 300) {
            if (strpos($body, "why am i seeing this page?") !== false) {
                return [
                    'status' => 'Error',
                    'status_code' => $statusCode,
                    'error_message' => 'Default page detected. Site might not be set up.',
                    'response_time' => $responseTime,
                ];
            }
            return [
                'status' => 'OK',
                'status_code' => $statusCode,
                'response_time' => $responseTime,
            ];
        } else {
            $errorMessage = 'HTTP request failed';
            if ($statusCode === 404) {
                $errorMessage = 'Page not found';
            } elseif ($statusCode === 503) {
                $errorMessage = 'Service unavailable';
            }
            return [
                'status' => 'Error',
                'status_code' => $statusCode,
                'error_message' => $errorMessage,
                'response_time' => $responseTime,
            ];
        }
    } catch (RequestException $e) {
        $endTime = microtime(true);
        $responseTime = round($endTime - $startTime, 3);

        if ($e->hasResponse()) {
            $response = $e->getResponse();
            return [
                'status' => 'Error',
                'status_code' => $response->getStatusCode(),
                'error_message' => $e->getMessage(),
                'response_time' => $responseTime,
            ];
        } else {
            return [
                'status' => 'Error',
                'error_code' => 'CONNECTION_ERROR',
                'error_message' => 'Connection failed: ' . $e->getMessage(),
                'response_time' => $responseTime,
            ];
        }
    } catch (\Exception $e) {
        $endTime = microtime(true);
        $responseTime = round($endTime - $startTime, 3);

        return [
            'status' => 'Error',
            'error_code' => 'UNKNOWN_ERROR',
            'error_message' => $e->getMessage(),
            'response_time' => $responseTime,
        ];
    }
}

    private function getResponseTime($response): string
    {
        $transferTime = $response->getTransferTime();
        return number_format($transferTime, 3) . ' seconds';
    }
}
