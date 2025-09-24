<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class DocumentSecurityService
{
    /**
     * Generate a secure filename for a document
     * 
     * @param int $loanId
     * @param string $documentType
     * @param UploadedFile $file
     * @return string
     */
    public function generateSecureFilename($loanId, $documentType, UploadedFile $file)
    {
        return Str::uuid() . '_' . 
               hash('sha256', $loanId . $documentType . time()) . 
               '.' . $file->getClientOriginalExtension();
    }

    /**
     * Store a document securely
     * 
     * @param UploadedFile $file
     * @param int $loanId
     * @param string $documentType
     * @return string
     */
    public function storeDocument(UploadedFile $file, $loanId, $documentType)
    {
        // Generate secure filename
        $filename = $this->generateSecureFilename($loanId, $documentType, $file);

        // Store in private loan documents disk
        return $file->storeAs(
            "loans/{$loanId}/{$documentType}", 
            $filename, 
            'loan_documents'
        );
    }

    /**
     * Generate a temporary download URL
     * 
     * @param string $documentPath
     * @param string $disk
     * @param int $minutes
     * @return string
     */
    public function generateTemporaryDownloadUrl(
        $documentPath, 
        $disk = 'loan_documents', 
        $minutes = 15
    ) {
        return Storage::disk($disk)
            ->temporaryUrl(
                $documentPath, 
                now()->addMinutes($minutes)
            );
    }
}
