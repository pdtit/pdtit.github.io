# Test MAI-Image-2.5 Image Generation
# Direct API call to verify authentication and endpoint work

$endpoint = "https://aif-research-lyqhr.services.ai.azure.com/api/projects/aifp-research-lyqhr"
$model = "MAI-Image-2.5"

Write-Host "🧪 Testing MAI-Image-2.5 Image Generation" -ForegroundColor Cyan
Write-Host "Endpoint: $endpoint"
Write-Host "Model: $model"
Write-Host ""

# Read the image prompt
$promptPath = "c:\007FFFLearning_Blog\social\linkedin\testing-linkedin-automation-mai-image\image-prompt.md"
$promptContent = Get-Content $promptPath -Raw

# Extract just the main prompt text (remove markdown headers)
$prompt = ($promptContent -split "## Main Prompt")[1] -split "## Negative Prompt" | Select-Object -First 1
$prompt = $prompt.Trim()

Write-Host "📝 Prompt (first 200 chars):" -ForegroundColor Yellow
Write-Host $prompt.Substring(0, [Math]::Min(200, $prompt.Length))
Write-Host "..."
Write-Host ""

# Get Azure AD token using Azure CLI (must be logged in)
Write-Host "🔐 Getting Azure AD token..." -ForegroundColor Cyan
try {
    $token = az account get-access-token --resource https://ai.azure.com --query accessToken -o tsv
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to get Azure token. Run 'az login' first." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Token obtained" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Azure CLI error: $_" -ForegroundColor Red
    Write-Host "Make sure you're logged in with 'az login'" -ForegroundColor Yellow
    exit 1
}

# Call MAI-Image-2.5 API
Write-Host "🎨 Calling MAI-Image-2.5 API..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$body = @{
    model = $model
    prompt = $prompt.Substring(0, [Math]::Min(4000, $prompt.Length))
    n = 1
    size = "1792x1024"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod `
        -Uri "$endpoint/inference/text-to-image/submissions?api-version=2024-05-01-preview" `
        -Method Post `
        -Headers $headers `
        -Body $body `
        -TimeoutSec 90
    
    Write-Host "✅ API call successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Yellow
    $response | ConvertTo-Json -Depth 10
    
    # Check if we got a direct URL or need to poll
    if ($response.data -and $response.data[0].url) {
        $imageUrl = $response.data[0].url
        Write-Host ""
        Write-Host "🖼️  Image URL: $imageUrl" -ForegroundColor Green
        
        # Download the image
        $outputPath = "c:\007FFFLearning_Blog\social\linkedin\testing-linkedin-automation-mai-image\image.png"
        Write-Host "⬇️  Downloading image..." -ForegroundColor Cyan
        
        Invoke-WebRequest -Uri $imageUrl -OutFile $outputPath
        
        Write-Host "✅ Image saved to: $outputPath" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎉 Test successful! Image generation works!" -ForegroundColor Green
        
    } elseif ($response.status -eq "submitted" -or $response.status -eq "running") {
        Write-Host "⏳ Image generation is async. Job ID: $($response.id)" -ForegroundColor Yellow
        Write-Host "   Would need to poll for completion..." -ForegroundColor Yellow
    } else {
        Write-Host "⚠️  Unexpected response format" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ API call failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response body: $responseBody" -ForegroundColor Red
    }
    
    exit 1
}
