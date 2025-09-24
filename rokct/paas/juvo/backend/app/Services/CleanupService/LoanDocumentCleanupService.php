<?php

namespace App\Services\CleanupService;

use App\Models\LoanApplication;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class LoanDocumentCleanupService
{
    /**
     * Clean up documents for a specific loan application
     *
     * @param LoanApplication $loanApplication
     * @return array Information about the cleanup process
     */
    public function cleanupApplicationDocuments(LoanApplication $loanApplication): array
    {
        $result = [
            'application_id' => $loanApplication->id,
            'status' => $loanApplication->status,
            'deleted_count' => 0,
            'failed_count' => 0,
            'documents' => []
        ];

        // If the application doesn't have any documents, return early
        if (empty($loanApplication->documents) || !is_array($loanApplication->documents)) {
            Log::info('No documents to clean up for application', [
                'application_id' => $loanApplication->id,
                'status' => $loanApplication->status
            ]);
            return $result;
        }

        // Iterate through each document and delete it
        foreach ($loanApplication->documents as $docType => $path) {
            // Skip if path is empty
            if (empty($path)) {
                continue;
            }

            try {
                // Check if file exists
                if (Storage::disk('loan_documents')->exists($path)) {
                    // Delete the file
                    $deleted = Storage::disk('loan_documents')->delete($path);
                    
                    // Record the result
                    $result['documents'][] = [
                        'type' => $docType,
                        'path' => $path,
                        'deleted' => $deleted
                    ];
                    
                    if ($deleted) {
                        $result['deleted_count']++;
                        Log::info('Document deleted successfully', [
                            'application_id' => $loanApplication->id,
                            'document_type' => $docType,
                            'path' => $path
                        ]);
                    } else {
                        $result['failed_count']++;
                        Log::warning('Failed to delete document', [
                            'application_id' => $loanApplication->id,
                            'document_type' => $docType,
                            'path' => $path
                        ]);
                    }
                } else {
                    Log::info('Document not found on disk', [
                        'application_id' => $loanApplication->id,
                        'document_type' => $docType,
                        'path' => $path
                    ]);
                    $result['documents'][] = [
                        'type' => $docType,
                        'path' => $path,
                        'deleted' => false,
                        'reason' => 'File not found'
                    ];
                }
            } catch (\Exception $e) {
                Log::error('Error deleting document', [
                    'application_id' => $loanApplication->id,
                    'document_type' => $docType,
                    'path' => $path,
                    'error' => $e->getMessage()
                ]);
                
                $result['documents'][] = [
                    'type' => $docType,
                    'path' => $path,
                    'deleted' => false,
                    'reason' => $e->getMessage()
                ];
                $result['failed_count']++;
            }
        }
        
        // Clear the documents field in the database
        $loanApplication->update(['documents' => null]);
        
        // Check if the loan folder is now empty - if so, delete it too
        $this->cleanupEmptyFolders($loanApplication->id);

        return $result;
    }
    
    /**
     * Clean up empty folders for a loan application
     *
     * @param int $loanId
     * @return bool Whether the folder was deleted
     */
    protected function cleanupEmptyFolders(int $loanId): bool
    {
        $folderDeleted = false;
        
        try {
            $loanFolderPath = "loans/{$loanId}";
            
            // Check if the folder exists
            if (Storage::disk('loan_documents')->exists($loanFolderPath)) {
                // Get all files in the folder
                $files = Storage::disk('loan_documents')->files($loanFolderPath);
                
                // If folder is empty, delete it
                if (empty($files)) {
                    Storage::disk('loan_documents')->deleteDirectory($loanFolderPath);
                    $folderDeleted = true;
                    
                    Log::info('Empty loan folder deleted', [
                        'loan_id' => $loanId,
                        'folder_path' => $loanFolderPath
                    ]);
                }
            }
        } catch (\Exception $e) {
            Log::error('Error deleting empty loan folder', [
                'loan_id' => $loanId,
                'error' => $e->getMessage()
            ]);
        }
        
        return $folderDeleted;
    }
    
    /**
     * Clean up documents for all rejected or cancelled applications
     *
     * @param int $batchSize Number of applications to process at once
     * @return array Summary of the cleanup process
     */
    public function cleanupAllRejectedAndCancelledApplications(int $batchSize = 10): array
    {
        $summary = [
            'total_applications_processed' => 0,
            'total_documents_deleted' => 0,
            'failed_deletions' => 0
        ];
        
        // Get all rejected or cancelled applications with documents
        $applications = LoanApplication::whereIn('status', ['rejected', 'cancelled'])
            ->whereNotNull('documents')
            ->limit($batchSize)
            ->get();
            
        $summary['total_applications_processed'] = count($applications);
        
        foreach ($applications as $application) {
            $result = $this->cleanupApplicationDocuments($application);
            $summary['total_documents_deleted'] += $result['deleted_count'];
            $summary['failed_deletions'] += $result['failed_count'];
        }
        
        Log::info('Batch cleanup completed', $summary);
        
        return $summary;
    }
    
    /**
     * Register status change hook to automatically clean up documents
     * 
     * This method hooks into application status changes to automatically
     * clean up documents when an application is rejected or cancelled
     *
     * @param LoanApplication $application
     * @param string $oldStatus
     * @param string $newStatus
     * @return void
     */
    public function handleStatusChange(LoanApplication $application, string $oldStatus, string $newStatus): void
    {
        // If new status is rejected or cancelled, clean up documents
        if (in_array($newStatus, ['rejected', 'cancelled']) && $oldStatus !== $newStatus) {
            Log::info('Automatically cleaning up documents due to status change', [
                'application_id' => $application->id,
                'old_status' => $oldStatus,
                'new_status' => $newStatus
            ]);
            
            // Clean up documents in a queued job to avoid blocking the request
            dispatch(function () use ($application) {
                $this->cleanupApplicationDocuments($application);
            })->afterCommit();
        }
    }
}
