<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: DejaVu Sans, sans-serif; }
        .header { 
            position: relative; 
            margin-bottom: 20px; 
        }
        .logo { 
            position: absolute; 
            top: 0; 
            left: 0; 
            max-width: 150px; 
        }
        .signature { 
            position: absolute; 
            bottom: 0; 
            left: 0; 
            max-width: 200px; 
        }
    </style>
</head>
<body>
    <div class="header">
        @if(file_exists($logoPath))
            <img src="{{ $logoPath }}" class="logo" alt="Company Logo">
        @endif
    </div>

    <h1>{{ $contract->title }}</h1>

    <p>Loan Application Number: {{ $loanApplication->id }}</p>
    <p>Borrower: {{ $user->name }}</p>
    <p>Loan Amount: R{{ number_format($loanApplication->amount, 2) }}</p>

    <div>
        {!! nl2br(e($contract->content)) !!}
    </div>

    @if($isAcceptance === false && file_exists($signaturePath))
        <div style="margin-top: 50px;">
            <img src="{{ $signaturePath }}" class="signature" alt="Authorized Signature">
            <p>Authorized Signature</p>
        </div>
    @endif
</body>
</html>
