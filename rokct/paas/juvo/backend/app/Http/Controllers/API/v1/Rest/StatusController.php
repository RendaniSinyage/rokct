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
    public function simpleStatus(): JsonResponse
    {
        $juvoStatus = $this->getJuvoStatus();
        
        // Extract only the top-level fields for simple status
        $simpleResponse = [
            'juvo_platform' => [
                'status' => $juvoStatus['status'],
                'uptime' => $juvoStatus['uptime'],
                'last_restart' => $juvoStatus['last_restart'],
                'version' => $juvoStatus['version'],
                'maintenance' => $juvoStatus['maintenance']
            ]
        ];

        return response()->json($simpleResponse);
    }

    public function detailedStatus(): JsonResponse
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

    // PM2 monitoring configuration - correct based on actual PM2 output
    private function getPm2MonitoringConfig(): array
    {
        return [
            'juvo_web' => ['enabled' => true, 'pm2_id' => 0],      // PM2 ID 0 = "yarn start" 
            'main_website' => ['enabled' => false, 'pm2_id' => null],
            'admin_panel' => ['enabled' => false, 'pm2_id' => null],
            'juvo_agency' => ['enabled' => false, 'pm2_id' => null],
            'one_platform' => ['enabled' => false, 'pm2_id' => null],
            'n8n_platform' => ['enabled' => false, 'pm2_id' => null],
            'wateros' => ['enabled' => false, 'pm2_id' => null],    // Disabled - no wateros PM2 process
            'image_server' => ['enabled' => false, 'pm2_id' => null],
        ];
    }

    /**
     * Get PM2 process info by ID
     */
    private function getPm2ProcessById(int $pm2Id): ?array
    {
        try {
            $pm2Output = shell_exec('pm2 jlist 2>/dev/null');
            
            if (empty($pm2Output)) {
                return null;
            }

            $processes = json_decode(trim($pm2Output), true);
            
            if (json_last_error() !== JSON_ERROR_NONE || !is_array($processes)) {
                return null;
            }

            foreach ($processes as $process) {
                if (($process['pm_id'] ?? null) === $pm2Id) {
                    return [
                        'id' => $process['pm_id'],
                        'name' => $process['name'] ?? 'unknown',
                        'status' => $process['pm2_env']['status'] ?? 'unknown',
                        'running' => ($process['pm2_env']['status'] ?? '') === 'online'
                    ];
                }
            }

            return null;
        } catch (\Exception $e) {
            Log::error("PM2 Process Check Error for ID {$pm2Id}: " . $e->getMessage());
            return null;
        }
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
            'n8n_platform' => $this->getOneLandingStatus(),
            'wateros' => $this->getWaterOsStatus(),
            'image_server' => $this->getImageServerStatus(),
            'pm2_processes' => $this->getPm2Status(),
        ];
    }

    /**
     * Get PM2 process status
     */
    private function getPm2Status(): array
    {
        try {
            // Get PM2 list in JSON format
            $pm2Output = shell_exec('pm2 jlist 2>/dev/null');
            
            if (empty($pm2Output)) {
                return [
                    'status' => 'PM2 Not Available',
                    'processes' => []
                ];
            }

            // The output should be clean JSON, so parse directly
            $processes = json_decode(trim($pm2Output), true);
            
            if (json_last_error() !== JSON_ERROR_NONE) {
                Log::error('PM2 JSON Parse Error: ' . json_last_error_msg() . ' - Output length: ' . strlen($pm2Output));
                return [
                    'status' => 'PM2 Parse Error: ' . json_last_error_msg(),
                    'processes' => [],
                    'output_preview' => substr(trim($pm2Output), 0, 200)
                ];
            }

            if (!is_array($processes)) {
                return [
                    'status' => 'PM2 Invalid Response Format',
                    'processes' => []
                ];
            }

            $processStatus = [];
            $allOnline = true;

            foreach ($processes as $process) {
                $name = $process['name'] ?? 'unknown';
                $status = $process['pm2_env']['status'] ?? 'unknown';
                $pid = $process['pid'] ?? null;
                $uptime = isset($process['pm2_env']['pm_uptime']) ? 
                    $this->formatUptime((time() * 1000 - $process['pm2_env']['pm_uptime']) / 1000) : 'unknown';
                $restarts = $process['pm2_env']['restart_time'] ?? 0;
                $memory = isset($process['monit']['memory']) ? 
                    $this->formatBytes($process['monit']['memory']) : 'unknown';
                $cpu = isset($process['monit']['cpu']) ? 
                    $process['monit']['cpu'] . '%' : 'unknown';
                $pm_id = $process['pm_id'] ?? 'unknown';

                $processStatus[] = [
                    'pm_id' => $pm_id,
                    'name' => $name,
                    'status' => $status,
                    'pid' => $pid,
                    'uptime' => $uptime,
                    'restarts' => $restarts,
                    'memory' => $memory,
                    'cpu' => $cpu
                ];

                if ($status !== 'online') {
                    $allOnline = false;
                }
            }

            return [
                'status' => $allOnline ? 'All Processes Online' : 'Some Processes Down',
                'total_processes' => count($processes),
                'online_processes' => count(array_filter($processes, function($p) {
                    return ($p['pm2_env']['status'] ?? '') === 'online';
                })),
                'processes' => $processStatus
            ];

        } catch (\Exception $e) {
            Log::error('PM2 Status Error: ' . $e->getMessage());
            return [
                'status' => 'Error: ' . $e->getMessage(),
                'error' => $e->getMessage(),
                'processes' => []
            ];
        }
    }

    /**
     * Check if a specific PM2 process is running
     */
    private function isPm2ProcessRunning(string $processName): bool
    {
        try {
            $pm2Output = shell_exec('pm2 jlist 2>/dev/null');
            
            if (empty($pm2Output)) {
                return false;
            }

            $processes = json_decode($pm2Output, true);
            
            if (json_last_error() !== JSON_ERROR_NONE) {
                return false;
            }

            foreach ($processes as $process) {
                if (($process['name'] ?? '') === $processName) {
                    return ($process['pm2_env']['status'] ?? '') === 'online';
                }
            }

            return false;
        } catch (\Exception $e) {
            Log::error("PM2 Process Check Error for {$processName}: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Enhanced website status check with PM2 monitoring by ID
     */
    private function getWebsiteStatusWithPm2(string $url, string $siteKey): array
    {
        $config = $this->getPm2MonitoringConfig();
        $httpStatus = $this->getWebsiteStatus($url);
        
        // If PM2 monitoring is not enabled for this site, return original HTTP status
        if (!$config[$siteKey]['enabled'] || $config[$siteKey]['pm2_id'] === null) {
            return $httpStatus;
        }
        
        // Get PM2 process info by ID
        $pm2Process = $this->getPm2ProcessById($config[$siteKey]['pm2_id']);
        
        // If PM2 monitoring is enabled but process not found, that's a configuration error
        if (!$pm2Process) {
            return [
                'status' => 'Error',
                'error_code' => 'PM2_PROCESS_NOT_FOUND',
                'error_message' => "PM2 monitoring enabled but process ID {$config[$siteKey]['pm2_id']} not found"
            ];
        }
        
        $processName = $pm2Process['name'];
        $pm2Running = $pm2Process['running'];
        $httpOk = $httpStatus['status'] === 'OK';
        
        // Both HTTP and PM2 are OK
        if ($httpOk && $pm2Running) {
            return $httpStatus; // Return original successful response
        }
        
        // PM2 is down but HTTP is OK
        if ($httpOk && !$pm2Running) {
            return [
                'status' => 'Error',
                'status_code' => $httpStatus['status_code'] ?? null,
                'error_message' => "PM2 process '{$processName}' is not running"
            ];
        }
        
        // HTTP is down but PM2 is OK
        if (!$httpOk && $pm2Running) {
            $response = [
                'status' => 'Error',
                'error_message' => "Website is down but PM2 process '{$processName}' is running"
            ];
            
            // Include original HTTP error details
            if (isset($httpStatus['status_code'])) {
                $response['status_code'] = $httpStatus['status_code'];
                $response['error_message'] .= " (HTTP: " . ($httpStatus['error_message'] ?? 'Unknown error') . ")";
            } elseif (isset($httpStatus['error_message'])) {
                $response['error_message'] .= " (HTTP: " . $httpStatus['error_message'] . ")";
            }
            
            if (isset($httpStatus['error_code'])) {
                $response['error_code'] = $httpStatus['error_code'];
            }
            
            return $response;
        }
        
        // Both HTTP and PM2 are down
        $response = [
            'status' => 'Error',
            'error_message' => "Both website and PM2 process '{$processName}' are down"
        ];
        
        // Include original HTTP error details
        if (isset($httpStatus['status_code'])) {
            $response['status_code'] = $httpStatus['status_code'];
        }
        
        if (isset($httpStatus['error_message'])) {
            $response['error_message'] .= " (HTTP: " . $httpStatus['error_message'] . ")";
        }
        
        if (isset($httpStatus['error_code'])) {
            $response['error_code'] = $httpStatus['error_code'];
        }
        
        return $response;
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

    private function formatUptime(int $seconds): string
    {
        $days = floor($seconds / 86400);
        $hours = floor(($seconds % 86400) / 3600);
        $minutes = floor(($seconds % 3600) / 60);
        $secs = $seconds % 60;

        if ($days > 0) {
            return "{$days}d {$hours}h {$minutes}m";
        } elseif ($hours > 0) {
            return "{$hours}h {$minutes}m";
        } elseif ($minutes > 0) {
            return "{$minutes}m {$secs}s";
        } else {
            return "{$secs}s";
        }
    }

    private function formatBytes(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        $bytes /= pow(1024, $pow);
        
        return round($bytes, 1) . $units[$pow];
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

    // Payment provider methods remain the same...
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

    // Filter methods remain unchanged...
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

    // Filter methods for scheduled maintenance and incidents remain the same...
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

    // Website status methods using the new PM2-aware system
    private function getNextJsStatus(): array
    {
        return $this->getWebsiteStatusWithPm2('https://web.juvo.app', 'juvo_web');
    }

    private function getMainWebsiteStatus(): array
    {
        return $this->getWebsiteStatusWithPm2('https://juvo.app', 'main_website');
    }

    private function getAdminPanelStatus(): array
    {
        return $this->getWebsiteStatusWithPm2('https://admin.juvo.app', 'admin_panel');
    }

    private function getAgencyWebsiteStatus(): array
    {
        return $this->getWebsiteStatusWithPm2('https://agency.juvo.app', 'juvo_agency');
    }

    private function getOnePlatformStatus(): array
    {
        return $this->getWebsiteStatusWithPm2('https://one.juvo.app', 'one_platform');
    }

    private function getOneLandingStatus(): array
    {
        return $this->getWebsiteStatusWithPm2('https://n8n.juvo.app', 'n8n_platform');
    }

    private function getWaterOsStatus(): array
    {
        return $this->getWebsiteStatusWithPm2('https://os.juvo.app', 'wateros');
    }

    private function getImageServerStatus(): array
    {
        return $this->getWebsiteStatusWithPm2('https://s3.juvo.app', 'image_server');
    }
}
