<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class LoanContractMail extends Mailable
{
    use Queueable, SerializesModels;

    public $pdfPath;
    public $filename;
    public $isAcceptance;
    public $user;
    public $loanApplication;

    /**
     * Create a new message instance.
     */
    public function __construct(
        $pdfPath, 
        $filename, 
        $isAcceptance, 
        $user, 
        $loanApplication
    ) {
        $this->pdfPath = $pdfPath;
        $this->filename = $filename;
        $this->isAcceptance = $isAcceptance;
        $this->user = $user;
        $this->loanApplication = $loanApplication;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        $subject = $this->isAcceptance 
            ? 'Loan Contract Acceptance' 
            : 'Loan Paid-Up Certificate';

        return new Envelope(
            subject: $subject,
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.loan_contract',
            with: [
                'user' => $this->user,
                'isAcceptance' => $this->isAcceptance,
                'loanApplication' => $this->loanApplication
            ]
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array
     */
    public function attachments()
    {
        return [
            \Illuminate\Mail\Mailables\Attachment::fromPath($this->pdfPath)
                ->as($this->filename)
                ->withMime('application/pdf')
        ];
    }
}
