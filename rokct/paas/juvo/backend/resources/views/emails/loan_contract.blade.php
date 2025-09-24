<?php

<p>Dear {{ $user->name }},</p>

@if($isAcceptance)
    <p>Please find attached your loan contract.</p>
@else
    <p>Congratulations! Your loan has been fully paid. Please find attached your paid-up certificate.</p>
@endif
