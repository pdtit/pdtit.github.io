# LinkedIn Automation Setup Script
# Run this to configure MCP servers for automated LinkedIn posting

Write-Host "=== LinkedIn Automation Setup ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if tools/mcp-servers exists
if (!(Test-Path "tools/mcp-servers")) {
    Write-Host "❌ tools/mcp-servers directory not found" -ForegroundColor Red
    Write-Host "Run this script from the repo root: c:\007FFFLearning_Blog" -ForegroundColor Yellow
    exit 1
}

# Step 2: Install npm dependencies
Write-Host "📦 Installing MCP server dependencies..." -ForegroundColor Yellow
Push-Location "tools/mcp-servers"
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm install failed" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Step 3: Collect credentials
Write-Host "🔑 Credential Configuration" -ForegroundColor Cyan
Write-Host "This script will update .vscode/settings.json with your MCP server config." -ForegroundColor Yellow
Write-Host ""

# Image Generation Backend Choice
Write-Host "Image Generation Backend:" -ForegroundColor White
Write-Host "  1. Azure OpenAI (direct)" -ForegroundColor Gray
Write-Host "  2. Azure AI Foundry (recommended - better tracking & monitoring)" -ForegroundColor Gray
Write-Host "  3. Skip (configure later or use manual image creation)" -ForegroundColor Gray
$backendChoice = Read-Host "  Your choice (1, 2, or 3)"

$azureKey = $null
$azureEndpoint = $null

