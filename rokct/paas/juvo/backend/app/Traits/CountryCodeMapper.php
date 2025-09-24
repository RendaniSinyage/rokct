<?php

namespace App\Traits;

trait CountryCodeMapper
{
    protected $countryCodeMap = [
        'za' => 'South Africa',
        // Add other country codes as needed
    ];

    protected function getCountryNameFromCode($code)
    {
        return $this->countryCodeMap[strtolower($code)] ?? null;
    }

    protected function validateCountryMatch($countryCode, $returnedCountry)
    {
        $expectedCountry = $this->getCountryNameFromCode($countryCode);
        return $expectedCountry && $returnedCountry === $expectedCountry;
    }
}
