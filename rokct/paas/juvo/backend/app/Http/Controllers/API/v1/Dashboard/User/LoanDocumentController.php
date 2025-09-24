<?php

namespace App\Http\Controllers\API\v1\Dashboard\User;

use App\Http\Controllers\Controller;
use App\Models\LoanApplication;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use App\Services\DocumentSecurityService;

class LoanDocumentController extends Controller
{
    protected $documentSecurityService;

    public function __construct(DocumentSecurityService $documentSecurityService)
    {
        $this->documentSecurityService = $documentSecurityService;
    }

    /**
     * Download a specific loan document
     * 
     * @param int $loanId
     * @param string $documentType
     * @return \Illuminate\Http\JsonResponse
     */
    public function download($loanId, $documentType)
    {
        $user = Auth::user();
        
        try {
            // Verify loan application ownership
            $loanApplication = LoanApplication::where('id', $loanId)
                ->where('user_id', $user->id)
                ->firstOrFail();

            // Check if document exists in the application's documents
            $documentPath = $loanApplication->documents[$documentType] ?? null;

            if (!$documentPath) {
                return response()->json([
                    'error' => 'Document not found'
                ], 404);
            }

            // Verify document exists in storage
            if (!Storage::disk('loan_documents')->exists($documentPath)) {
                return response()->json([
                    'error' => 'Document file is missing'
                ], 404);
            }

            // Generate temporary download URL
            $downloadUrl = $this->documentSecurityService->generateTemporaryDownloadUrl(
                $documentPath, 
                'loan_documents'
            );

            return response()->json([
                'download_url' => $downloadUrl,
                'expires_at' => now()->addMinutes(15)->toDateTimeString()
            ]);

        } catch (\Exception $e) {
            // Log the error for internal tracking
            \Log::error('Document Download Error: ' . $e->getMessage());

            return response()->json([
                'error' => 'Unable to process document download',
                'details' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Upload documents for a loan application
     * 
     * @param Request $request
     * @param int $loanId
     * @return \Illuminate\Http\JsonResponse
     */
    public function uploadDocuments(Request $request, $loanId)
    {
        $user = Auth::user();

        $request->validate([
            'documents' => 'required|array',
            'documents.*' => 'file|mimes:pdf|max:5120' // 5MB max
        ]);

        try {
            // Verify loan application ownership
            $loanApplication = LoanApplication::where('id', $loanId)
                ->where('user_id', $user->id)
                ->firstOrFail();

            $documentPaths = [];

            foreach ($request->file('documents') as $docType => $file) {
                // Sanitize document type
                $sanitizedDocType = Str::slug($docType);

                // Store document securely
                $documentPath = $this->documentSecurityService->storeDocument(
                    $file, 
                    $loanId, 
                    $sanitizedDocType
                );

                $documentPaths[$sanitizedDocType] = $documentPath;
            }

            // Update loan application with document paths
            $loanApplication->update([
                'documents' => $documentPaths,
                'status' => 'documents_uploaded'
            ]);

            return response()->json([
                'message' => 'Documents uploaded successfully',
                'documents' => $documentPaths
            ]);

        } catch (\Exception $e) {
            \Log::error('Document Upload Error: ' . $e->getMessage());

            return response()->json([
                'error' => 'Unable to upload documents',
                'details' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * List available documents for a loan application
     * 
     * @param int $loanId
     * @return \Illuminate\Http\JsonResponse
     */
    public function listDocuments($loanId)
    {
        $user = Auth::user();

        try {
            $loanApplication = LoanApplication::where('id', $loanId)
                ->where('user_id', $user->id)
                ->firstOrFail();

            $documents = $loanApplication->documents ?? [];

            return response()->json([
                'documents' => array_keys($documents)
            ]);

        } catch (\Exception $e) {
            \Log::error('Document List Error: ' . $e->getMessage());

            return response()->json([
                'error' => 'Unable to list documents',
                'details' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a specific document from a loan application
     * 
     * @param int $loanId
     * @param string $documentType
     * @return \Illuminate\Http\JsonResponse
     */
    public function deleteDocument($loanId, $documentType)
    {
        $user = Auth::user();

        try {
            $loanApplication = LoanApplication::where('id', $loanId)
                ->where('user_id', $user->id)
                ->firstOrFail();

            $documents = $loanApplication->documents ?? [];
            $documentPath = $documents[$documentType] ?? null;

            if (!$documentPath) {
                return response()->json([
                    'error' => 'Document not found'
                ], 404);
            }

            // Delete from storage
            if (Storage::disk('loan_documents')->exists($documentPath)) {
                Storage::disk('loan_documents')->delete($documentPath);
            }

            // Remove from loan application documents
            unset($documents[$documentType]);
            $loanApplication->update(['documents' => $documents]);

            return response()->json([
                'message' => 'Document deleted successfully'
            ]);

        } catch (\Exception $e) {
            \Log::error('Document Deletion Error: ' . $e->getMessage());

            return response()->json([
                'error' => 'Unable to delete document',
                'details' => $e->getMessage()
            ], 500);
        }
    }
}
