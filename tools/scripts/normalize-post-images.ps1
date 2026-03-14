param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

$postDir = Join-Path $PSScriptRoot '..\..\content\post'
$imageDir = Join-Path $postDir 'images'

if (-not (Test-Path -LiteralPath $postDir)) {
    throw "Post directory not found: $postDir"
}
if (-not (Test-Path -LiteralPath $imageDir)) {
    throw "Image directory not found: $imageDir"
}

function Get-PostDateString {
    param([string]$Content)

    $dateKeys = @('publishDate', 'publishdate', 'date')
    foreach ($key in $dateKeys) {
        $m = [regex]::Match($Content, "(?im)^" + [regex]::Escape($key) + ":\s*(.+)$")
        if ($m.Success) {
            $raw = $m.Groups[1].Value.Trim().Trim("'").Trim('"')
            try {
                return ([datetimeoffset]::Parse($raw)).ToString('yyyy-MM-dd')
            }
            catch {
                # Continue to fallback keys.
            }
        }
    }

    return $null
}

function Normalize-Token {
    param([string]$Value)

    $lower = $Value.ToLowerInvariant()
    $token = [regex]::Replace($lower, '[^a-z0-9]+', '-')
    $token = $token.Trim('-')
    if ([string]::IsNullOrWhiteSpace($token)) {
        return 'img'
    }
    return $token
}

function Get-ShortHash {
    param([string]$Value)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $hashBytes = $sha1.ComputeHash($bytes)
    }
    finally {
        $sha1.Dispose()
    }

    $hex = [BitConverter]::ToString($hashBytes).Replace('-', '').ToLowerInvariant()
    return $hex.Substring(0, 8)
}

$postFiles = Get-ChildItem -LiteralPath $postDir -File -Filter '*.md' | Sort-Object Name

$summary = [ordered]@{
    PostsScanned = 0
    PostsUpdated = 0
    ImageRefsUpdated = 0
    CopiesCreated = 0
    MissingSourceImages = 0
}

foreach ($post in $postFiles) {
    $summary.PostsScanned++

    $content = Get-Content -LiteralPath $post.FullName -Raw
    $postDate = Get-PostDateString -Content $content
    if (-not $postDate) {
        Write-Host "Skipping (no parseable date): $($post.Name)"
        continue
    }

    $matches = [regex]::Matches($content, '!\[[^\]]*\]\((\.\./images/[^)]+)\)')
    if ($matches.Count -eq 0) {
        continue
    }

    $refMap = @{}

    foreach ($match in $matches) {
        $originalRef = $match.Groups[1].Value
        if ($refMap.ContainsKey($originalRef)) {
            continue
        }

        $refPath = $originalRef
        $queryIndex = $refPath.IndexOf('?')
        if ($queryIndex -ge 0) {
            $refPath = $refPath.Substring(0, $queryIndex)
        }
        $hashIndex = $refPath.IndexOf('#')
        if ($hashIndex -ge 0) {
            $refPath = $refPath.Substring(0, $hashIndex)
        }

        $decodedRefPath = [uri]::UnescapeDataString($refPath)
        if (-not $decodedRefPath.StartsWith('../images/')) {
            continue
        }

        $fileName = $decodedRefPath.Substring('../images/'.Length)
        $sourcePath = Join-Path $imageDir $fileName

        if (-not (Test-Path -LiteralPath $sourcePath)) {
            Write-Host "Missing source image for $($post.Name): $decodedRefPath"
            $summary.MissingSourceImages++
            continue
        }

        $ext = [io.path]::GetExtension($fileName).ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($ext)) {
            $ext = '.png'
        }

        $normalizedNameMatch = [regex]::Match($fileName, '^screenshot-(\d{4}-\d{2}-\d{2})-[a-z0-9-]+\.[a-z0-9]+$')
        if ($normalizedNameMatch.Success) {
            if ($normalizedNameMatch.Groups[1].Value -eq $postDate) {
                continue
            }
        }

        $hash = Get-ShortHash -Value $fileName
        $newFileName = "screenshot-$postDate-$hash$ext"
        $destPath = Join-Path $imageDir $newFileName

        if (-not (Test-Path -LiteralPath $destPath)) {
            if ($Apply) {
                Copy-Item -LiteralPath $sourcePath -Destination $destPath
            }
            $summary.CopiesCreated++
        }

        $refMap[$originalRef] = "../images/$newFileName"
    }

    if ($refMap.Count -eq 0) {
        continue
    }

    $updated = $content
    foreach ($key in $refMap.Keys) {
        $updated = $updated.Replace($key, $refMap[$key])
    }

    if ($updated -ne $content) {
        if ($Apply) {
            Set-Content -LiteralPath $post.FullName -Value $updated -Encoding utf8
        }
        $summary.PostsUpdated++
        $summary.ImageRefsUpdated += $refMap.Count
        Write-Host "Updated $($post.Name): $($refMap.Count) image refs"
    }
}

Write-Host ""
Write-Host "Normalization summary:"
$summary.GetEnumerator() | ForEach-Object { Write-Host ("- {0}: {1}" -f $_.Key, $_.Value) }

if (-not $Apply) {
    Write-Host ""
    Write-Host "Dry run only. Re-run with -Apply to write changes."
}