if ($backendChoice -eq "1") {
    Write-Host ""
    Write-Host "Azure OpenAI Configuration:" -ForegroundColor Cyan
    $azureKey = Read-Host "  API Key"
    $azureEndpoint = Read-Host "  Endpoint (e.g., https://your-resource.openai.azure.com)"
    
    if (!$azureEndpoint.StartsWith("https://")) {
        Write-Host "⚠️  Endpoint should start with https://" -ForegroundColor Yellow
        $azureEndpoint = "https://" + $azureEndpoint
    }
    Write-Host "✅ Azure OpenAI configured" -ForegroundColor Green
}
elseif ($backendChoice -eq "2") {
    Write-Host ""
    Write-Host "Azure AI Foundry Configuration:" -ForegroundColor Cyan
    Write-Host "  Get these from: https://ai.azure.com → Your Project → Deployments → dalle3-linkedin" -ForegroundColor Gray
    $azureKey = Read-Host "  Primary Key (from deployment)"
    $azureEndpoint = Read-Host "  Target URI (should end with /v1/images/generations)"
    
    if (!$azureEndpoint.StartsWith("https://")) {
        Write-Host "⚠️  Endpoint should start with https://" -ForegroundColor Yellow
        $azureEndpoint = "https://" + $azureEndpoint
    }
    
    # Validate Foundry endpoint format
    if (!$azureEndpoint.Contains("inference.ml.azure.com")) {
        Write-Host "⚠️  Foundry endpoints typically contain 'inference.ml.azure.com'" -ForegroundColor Yellow
        $confirm = Read-Host "  Continue anyway? (y/n)"
        if ($confirm -ne "y") {
            Write-Host "❌ Setup cancelled" -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "✅ Azure AI Foundry configured" -ForegroundColor Green
}
else {
    Write-Host "⏭️  Image generation skipped (you can configure manually later)" -ForegroundColor Yellow
}

# LinkedIn Helper (no API needed!)
Write-Host ""
Write-Host "LinkedIn Helper will be configured automatically" -ForegroundColor Green
Write-Host "  No OAuth or company page required!" -ForegroundColor Gray
Write-Host "  Automates: copy to clipboard + open browser" -ForegroundColor Gray

# Step 4: Build settings.json config
$mcpServers = @{}

if ($azureKey -and $azureEndpoint) {
    $mcpServers["microsoft-designer"] = @{
        command = "node"
        args = @("c:\007FFFLearning_Blog\tools\mcp-servers\microsoft-designer.js")
        env = @{
            AZURE_OPENAI_API_KEY = $azureKey
            AZURE_OPENAI_ENDPOINT = $azureEndpoint
        }
    }
    Write-Host "✅ Microsoft Designer MCP configured" -ForegroundColor Green
}

# Always add LinkedIn helper (no credentials needed)
$mcpServers["linkedin-helper"] = @{
    command = "node"
    args = @("c:\007FFFLearning_Blog\tools\mcp-servers\linkedin-helper.js")
}
Write-Host "✅ LinkedIn Helper MCP configured" -ForegroundColor Green

if ($mcpServers.Count -eq 0) {
    Write-Host ""
    Write-Host "⚠️  No MCP servers configured (all fields were skipped)" -ForegroundColor Yellow
    Write-Host "Re-run this script to add credentials, or manually edit .vscode/settings.json" -ForegroundColor Yellow
    exit 0
}

# Step 5: Update .vscode/settings.json
$settingsPath = ".vscode/settings.json"
if (!(Test-Path ".vscode")) {
    New-Item -ItemType Directory -Path ".vscode" | Out-Null
}

$settings = @{}
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
}

if (!$settings["github.copilot.chat.mcp.servers"]) {
    $settings["github.copilot.chat.mcp.servers"] = @{}
}

foreach ($key in $mcpServers.Keys) {
    $settings["github.copilot.chat.mcp.servers"][$key] = $mcpServers[$key]
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath

Write-Host ""
Write-Host "✅ .vscode/settings.json updated" -ForegroundColor Green
Write-Host ""

# Step 6: Next steps
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""



Write-Host "1. Restart VS Code to load the new MCP servers" -ForegroundColor White
Write-Host "2. Verify MCP servers are loaded:" -ForegroundColor White
Write-Host "   - Open GitHub Copilot chat" -ForegroundColor Gray
Write-Host "   - Type '@workspace list MCP servers'" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Test image generation:" -ForegroundColor White
Write-Host "   - In Copilot: 'Generate a test image using microsoft-designer MCP'" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Test LinkedIn Helper:" -ForegroundColor White
Write-Host "   - In Copilot: 'Prepare my blog post for LinkedIn'" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Test full workflow:" -ForegroundColor White
Write-Host "   - Set a blog post to draft: false" -ForegroundColor Gray
Write-Host "   - Run the LinkedIn Poster agent" -ForegroundColor Gray
Write-Host "   - Paste + drag image + post (10 seconds!)" -ForegroundColor Gray
Write-Host ""
Write-Host "📖 Documentation:" -ForegroundColor Cyan
Write-Host "   - Quick start: QUICK_START.md" -ForegroundColor Gray
Write-Host "   - LinkedIn personal accounts: LINKEDIN_PERSONAL_ACCOUNTS.md" -ForegroundColor Gray
Write-Host "   - Foundry setup: tools/FOUNDRY_IMAGE_GENERATION.md" -ForegroundColor Gray
Write-Host "   - Image options: tools/IMAGE_GENERATION_OPTIONS.md" -ForegroundColor Gray
Write-Host ""

# Security warning
Write-Host "⚠️  SECURITY NOTE" -ForegroundColor Yellow
Write-Host "API keys are now stored in .vscode/settings.json" -ForegroundColor Yellow
Write-Host "Make sure .vscode/settings.json is in .gitignore!" -ForegroundColor Yellow
Write-Host ""

# Check .gitignore
if (!(Select-String -Path ".gitignore" -Pattern "\.vscode/settings\.json" -Quiet)) {
    Write-Host "Adding .vscode/settings.json to .gitignore..." -ForegroundColor Yellow
    Add-Content -Path ".gitignore" -Value "`n# MCP server credentials`n.vscode/settings.json"
    Write-Host "✅ Added to .gitignore" -ForegroundColor Green
} else {
    Write-Host "✅ .vscode/settings.json already in .gitignore" -ForegroundColor Green
}

Write-Host ""
Write-Host "Setup complete! 🎉" -ForegroundColor Green
