<?php

namespace App\Http\Controllers\API\v1\Dashboard\User;

use App\Http\Controllers\Controller;
use App\Models\LoanApplication;
use App\Models\ContractTemplate;
use App\Models\LoanContract;
use App\Mail\LoanContractMail;
use App\Services\DocumentSecurityService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class LoanController extends Controller
{
    protected $documentSecurityService;

    public function __construct(DocumentSecurityService $documentSecurityService)
    {
        $this->documentSecurityService = $documentSecurityService;
    }

    /**
     * Check loan history for disqualifying factors
     */
    public function checkLoanHistoryEligibility()
    {
        $user = Auth::user();

        // Check for unpaid loans
        $hasUnpaidLoans = LoanApplication::where('user_id', $user->id)
            ->whereIn('status', ['active', 'overdue'])
            ->exists();

        // Check for previously declined loans
        $hasDeclinedLoans = LoanApplication::where('user_id', $user->id)
            ->where('status', 'declined')
            ->exists();

        return response()->json([
            'data' => [
                'has_disqualifying_history' => $hasUnpaidLoans || $hasDeclinedLoans,
                'has_unpaid_loans' => $hasUnpaidLoans,
                'has_declined_loans' => $hasDeclinedLoans,
            ]
        ]);
    }

    /**
     * Check financial eligibility based on income and expenses
     */
    public function checkFinancialEligibility(Request $request)
    {
        $validated = $request->validate([
            'monthly_income' => 'required|numeric|min:0',
            'grocery_expenses' => 'required|numeric|min:0',
            'other_expenses' => 'required|numeric|min:0',
            'existing_credits' => 'required|numeric|min:0',
        ]);

        // Calculate debt-to-income ratio
        $totalMonthlyExpenses = 
            $validated['grocery_expenses'] + 
            $validated['other_expenses'] + 
            $validated['existing_credits'];
        
        $debtToIncomeRatio = $totalMonthlyExpenses / $validated['monthly_income'];

        // Eligibility criteria
        $isEligible = 
            $validated['monthly_income'] >= 5000 && // Minimum income threshold
            $debtToIncomeRatio <= 0.4; // Debt-to-income ratio max 40%

        return response()->json([
            'data' => [
                'is_eligible' => $isEligible,
                'income_too_low' => $validated['monthly_income'] < 5000,
                'debt_to_income_ratio_high' => $debtToIncomeRatio > 0.4,
            ]
        ]);
    }

    /**
 * Save an incomplete loan application
 */
public function saveIncompleteLoanApplication(Request $request)
{
    $validated = $request->validate([
        'id_number' => 'nullable|string',
        'amount' => 'required|numeric|min:200|max:10000',
        'status' => 'nullable|string|in:incomplete,rejected', // Allow explicitly setting status
        'additional_data' => 'nullable|array',
    ]);

    $user = Auth::user();

    // Create or update loan application
    $application = LoanApplication::updateOrCreate(
        [
            'user_id' => $user->id,
            'status' => 'incomplete', // Find by incomplete status
        ],
        [
            'id_number' => $validated['id_number'] ?? null,
            'amount' => $validated['amount'],
            'status' => $validated['status'] ?? 'incomplete', // Use provided status or default to incomplete
            'additional_data' => $validated['additional_data']
        ]
    );

    return response()->json([
        'data' => [
            'application_id' => $application->id,
            'message' => 'Loan application saved successfully'
        ]
    ]);
}

    /**
     * Fetch an incomplete loan application
     */
public function getSavedApplication(Request $request)
{
    $user = auth()->user();
    $savedApplication = LoanApplication::where('user_id', $user->id)
        ->where('status', 'incomplete')
        ->orderBy('updated_at', 'desc')
        ->first();
    
    if (!$savedApplication) {
        return response()->json(['data' => null]);
    }
    
    return response()->json(['data' => $savedApplication]);
}


  /**
 * Fetch saved loan applications with pagination
 */
public function getSavedApplications(Request $request)
{
    $user = auth()->user();

    // Fetch saved applications for the user with pagination
    $savedApplications = LoanApplication::where('user_id', $user->id)
        ->orderBy('updated_at', 'desc')
        ->paginate(5); // Change the number as per your requirement

    return response()->json([
        'data' => $savedApplications->items(),
        'current_page' => $savedApplications->currentPage(),
        'last_page' => $savedApplications->lastPage(),
        'per_page' => $savedApplications->perPage(),
        'total' => $savedApplications->total(),
    ]);
}

/**
 * Update loan application status
 */
public function updateLoanStatus(Request $request, $loanId)
{
    $validated = $request->validate([
        'status' => 'required|string|in:pending_review,approved,rejected,cancelled,completed',
        'rejection_reason' => 'nullable|string|required_if:status,rejected',
        'cancellation_reason' => 'nullable|string|required_if:status,cancelled'
    ]);

    $user = Auth::user();
    
    $loanApplication = LoanApplication::where('id', $loanId)
        ->where('user_id', $user->id)
        ->firstOrFail();
    
    // Store the old status for comparison
    $oldStatus = $loanApplication->status;
    
    // Update the status
    $loanApplication->status = $validated['status'];
    
    // Add reason if applicable
    if ($validated['status'] === 'rejected' && isset($validated['rejection_reason'])) {
        $loanApplication->rejection_reason = $validated['rejection_reason'];
    }
    
    if ($validated['status'] === 'cancelled' && isset($validated['cancellation_reason'])) {
        $loanApplication->cancellation_reason = $validated['cancellation_reason'];
    }
    
    $loanApplication->save();
    
    // If status changed to rejected or cancelled, clean up documents
    if (in_array($validated['status'], ['rejected', 'cancelled']) && $oldStatus !== $validated['status']) {
        // Use the cleanup service to delete documents
        $cleanupService = app(App\Services\CleanupService\LoanDocumentCleanupService::class);
        
        // Schedule document cleanup as a background job to avoid blocking the request
        dispatch(function () use ($cleanupService, $loanApplication) {
            $cleanupService->cleanupApplicationDocuments($loanApplication);
        })->afterCommit();
    }
    
    return response()->json([
        'data' => [
            'message' => 'Loan application status updated successfully',
            'status' => $validated['status']
        ]
    ]);
}

/**
 * Decline loan contract
 */
public function declineLoanContract($loanId)
{
    $user = Auth::user();

    $loanApplication = LoanApplication::where('id', $loanId)
        ->where('user_id', $user->id)
        ->firstOrFail();

    $contract = $loanApplication->contract;

    // Update contract and loan application status
    $contract->update([
        'status' => 'declined',
        'declined_at' => now(),
    ]);

    // Store the old status for comparison
    $oldStatus = $loanApplication->status;

    // Update loan application status
    $loanApplication->update([
        'status' => 'cancelled',
    ]);

    // If status changed to cancelled, clean up documents
    if ($oldStatus !== 'cancelled') {
        // Use the cleanup service to delete documents
        $cleanupService = app(App\Services\CleanupService\LoanDocumentCleanupService::class);
        
        // Schedule document cleanup as a background job to avoid blocking the request
        dispatch(function () use ($cleanupService, $loanApplication) {
            $cleanupService->cleanupApplicationDocuments($loanApplication);
        })->afterCommit();
    }

    return response()->json([
        'data' => [
            'message' => 'Contract declined. Loan application cancelled.',
            'status' => 'cancelled'
        ]
    ]);
}

/**
 * Mark an application as rejected due to eligibility check failure
 */
public function markApplicationAsRejected(Request $request)
{
    $validated = $request->validate([
        'financial_details' => 'required|array',
        'rejection_reason' => 'nullable|string',
        'rejection_date' => 'nullable|date',
    ]);

    $user = Auth::user();

    try {
        DB::beginTransaction();

        // Check if there's an existing incomplete application
        $loanApplication = LoanApplication::where('user_id', $user->id)
            ->where('status', 'incomplete')
            ->first();

        if ($loanApplication) {
            // Update the existing application
            $loanApplication->status = 'rejected';
            $loanApplication->rejection_reason = $validated['rejection_reason'] ?? 'Failed eligibility check';
            $loanApplication->additional_data = array_merge(
                (array)$loanApplication->additional_data, 
                $validated['financial_details']
            );
            $loanApplication->save();
            
            $isExisting = true;
        } else {
            // Create a new rejected application
            $loanApplication = LoanApplication::create([
                'user_id' => $user->id,
                'id_number' => $validated['financial_details']['id_number'] ?? null,
                'amount' => $validated['financial_details']['loan_amount'] ?? 200.0,
                'status' => 'rejected',
                'rejection_reason' => $validated['rejection_reason'] ?? 'Failed eligibility check',
                'additional_data' => $validated['financial_details'],
            ]);
            
            $isExisting = false;
        }

        DB::commit();

        // If the application has documents and status was changed, clean them up
        if ($isExisting && !empty($loanApplication->documents)) {
            // Use the cleanup service to delete documents
            $cleanupService = app(App\Services\CleanupService\LoanDocumentCleanupService::class);
            
            // Schedule document cleanup as a background job
            dispatch(function () use ($cleanupService, $loanApplication) {
                $cleanupService->cleanupApplicationDocuments($loanApplication);
            })->afterCommit();
            
            \Log::info('Document cleanup scheduled for rejected loan application', [
                'loan_id' => $loanApplication->id,
                'user_id' => $user->id
            ]);
        }

        return response()->json([
            'data' => [
                'application_id' => $loanApplication->id,
                'status' => 'rejected',
                'message' => 'Application marked as rejected'
            ]
        ]);
    } catch (\Exception $e) {
        DB::rollBack();
        \Log::error('Failed to mark application as rejected: ' . $e->getMessage(), [
            'user_id' => $user->id,
            'trace' => $e->getTraceAsString()
        ]);
        
        return response()->json([
            'error' => 'Failed to mark application as rejected',
            'message' => $e->getMessage()
        ], 500);
    }
}

    /**
 * Submit full loan application with documents
 */
public function submitLoanApplication(Request $request)
{
    // Validate the base data
    $validated = $request->validate([
        'id_number' => 'required|string|size:13',
        'amount' => 'required|numeric|min:200|max:10000',
        'saved_application_id' => 'nullable|string|exists:loan_applications,id', // Add validation for saved application ID
    ]);

    // Validate that documents exist
    if (!$request->hasFile('documents')) {
        return response()->json([
            'error' => 'Documents are required'
        ], 422);
    }

    $user = Auth::user();

    // Start a database transaction
    return DB::transaction(function () use ($request, $user, $validated) {
        // Determine if we're updating an existing application or creating a new one
        $loanApplication = null;
        
        if ($request->has('saved_application_id')) {
            // Find the existing application
            $loanApplication = LoanApplication::where('id', $request->saved_application_id)
                ->where('user_id', $user->id)
                ->where('status', 'incomplete')
                ->first();
                
            // Log if we found it
            if ($loanApplication) {
                \Log::info("Updating existing loan application", [
                    'id' => $loanApplication->id,
                    'user_id' => $user->id
                ]);
            }
        }
        
        // If we didn't find an existing application or no ID was provided, create new
        if (!$loanApplication) {
            $loanApplication = LoanApplication::create([
                'user_id' => $user->id,
                'id_number' => $validated['id_number'],
                'amount' => $validated['amount'],
                'status' => 'pending_review',
            ]);
            
            \Log::info("Created new loan application", [
                'id' => $loanApplication->id,
                'user_id' => $user->id
            ]);
        } else {
            // Update the existing application with new data
            $loanApplication->update([
                'id_number' => $validated['id_number'],
                'amount' => $validated['amount'],
                'status' => 'pending_review', // Change status from incomplete to pending_review
            ]);
            
            \Log::info("Updated loan application status", [
                'id' => $loanApplication->id,
                'user_id' => $user->id,
                'new_status' => 'pending_review'
            ]);
        }

        // Store uploaded documents
        $documentPaths = [];
        
        // Get all documents from the request
        $documents = $request->file('documents');
        
        if (is_array($documents)) {
            foreach ($documents as $docType => $file) {
                // Clean document type name by removing brackets
                $cleanDocType = str_replace(['[', ']'], '', $docType);
                
                $path = $this->documentSecurityService->storeDocument(
                    $file, 
                    $loanApplication->id, 
                    $cleanDocType
                );
                $documentPaths[$cleanDocType] = $path;
                
                \Log::info("Stored document for loan application", [
                    'loan_id' => $loanApplication->id,
                    'document_type' => $cleanDocType,
                    'path' => $path
                ]);
            }
        }

        // Update loan application with document paths
        $loanApplication->update(['documents' => $documentPaths]);

        return response()->json([
            'data' => [
                'application_id' => $loanApplication->id,
                'message' => 'Loan application submitted successfully',
                'was_update' => $request->has('saved_application_id') ? true : false
            ]
        ]);
    });
}


    /**
     * Fetch loan contract details
     */
    public function fetchLoanContract($loanId)
    {
        $user = Auth::user();

        $loanApplication = LoanApplication::where('id', $loanId)
            ->where('user_id', $user->id)
            ->firstOrFail();

        // Find or generate contract
        $contract = LoanContract::firstOrCreate(
            ['loan_application_id' => $loanApplication->id],
            [
                'title' => 'Loan Contract for Application #' . $loanApplication->id,
                'content' => $this->generateLoanContractContent($loanApplication),
                'status' => 'pending_acceptance',
                'expires_at' => now()->addDays(7),
            ]
        );

        return response()->json([
            'data' => [
                'id' => $contract->id,
                'title' => $contract->title,
                'content' => $contract->content,
                'status' => $contract->status,
                'expires_at' => $contract->expires_at,
                'created_at' => $contract->created_at,
            ]
        ]);
    }

    /**
     * Generate dynamic loan contract content
     */
    private function generateLoanContractContent(LoanApplication $loanApplication)
    {
        // Find appropriate contract template
        $contractTemplate = ContractTemplate::where('loan_type', 'personal')
            ->where('min_amount', '<=', $loanApplication->amount)
            ->where('max_amount', '>=', $loanApplication->amount)
            ->first() ?? 
            ContractTemplate::where('is_default', true)->firstOrFail();

        // Interpolate dynamic values
        return strtr($contractTemplate->content, [
            '{LOAN_AMOUNT}' => number_format($loanApplication->amount, 2),
            '{USER_NAME}' => $loanApplication->user->name,
            '{ID_NUMBER}' => $loanApplication->id_number,
            '{INTEREST_RATE}' => $contractTemplate->base_interest_rate ?? 15.5,
            '{REPAYMENT_PERIOD}' => $contractTemplate->default_term_months ?? 36,
        ]);
    }

    /**
     * Accept loan contract
     */
    public function acceptLoanContract($loanId)
    {
        $user = Auth::user();

        $loanApplication = LoanApplication::where('id', $loanId)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $contract = $loanApplication->contract;

        // Validate contract acceptance
        if ($contract->status !== 'pending_acceptance' || 
            $contract->expires_at < now()) {
            
            $loanApplication->update(['status' => 'cancelled']);
            
            return response()->json([
                'error' => 'Contract has expired or is no longer valid.',
                'status' => 'cancelled'
            ], 400);
        }

        // Update contract and loan application status
        $contract->update([
            'status' => 'accepted',
            'accepted_at' => now(),
        ]);

        $loanApplication->update([
            'status' => 'pending_disbursal',
        ]);

        // Generate and email contract PDF
        $pdfPath = $this->generateContractPdf($loanId, true);

        return response()->json([
            'data' => [
                'message' => 'Contract accepted successfully',
                'status' => 'accepted'
            ]
        ]);
    }

    /**
     * Decline loan contract
     
    public function declineLoanContract($loanId)
    {
        $user = Auth::user();

        $loanApplication = LoanApplication::where('id', $loanId)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $contract = $loanApplication->contract;

        // Update contract and loan application status
        $contract->update([
            'status' => 'declined',
            'declined_at' => now(),
        ]);

        $loanApplication->update([
            'status' => 'cancelled',
        ]);

        return response()->json([
            'data' => [
                'message' => 'Contract declined. Loan application cancelled.',
                'status' => 'cancelled'
            ]
        ]);
    }*/

    /**
     * Generate contract PDF and email
     */
    public function generateContractPdf($loanId, $isAcceptance = true)
    {
        $loanApplication = LoanApplication::findOrFail($loanId);
        $contract = $loanApplication->contract;
        $user = $loanApplication->user;

        // Use secure disk for logos and signatures
        $logoPath = Storage::disk('company_assets')->path('logos/main_logo.png');
        $signaturePath = $isAcceptance 
            ? null 
            : Storage::disk('company_assets')->path('signatures/authorized_signature.png');

        $pdf = PDF::loadView('pdfs.loan_contract', [
            'contract' => $contract,
            'loanApplication' => $loanApplication,
            'user' => $user,
            'logoPath' => $logoPath,
            'signaturePath' => $signaturePath,
            'isAcceptance' => $isAcceptance,
        ]);

        // Generate unique filename
        $filename = "loan_contract_{$loanId}_" . 
            ($isAcceptance ? 'acceptance' : 'paid_up') . 
            '_' . now()->format('YmdHis') . '.pdf';

        // Save PDF locally
        $pdfPath = storage_path("app/loan_pdfs/{$filename}");
        $pdf->save($pdfPath);

        // Send email with PDF
        Mail::to($user->email)->send(new LoanContractMail(
            $pdfPath, 
            $filename, 
            $isAcceptance,
            $user,
            $loanApplication
        ));

        return $pdfPath;
    }
}
