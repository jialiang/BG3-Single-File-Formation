param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+\.\d+$')]
    [string]$Version
)

$ErrorActionPreference = 'Stop'

$parts = $Version.Split('.')
$major    = [uint64]$parts[0]
$minor    = [uint64]$parts[1]
$revision = [uint64]$parts[2]
$build    = [uint64]$parts[3]

$Version64 = ($major -shl 55) -bor ($minor -shl 47) -bor ($revision -shl 31) -bor $build
Write-Host "Version: $Version -> Version64: $Version64"

$Root = $PSScriptRoot
$Divine = Join-Path $Root 'LSLib\Packed\Tools\Divine.exe'
$TempDir = Join-Path $Root 'Temp'
$OutDir = Join-Path $Root 'Output'
$Pak = Join-Path $OutDir 'SingleFileFormation.pak'
$Meta = Join-Path $TempDir 'Mods\SingleFileFormation\meta.lsx'

try {
    Remove-Item $TempDir, $OutDir -Recurse -Force -ErrorAction SilentlyContinue

    Copy-Item (Join-Path $Root 'Mods') (Join-Path $TempDir 'Mods') -Recurse
    if (-not $?) { throw 'Copy failed' }

    (Get-Content $Meta -Raw).Replace('<VERSION>', $Version64) | Set-Content $Meta -NoNewline

    & $Divine --action create-package --source $TempDir --destination $Pak --game bg3
    if ($LASTEXITCODE -ne 0) { throw 'Build failed' }

    Write-Host "Built: $Pak"

    $Info = Join-Path $OutDir 'info.json'
    $md5 = (Get-FileHash $Pak -Algorithm MD5).Hash.ToLower()
    $group = [guid]::NewGuid().ToString()
    $created = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffffffK'

    $json = [ordered]@{
        Mods = @([ordered]@{
                Author       = 'Author'
                Name         = 'SingleFileFormation'
                Folder       = 'SingleFileFormation'
                Version      = [string]$Version64
                Description  = 'Makes your companions follow each other in a chain, so that the whole group walks in a single file behind the character you control.'
                UUID         = 'b5ac59e5-35c7-49c4-8ef9-ce697e7893cf'
                Created      = $created
                Dependencies = @()
                Group        = $group
            })
        MD5  = $md5
    }

    $json | ConvertTo-Json -Depth 3 | Set-Content $Info -Encoding UTF8
    Write-Host "Generated: $Info"

    $Zip = Join-Path $OutDir 'SingleFileFormation.zip'
    Compress-Archive -Path $Pak, $Info -DestinationPath $Zip -Force
    Write-Host "Packaged: $Zip"
}
finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Read-Host 'Press Enter to exit'
}
