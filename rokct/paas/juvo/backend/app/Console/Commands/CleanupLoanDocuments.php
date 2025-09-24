<?php

namespace App\Console\Commands;

use App\Models\LoanApplication;
use App\Services\CleanupService\LoanDocumentCleanupService;
use Illuminate\Console\Command;

class CleanupLoanDocuments extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'loans:cleanup-documents 
                            {--status=* : Statuses to clean up documents for (rejected, cancelled)}
                            {--id= : Clean up a specific loan application by ID}
                            {--batch=50 : Number of applications to process at once}
                            {--force : Force cleanup without confirmation}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clean up documents for rejected or cancelled loan applications';

    /**
     * @var LoanDocumentCleanupService
     */
    protected $cleanupService;

    /**
     * Create a new command instance.
     *
     * @param LoanDocumentCleanupService $cleanupService
     * @return void
     */
    public function __construct(LoanDocumentCleanupService $cleanupService)
    {
        parent::__construct();
        $this->cleanupService = $cleanupService;
    }

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        // Get command options
        $statuses = $this->option('status');
        $specificId = $this->option('id');
        $batchSize = (int) $this->option('batch');
        $force = $this->option('force');
        
        // If no statuses provided, default to rejected and cancelled
        if (empty($statuses)) {
            $statuses = ['rejected', 'cancelled'];
        }
        
        if ($specificId) {
            // Clean up a specific application
            return $this->cleanupSpecificApplication($specificId, $force);
        } else {
            // Clean up applications by status
            return $this->cleanupByStatus($statuses, $batchSize, $force);
        }
    }

    /**
     * Clean up documents for a specific application
     *
     * @param int $applicationId
     * @param bool $force
     * @return int
     */
    protected function cleanupSpecificApplication($applicationId, $force)
    {
        $application = LoanApplication::find($applicationId);
        
        if (!$application) {
            $this->error("Application with ID {$applicationId} not found.");
            return 1;
        }
        
        // Confirm cleanup unless force option is used
        if (!$force) {
            $confirmMessage = "Are you sure you want to clean up documents for application {$applicationId} with status '{$application->status}'?";
            if (!$this->confirm($confirmMessage)) {
                $this->info('Operation cancelled.');
                return 0;
            }
        }
        
        $this->info("Cleaning up documents for application {$applicationId}...");
        $result = $this->cleanupService->cleanupApplicationDocuments($application);
        
        $this->displayResult($result);
        
        return 0;
    }

    /**
     * Clean up documents for applications with specified statuses
     *
     * @param array $statuses
     * @param int $batchSize
     * @param bool $force
     * @return int
     */
    protected function cleanupByStatus(array $statuses, int $batchSize, bool $force)
    {
        // Count applications to be processed
        $count = LoanApplication::whereIn('status', $statuses)
            ->whereNotNull('documents')
            ->count();
            
        if ($count === 0) {
            $this->info("No applications with status(es) " . implode(', ', $statuses) . " found with documents to clean up.");
            return 0;
        }
        
        // Confirm cleanup unless force option is used
        if (!$force) {
            $confirmMessage = "Are you sure you want to clean up documents for {$count} applications with status(es) " . implode(', ', $statuses) . "?";
            if (!$this->confirm($confirmMessage)) {
                $this->info('Operation cancelled.');
                return 0;
            }
        }
        
        $this->info("Cleaning up documents for {$count} applications with status(es) " . implode(', ', $statuses) . "...");
        
        // Process in batches
        $processed = 0;
        $totalDeleted = 0;
        $totalFailed = 0;
        
        $progressBar = $this->output->createProgressBar($count);
        $progressBar->start();
        
        while ($processed < $count) {
            $applications = LoanApplication::whereIn('status', $statuses)
                ->whereNotNull('documents')
                ->limit($batchSize)
                ->get();
                
            foreach ($applications as $application) {
                $result = $this->cleanupService->cleanupApplicationDocuments($application);
                $totalDeleted += $result['deleted_count'];
                $totalFailed += $result['failed_count'];
                $processed++;
                $progressBar->advance();
            }
        }
        
        $progressBar->finish();
        $this->newLine(2);
        
        $this->info("Cleanup completed.");
        $this->info("Total applications processed: {$processed}");
        $this->info("Total documents deleted: {$totalDeleted}");
        
        if ($totalFailed > 0) {
            $this->warn("Failed deletions: {$totalFailed}");
        }
        
        return 0;
    }

    /**
     * Display cleanup result
     *
     * @param array $result
     * @return void
     */
    protected function displayResult(array $result)
    {
        $this->info("Application ID: {$result['application_id']}");
        $this->info("Status: {$result['status']}");
        $this->info("Documents deleted: {$result['deleted_count']}");
        
        if ($result['failed_count'] > 0) {
            $this->warn("Failed deletions: {$result['failed_count']}");
        }
        
        if (!empty($result['documents'])) {
            $this->newLine();
            $this->info("Document details:");
            
            $headers = ['Type', 'Path', 'Deleted', 'Reason'];
            $rows = [];
            
            foreach ($result['documents'] as $doc) {
                $rows[] = [
                    $doc['type'],
                    $doc['path'],
                    $doc['deleted'] ? 'Yes' : 'No',
                    $doc['deleted'] ? '' : ($doc['reason'] ?? 'Unknown error')
                ];
            }
            
            $this->table($headers, $rows);
        }
    }
}
