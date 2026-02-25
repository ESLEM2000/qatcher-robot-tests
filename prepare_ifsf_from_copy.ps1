<#
.SYNOPSIS
    Prépare IFSF_Build à partir d'artefacts .7z déjà copiés (ex: plugin Copy Artifacts).
    Évite les appels HTTP depuis l'agent vers Jenkins (connexion interrompue sur le même serveur).

.PARAMETER ArtifactsDir
    Dossier contenant les 3 .7z (DevProxy, IFSF, XMLConfigDLL). Recherche récursive.

.PARAMETER QAtcherTerminalID
    ID du terminal (ex: Move3500_54227826). Utilisé pour déduire le type si TerminalType non fourni.

.PARAMETER TerminalType
    TETRA | T2 | SELF. Vide = déduit de QAtcherTerminalID.

.PARAMETER OutputDir
    Dossier de sortie (fichiers plats). Par défaut: IFSF_BUILD_DIR ou .\IFSF_Build
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ArtifactsDir,
    [string]$QAtcherTerminalID = $env:QAtcherTerminalID,
    [ValidateSet("TETRA", "T2", "SELF")]
    [string]$TerminalType = "",
    [string]$OutputDir = ""
)

. "$PSScriptRoot\ifsf_config.ps1"

$termType = $TerminalType
if ([string]::IsNullOrWhiteSpace($termType)) {
    $termType = $script:IFSF_TERMINAL_TYPE
}
if ([string]::IsNullOrWhiteSpace($termType)) {
    $termType = Get-IFSFTerminalTypeFromQAtcherID -QAtcherTerminalID $QAtcherTerminalID
}

$outDir = $OutputDir
if ([string]::IsNullOrWhiteSpace($outDir)) {
    $outDir = $script:IFSF_BUILD_DIR
}
$outDir = [System.IO.Path]::GetFullPath($outDir)

if (-not (Test-Path $ArtifactsDir)) {
    Write-Error "Dossier artefacts introuvable: $ArtifactsDir"
    exit 1
}

# 7z
$7z = $null
foreach ($p in @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe")) {
    if ($p -and (Test-Path $p)) { $7z = $p; break }
}
if (-not $7z) { $7z = (Get-Command 7z -ErrorAction SilentlyContinue).Source }
if (-not $7z) {
    Write-Error "7-Zip (7z.exe) est requis. Installez 7-Zip ou ajoutez-le au PATH."
    exit 1
}

# Trouver les 3 .7z (récursif)
$all7z = Get-ChildItem -Path $ArtifactsDir -Recurse -Filter "*.7z" -File | ForEach-Object { $_.FullName }
function Find-First7z {
    param([string]$Pattern)
    foreach ($f in $all7z) {
        $leaf = [System.IO.Path]::GetFileName($f)
        if ($leaf -like $Pattern) { return $f }
    }
    return $null
}
$devProxy7z  = Find-First7z -Pattern "DevProxy*.7z"
$ifsf7z      = Find-First7z -Pattern "IFSF*.7z"
$xmlConfig7z = Find-First7z -Pattern "XMLConfigDLL*.7z"

if (-not $devProxy7z -or -not $ifsf7z -or -not $xmlConfig7z) {
    Write-Error "Artefacts .7z introuvables dans $ArtifactsDir. Attendus: DevProxy*.7z, IFSF*.7z, XMLConfigDLL*.7z"
    Write-Host "Fichiers .7z trouves: $(($all7z | ForEach-Object { [System.IO.Path]::GetFileName($_) }) -join ', ')" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== IFSF - Preparation depuis Copy Artifacts ===" -ForegroundColor Cyan
Write-Host "  Dossier artefacts: $ArtifactsDir" -ForegroundColor White
Write-Host "  Type terminal: $termType" -ForegroundColor White
Write-Host "  Dossier sortie: $outDir" -ForegroundColor White
Write-Host ""

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "IFSF_Copy_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    $extractDirs = @{}
    $toExtract = @(
        @{ Key = "DevProxy";     Path = $devProxy7z }
        @{ Key = "IFSF";         Path = $ifsf7z }
        @{ Key = "XMLConfigDLL"; Path = $xmlConfig7z }
    )
    foreach ($d in $toExtract) {
        $extDir = Join-Path $tempDir $d.Key
        New-Item -ItemType Directory -Path $extDir -Force | Out-Null
        Write-Host "Extraction $($d.Key): $([System.IO.Path]::GetFileName($d.Path)) ..." -ForegroundColor Yellow
        & $7z x $d.Path "-o$extDir" -y | Out-Null
        $extractDirs[$d.Key] = $extDir
    }

    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    $pkg = $script:IFSF_PACKAGE_FILES[$termType]
    $importExt = $script:IFSF_IMPORT_EXT[$termType]

    $packageNames = [System.Collections.ArrayList]@()
    foreach ($key in @("DevProxy", "IFSF", "XMLConfigDLL")) {
        $relPath = $pkg[$key]
        $srcDir = $extractDirs[$key]
        $src = Join-Path $srcDir $relPath
        if (-not (Test-Path $src)) {
            Write-Error "Fichier package introuvable: $src"
            exit 1
        }
        $leaf = Split-Path -Leaf $src
        $dest = Join-Path $outDir $leaf
        Copy-Item -Path $src -Destination $dest -Force
        [void]$packageNames.Add($leaf)
        Write-Host "  Package: $dest" -ForegroundColor Green
    }

    $hostDir = Get-ChildItem -Path $extractDirs["XMLConfigDLL"] -Recurse -Directory -Filter "HOST" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $hostDir) { $hostDir = Join-Path $extractDirs["XMLConfigDLL"] "HOST" }
    if (-not (Test-Path $hostDir)) {
        Write-Error "Dossier HOST introuvable dans XMLConfigDLL: $($extractDirs['XMLConfigDLL'])"
        exit 1
    }
    foreach ($base in $script:IFSF_IMPORT_BASENAMES) {
        $fileName = $base + $importExt
        $src = Join-Path $hostDir $fileName
        if (-not (Test-Path $src)) {
            Write-Warning "Fichier import introuvable: $src"
            continue
        }
        $dest = Join-Path $outDir $fileName
        Copy-Item -Path $src -Destination $dest -Force
        Write-Host "  Import: $dest" -ForegroundColor Green
    }

    $importNames = @($script:IFSF_IMPORT_BASENAMES | ForEach-Object { $_ + $importExt })
    Set-Content -Path (Join-Path $outDir "package.txt") -Value $packageNames -Encoding UTF8
    Set-Content -Path (Join-Path $outDir "import.txt")  -Value $importNames -Encoding UTF8
    Set-Content -Path (Join-Path $outDir "ifsf_output_dir.txt") -Value $outDir -Encoding UTF8

    Write-Host ""
    Write-Host "=== Fichiers pret dans: $outDir ===" -ForegroundColor Green
    Write-Output $outDir
} finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
