#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generate LinkedIn post image using MAI-Image-2.5
.DESCRIPTION
    Calls Azure AI Foundry MAI API to generate an image from a prompt
.PARAMETER Prompt
    The image generation prompt
.PARAMETER OutputPath
    Path where the image should be saved
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Prompt,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,
    
    [Parameter(Mandatory=$false)]
    [int]$Width = 1024,
    
    [Parameter(Mandatory=$false)]
    [int]$Height = 1024
)

$ErrorActionPreference = "Stop"

Write-Host "🎨 Generating image with MAI-Image-2.5..." -ForegroundColor Cyan

# Get Azure AD token with correct scope
Write-Host "Getting Azure AD token..." -ForegroundColor Gray
$tokenResponse = az account get-access-token --scope https://ai.azure.com/.default | ConvertFrom-Json
$token = $tokenResponse.accessToken

# Build API request
# Note: MAI API uses resource-level endpoint (not project-scoped)
$endpoint = "https://aif-research-lyqhr.services.ai.azure.com/mai/v1/images/generations"
$body = @{
    model = "MAI-Image-2.5"  # Deployment name
    prompt = $Prompt
    width = $Width
    height = $Height
} | ConvertTo-Json

# Call MAI API
Write-Host "Calling MAI image generation API..." -ForegroundColor Gray
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "Endpoint: $endpoint" -ForegroundColor Gray
Write-Host "Model/Deployment: MAI-Image-2.5" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body -TimeoutSec 90 -Verbose
    
    # Decode base64 image
    if ($response.data -and $response.data[0].b64_json) {
        $imageBytes = [Convert]::FromBase64String($response.data[0].b64_json)
        
        # Ensure directory exists
        $outputDir = Split-Path -Parent $OutputPath
        if (!(Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        # Save image
        [System.IO.File]::WriteAllBytes($OutputPath, $imageBytes)
        Write-Host "✅ Image saved to: $OutputPath" -ForegroundColor Green
    } else {
        Write-Host "❌ Unexpected response format" -ForegroundColor Red
        Write-Host ($response | ConvertTo-Json -Depth 10)
        exit 1
    }
} catch {
    Write-Host "❌ API call failed: $_" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
