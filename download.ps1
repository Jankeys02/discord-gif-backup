# Step 2 of 2: downloads everything in gifs.json (made by backup-gifs.js) into .\gifs\
# Parallel (8 threads), resumable — already-downloaded files are skipped.
# Keeps oldest->newest order via zero-padded index prefix. Prefers real .gif for Tenor URLs.

$ErrorActionPreference = 'Stop'
$manifest = Join-Path $PSScriptRoot 'gifs.json'
# Real Downloads folder (respects a relocated Downloads, unlike $HOME\Downloads)
$downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$outDir = Join-Path $downloads 'discord-gifs'
New-Item -ItemType Directory -Force $outDir | Out-Null

$items = Get-Content $manifest -Raw | ConvertFrom-Json
$pad = [Math]::Max(3, $items.Count.ToString().Length)
$total = $items.Count

$results = $items | ForEach-Object -ThrottleLimit 8 -Parallel {
    $item = $_
    $outDir = $using:outDir
    $pad = $using:pad
    $total = $using:total

    function Get-Slug($url) {
        $name = [IO.Path]::GetFileNameWithoutExtension(([Uri]$url).AbsolutePath)
        $slug = ($name -replace '[^a-zA-Z0-9-_]', '-') -replace '-+', '-'
        if ($slug.Length -gt 60) { $slug = $slug.Substring(0, 60) }
        if (-not $slug) { $slug = 'gif' }
        return $slug
    }

    $url = $item.url
    $bare = $url -replace '\?.*$', ''  # tenor appends ?c=... tracking
    $ext = [IO.Path]::GetExtension(([Uri]$url).AbsolutePath).TrimStart('.')

    # Old-format Tenor media CDN is dead — recover current URL via the tenor.com/view page key
    if ($bare -match 'media\.tenor\.(com|co)/(videos|images)/[0-9a-f]+/') {
        $rescued = $null
        if ($item.key -match '^https://tenor\.com/view/') {
            try {
                $html = (Invoke-WebRequest -Uri $item.key -TimeoutSec 15 -UserAgent 'Mozilla/5.0').Content
                $m = [regex]::Match($html, 'https://media1?\.tenor\.com/(?:m/)?[A-Za-z0-9_-]+AAAAC/[^"''\\\s>]+\.gif')
                if ($m.Success) { $rescued = $m.Value }
            } catch {}
        }
        if ($rescued) { $url = $rescued; $ext = 'gif' }
        else { return [pscustomobject]@{ index = $item.index; url = $item.url; key = $item.key; status = 'dead' } }
    }

    # Discord-hosted links are signed with a hex expiry — flag stale ones instead of 404ing
    if ($url -match '(cdn|media)\.discordapp\.(com|net)' -and $url -match '[?&]ex=([0-9a-f]+)') {
        $exp = [Convert]::ToInt64($Matches[1], 16) # NB: second -match reset $Matches
        if ($exp -lt [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) {
            Write-Warning "[$($item.index)] EXPIRED Discord link — re-favorite it to refresh: $(Get-Slug $url)"
            return [pscustomobject]@{ index = $item.index; url = $item.url; status = 'expired' }
        }
    }

    # New-format Tenor: swap the 5-char rendition code for AAAAC (= real animated gif)
    if ($bare -match '^https://media\.tenor\.com/([A-Za-z0-9_-]+)/([^/]+)\.\w+$') {
        $id = $Matches[1].Substring(0, $Matches[1].Length - 5) + 'AAAAC'
        $gifUrl = "https://media.tenor.com/$id/$($Matches[2]).gif"
        try {
            Invoke-WebRequest -Uri $gifUrl -Method Head -TimeoutSec 10 | Out-Null
            $url = $gifUrl; $ext = 'gif'
        } catch { $url = $bare } # no gif variant — keep original sans tracking param
    }

    if (-not $ext) { $ext = 'gif' }
    $name = '{0}_{1}.{2}' -f $item.index.ToString().PadLeft($pad, '0'), (Get-Slug $url), $ext
    $dest = Join-Path $outDir $name
    if ((Test-Path $dest) -and (Get-Item $dest).Length -gt 0) {
        Write-Host "[$($item.index)/$total] $name (already saved)"
        return [pscustomobject]@{ index = $item.index; url = $url; status = 'saved' }
    }

    foreach ($try in 1..2) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -TimeoutSec 30
            Write-Host "[$($item.index)/$total] $name"
            return [pscustomobject]@{ index = $item.index; url = $url; status = 'saved' }
        } catch { Start-Sleep -Milliseconds 500 }
    }
    Write-Warning "FAILED [$($item.index)] $url"
    return [pscustomobject]@{ index = $item.index; url = $url; status = 'failed' }
}

$saved = @($results | Where-Object status -eq 'saved')
$deadTenor = @($results | Where-Object status -eq 'dead')
$expired = @($results | Where-Object status -eq 'expired')
$failures = @($results | Where-Object status -eq 'failed')

Write-Host "`nDone. $($saved.Count)/$($items.Count) saved to $outDir"
if ($deadTenor.Count) {
    Write-Host "$($deadTenor.Count) permanently deleted from Tenor (media + page both gone) — listed in dead-tenor.json"
    $deadTenor | ConvertTo-Json | Set-Content (Join-Path $PSScriptRoot 'dead-tenor.json')
}
if ($expired.Count) { Write-Host "$($expired.Count) expired Discord links skipped (re-favorite them, re-run step 1+2)." }
if ($failures.Count) { $failures | Format-Table index, url }
