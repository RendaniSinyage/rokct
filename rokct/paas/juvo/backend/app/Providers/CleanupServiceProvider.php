<?php

namespace App\Providers;

use App\Models\LoanApplication;
use App\Services\CleanupService\LoanDocumentCleanupService;
use Illuminate\Support\ServiceProvider;

class CleanupServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     *
     * @return void
     */
    public function register()
    {
        $this->app->singleton(LoanDocumentCleanupService::class, function ($app) {
            return new LoanDocumentCleanupService();
        });
    }

    /**
     * Bootstrap services.
     *
     * @return void
     */
    public function boot()
    {
        // Register model events to automatically clean up documents when application status changes
        LoanApplication::updated(function ($application) {
            // Only handle if status has changed to rejected or cancelled
            if ($application->isDirty('status')) {
                $oldStatus = $application->getOriginal('status');
                $newStatus = $application->status;
                
                if (in_array($newStatus, ['rejected', 'cancelled']) && $oldStatus !== $newStatus) {
                    // Only trigger cleanup if there are documents to clean
                    if (!empty($application->documents)) {
                        $cleanupService = app(LoanDocumentCleanupService::class);
                        
                        // Schedule cleanup task asynchronously
                        dispatch(function () use ($cleanupService, $application) {
                            $cleanupService->cleanupApplicationDocuments($application);
                        })->afterCommit();
                        
                        \Log::info('Automatic document cleanup scheduled', [
                            'loan_id' => $application->id,
                            'old_status' => $oldStatus,
                            'new_status' => $newStatus
                        ]);
                    }
                }
            }
        });
        
        // Add command to artisan
        if ($this->app->runningInConsole()) {
            $this->commands([
                \App\Console\Commands\CleanupLoanDocuments::class,
            ]);
        }
    }
}
