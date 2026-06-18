# Validate-HugoDraft.ps1
# PostToolUse hook for the Blog Composer agent.
# Runs after every tool invocation. If the tool just edited a file under
# content/post/, runs Hugo in --renderToMemory mode to surface frontmatter
# or template errors immediately. If Hugo fails, returns a blocking response
# so the agent sees the build error and can fix it.
#
# Stdin: JSON describing the tool call (see VS Code hooks docs).
# Stdout: optional JSON for the agent runtime.
# Exit codes: 0 = ok, 2 = blocking error, other = non-blocking warning.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# 1. Read stdin payload (the hook contract gives us JSON on stdin).
$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

try {
  $payload = $raw | ConvertFrom-Json -ErrorAction Stop
} catch {
  # If we can't parse the payload, don't block — just exit clean.
  exit 0
}

# 2. Only react to write-style tools. Different runtimes label these slightly
# differently, so match generously.
$toolName = "$($payload.tool_name)$($payload.toolName)$($payload.name)"
$isEdit = $toolName -match '(?i)(edit|write|create|replace).*file'
if (-not $isEdit) { exit 0 }

# 3. Pull candidate file paths out of the payload.
$candidatePaths = @()
foreach ($prop in 'file_path','filePath','path','target_file') {
  $val = $payload.tool_input.$prop
  if ($val) { $candidatePaths += $val }
  $val = $payload.toolInput.$prop
  if ($val) { $candidatePaths += $val }
  $val = $payload.input.$prop
  if ($val) { $candidatePaths += $val }
}

# Filter to posts only.
$postEdits = $candidatePaths | Where-Object { $_ -match 'content[\\/]+post[\\/]+.*\.md$' }
if (-not $postEdits) { exit 0 }

# 4. Locate Hugo. Prefer the pinned binary checked into the repo.
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$hugo = Join-Path $repoRoot 'tools\hugo\hugo.exe'
if (-not (Test-Path $hugo)) {
  $hugo = (Get-Command hugo -ErrorAction SilentlyContinue).Source
}
if (-not $hugo) {
  # Hugo not available — emit a soft warning, don't block.
  Write-Host "[validate-hugo-draft] Hugo binary not found; skipping validation."
  exit 0
}

# 5. Run Hugo in render-to-memory mode (no disk writes to docs/).
Push-Location $repoRoot
try {
  $output = & $hugo --renderToMemory --quiet --logLevel error -D 2>&1
  $code = $LASTEXITCODE
} finally {
  Pop-Location
}

if ($code -eq 0) {
  Write-Host "[validate-hugo-draft] OK ($($postEdits -join ', '))"
  exit 0
}

# 6. Hugo failed — return a blocking decision so the agent sees the error.
$body = @{
  decision = 'block'
  reason   = "Hugo validation failed for $($postEdits -join ', '):`n$($output | Out-String)"
} | ConvertTo-Json -Depth 4 -Compress

Write-Output $body
exit 2
