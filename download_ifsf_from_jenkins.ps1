<#
.SYNOPSIS
    Télécharge le dernier build Jenkins réussi (DevProxy, IFSF, XMLConfigDLL .7z),
    extrait, sélectionne les fichiers selon le type de terminal (TETRA/T2/SELF),
    et les copie dans un répertoire de sortie (prêt pour APPL_IFSF.MXX / Local Upgrade).

.PARAMETER QAtcherTerminalID
    ID du terminal (ex: Move3500_54227826). Utilisé pour déduire IFSF_TERMINAL_TYPE si non défini.

.PARAMETER TerminalType
    Force le type: TETRA | T2 | SELF. Sinon déduit de QAtcherTerminalID ou IFSF_TERMINAL_TYPE.

.PARAMETER OutputDir
    Dossier de sortie (fichiers plats). Par défaut: IFSF_BUILD_DIR ou .\IFSF_Build

.NOTES
    Si Jenkins exige une connexion (S'identifier), définir JENKINS_USER et JENKINS_PASSWORD (ou JENKINS_API_TOKEN).
    En PowerShell, si le mot de passe contient $, utiliser des guillemets simples: $env:JENKINS_PASSWORD = 'ITAGuetUser2025$'
    En cas de 401, préférer un token API : Jenkins -> Utilisateur -> Configure -> Add new Token, puis JENKINS_API_TOKEN.

.EXAMPLE
    $env:IFSF_JENKINS_URL = "https://jenkins.company.com/job/IFSF/"
    .\download_ifsf_from_jenkins.ps1 -QAtcherTerminalID Move3500_54227826
#>
param(
    [string]$QAtcherTerminalID = $env:QAtcherTerminalID,
    [ValidateSet("TETRA", "T2", "SELF")]
    [string]$TerminalType = "",
    [string]$OutputDir = "",
    [string]$JenkinsUser = $env:JENKINS_USER,
    [string]$JenkinsPassword = $env:JENKINS_PASSWORD,
    [string]$JenkinsApiToken = $env:JENKINS_API_TOKEN
)

. "$PSScriptRoot\ifsf_config.ps1"

if (-not $script:IFSF_JENKINS_URL) {
    Write-Error "IFSF_JENKINS_URL doit être défini (variable d'environnement ou dans ifsf_config.ps1)."
    exit 1
}

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

# 7z: chercher 7z.exe
$7z = $null
foreach ($p in @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe")) {
    if ($p -and (Test-Path $p)) { $7z = $p; break }
}
if (-not $7z) {
    $7z = (Get-Command 7z -ErrorAction SilentlyContinue).Source
}
if (-not $7z) {
    Write-Error "7-Zip (7z.exe) est requis pour extraire les .7z. Installez 7-Zip ou ajoutez-le au PATH."
    exit 1
}

# URL du job uniquement (sans /build, /buildWithParameters, /lastSuccessfulBuild, etc.)
$jenkinsBase = $script:IFSF_JENKINS_URL.TrimEnd('/')
foreach ($suffix in @('/build', '/buildWithParameters', '/lastSuccessfulBuild', '/lastBuild', '/lastStableBuild')) {
    if ($jenkinsBase.EndsWith($suffix, [StringComparison]::OrdinalIgnoreCase)) {
        $jenkinsBase = $jenkinsBase.Substring(0, $jenkinsBase.Length - $suffix.Length).TrimEnd('/')
    }
}
$lastBuildUrl = "$jenkinsBase/lastSuccessfulBuild"
$apiUrl = "$lastBuildUrl/api/json?tree=artifacts[fileName,relativePath]"

# Timeout et retries (optionnel: IFSF_JENKINS_TIMEOUT_SEC, IFSF_JENKINS_MAX_RETRIES)
if ($env:IFSF_JENKINS_TIMEOUT_SEC -match '^\d+$') { $script:JenkinsTimeoutSec = [int]$env:IFSF_JENKINS_TIMEOUT_SEC } else { $script:JenkinsTimeoutSec = 120 }
if ($env:IFSF_JENKINS_MAX_RETRIES -match '^\d+$') { $script:JenkinsMaxRetries = [int]$env:IFSF_JENKINS_MAX_RETRIES } else { $script:JenkinsMaxRetries = 3 }

# En-tête Basic Auth : token API prioritaire (souvent requis pour l'API), sinon mot de passe
$headers = @{}
$secret = $null
if (-not [string]::IsNullOrWhiteSpace($JenkinsApiToken)) { $secret = $JenkinsApiToken }
elseif (-not [string]::IsNullOrWhiteSpace($JenkinsPassword)) { $secret = $JenkinsPassword }
if (-not [string]::IsNullOrWhiteSpace($JenkinsUser) -and -not [string]::IsNullOrWhiteSpace($secret)) {
    $pair = "${JenkinsUser}:${secret}"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
    $headers["Authorization"] = "Basic $([Convert]::ToBase64String($bytes))"
}

Write-Host "=== IFSF - Téléchargement depuis Jenkins ===" -ForegroundColor Cyan
Write-Host "  Jenkins: $jenkinsBase" -ForegroundColor White
Write-Host "  Type terminal: $termType" -ForegroundColor White
Write-Host "  Dossier sortie: $outDir" -ForegroundColor White
if ($headers.Authorization) {
    $authType = if ($JenkinsApiToken) { "JENKINS_USER + API Token" } else { "JENKINS_USER" }
    Write-Host "  Auth: Basic ($authType)" -ForegroundColor Gray
# Timeout et retry (connexion au meme Jenkins depuis un build peut etre lente)
$script:JenkinsTimeoutSec = 120
$script:JenkinsMaxRetries = 3

} else { Write-Host "  Auth: aucune (Jenkins public ou 401 possible)" -ForegroundColor Yellow }
Write-Host ""

# Récupérer la liste des artefacts du dernier build réussi (avec retry)
$json = $null
$lastErr = $null
for ($attempt = 1; $attempt -le $script:JenkinsMaxRetries; $attempt++) {
    try {
        $params = @{ Uri = $apiUrl; Method = 'Get'; UseBasicParsing = $true; TimeoutSec = $script:JenkinsTimeoutSec }
        if ($headers.Count -gt 0) { $params['Headers'] = $headers }
        $json = Invoke-RestMethod @params
        break
    } catch {
        $lastErr = $_
        if ($attempt -lt $script:JenkinsMaxRetries) {
            Write-Host "  Tentative $attempt/$($script:JenkinsMaxRetries) echouee, nouvel essai dans 5 s..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
}
if (-not $json) {
    Write-Error "Impossible de recuperer les artefacts Jenkins apres $($script:JenkinsMaxRetries) tentative(s): $lastErr"
    if ($lastErr.Exception.Response.StatusCode.value__ -eq 401) {
        Write-Host "  Astuce: definissez JENKINS_USER et JENKINS_PASSWORD (ou JENKINS_API_TOKEN)." -ForegroundColor Yellow
        Write-Host "  Token API : Jenkins -> Utilisateur -> Configure -> Add new Token" -ForegroundColor Gray
    }
    Write-Host "  Si le job tourne sur le meme Jenkins (127.0.0.1), la connexion peut etre interrompue : augmentez le nombre de builds paralleles ou reessayez." -ForegroundColor Gray
    exit 1
}

$artifacts = @($json.artifacts)
if ($artifacts.Count -eq 0) {
    Write-Error "Aucun artefact dans le dernier build réussi."
    exit 1
}

function Find-Artifact {
    param([string]$Pattern)
    foreach ($a in $artifacts) {
        if ($a.fileName -like $Pattern) { return $a }
    }
    return $null
}

$devProxyArt    = Find-Artifact -Pattern $script:IFSF_ARTIFACT_DEVPROXY
$ifsfArt        = Find-Artifact -Pattern $script:IFSF_ARTIFACT_IFSF
$xmlConfigArt   = Find-Artifact -Pattern $script:IFSF_ARTIFACT_XMLCONFIGDLL

if (-not $devProxyArt -or -not $ifsfArt -or -not $xmlConfigArt) {
    Write-Error "Artefacts .7z introuvables. Attendus: DevProxy*.7z, IFSF*.7z, XMLConfigDLL*.7z (ou variables IFSF_ARTIFACT_*)"
    Write-Host "Artefacts disponibles: $(($artifacts | ForEach-Object { $_.fileName }) -join ', ')" -ForegroundColor Yellow
    exit 1
}

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "IFSF_Download_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    $extractDirs = @{}
    $toDownload = @(
        @{ Name = "DevProxy";     Art = $devProxyArt;   Key = "DevProxy" }
        @{ Name = "IFSF";         Art = $ifsfArt;       Key = "IFSF" }
        @{ Name = "XMLConfigDLL";  Art = $xmlConfigArt;  Key = "XMLConfigDLL" }
    )

    foreach ($d in $toDownload) {
        $rel = $d.Art.relativePath
        $url = "$lastBuildUrl/artifact/$rel"
        $local7z = Join-Path $tempDir $d.Art.fileName
        Write-Host "Telechargement $($d.Name): $($d.Art.fileName) ..." -ForegroundColor Yellow
        $downloaded = $false
        for ($attempt = 1; $attempt -le $script:JenkinsMaxRetries; $attempt++) {
            try {
                $reqParams = @{ Uri = $url; OutFile = $local7z; UseBasicParsing = $true; TimeoutSec = $script:JenkinsTimeoutSec }
                if ($headers.Count -gt 0) { $reqParams['Headers'] = $headers }
                Invoke-WebRequest @reqParams
                $downloaded = $true
                break
            } catch {
                if ($attempt -lt $script:JenkinsMaxRetries) {
                    Write-Host "  Tentative $attempt echouee, nouvel essai dans 5 s..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 5
                } else {
                    throw
                }
            }
        }
        if (-not $downloaded) { throw "Telechargement echoue: $($d.Art.fileName)" }
        $extDir = Join-Path $tempDir $d.Key
        New-Item -ItemType Directory -Path $extDir -Force | Out-Null
        & $7z x $local7z "-o$extDir" -y | Out-Null
        $extractDirs[$d.Key] = $extDir
    }

    # Dossier de sortie (plat)
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null

    $pkg = $script:IFSF_PACKAGE_FILES[$termType]
    $importExt = $script:IFSF_IMPORT_EXT[$termType]

    # Copier les 3 fichiers package (DevProxy, IFSF, XMLConfigDLL)
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

    # Copier les 6 fichiers HOST (import)
    $hostDir = Get-ChildItem -Path $extractDirs["XMLConfigDLL"] -Recurse -Directory -Filter "HOST" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $hostDir) {
        $hostDir = Join-Path $extractDirs["XMLConfigDLL"] "HOST"
    }
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

    # Listes pour Robot (package = vers /package, import = vers /import)
    $importNames = @($script:IFSF_IMPORT_BASENAMES | ForEach-Object { $_ + $importExt })
    Set-Content -Path (Join-Path $outDir "package.txt") -Value $packageNames -Encoding UTF8
    Set-Content -Path (Join-Path $outDir "import.txt")  -Value $importNames -Encoding UTF8
    Set-Content -Path (Join-Path $outDir "ifsf_output_dir.txt") -Value $outDir -Encoding UTF8

    Write-Host ""
    Write-Host "=== Fichiers prêts dans: $outDir ===" -ForegroundColor Green
    Write-Host "  Envoyez les fichiers Package vers /package et les HOST (.V*) vers /import (Local Upgrade)." -ForegroundColor Gray
    Write-Output $outDir
} finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
