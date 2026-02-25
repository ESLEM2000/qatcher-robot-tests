<#
.SYNOPSIS
    Exécute localement les mêmes étapes que le pipeline Jenkinsfile_IFSF_Install :
    1) Téléchargement IFSF (si IFSF_JENKINS_URL défini), 2) Installation Local Upgrade (Robot).
    À lancer depuis ce dossier (resources/sample/tests).

.EXAMPLE
    $env:IFSF_JENKINS_URL = "https://votre-jenkins/job/IFSF-Build/"
    $env:JENKINS_USER = "eslem_hajamor"
    $env:JENKINS_PASSWORD = "votre_mot_de_passe_ou_token"
    .\run_ifsf_install_local.ps1 -QAtcherTerminalID Move3500_54227826
#>
param(
    [string]$QAtcherTerminalID = $env:QAtcherTerminalID,
    [ValidateSet("", "TETRA", "T2", "SELF")]
    [string]$TerminalType = $env:IFSF_TERMINAL_TYPE,
    [string]$QAtcherHost = "localhost",
    [string]$QAtcherPort = "8080",
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"
$testsDir = $PSScriptRoot
Set-Location $testsDir

$buildDir = Join-Path $testsDir "IFSF_Build"

# Étape 1 : Téléchargement (sauf si SkipDownload ou IFSF_JENKINS_URL vide)
if (-not $SkipDownload -and $env:IFSF_JENKINS_URL) {
    Write-Host "=== Téléchargement IFSF depuis Jenkins ===" -ForegroundColor Cyan
    $args = @("-QAtcherTerminalID", $QAtcherTerminalID)
    if ($TerminalType) { $args += @("-TerminalType", $TerminalType) }
    & $testsDir\download_ifsf_from_jenkins.ps1 @args
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} elseif (-not $SkipDownload) {
    Write-Host "IFSF_JENKINS_URL non défini. Définissez-le (et JENKINS_USER/JENKINS_PASSWORD si besoin) puis relancez." -ForegroundColor Yellow
    Write-Host "Exemple: `$env:IFSF_JENKINS_URL = 'https://jenkins.../job/IFSF-Build/'" -ForegroundColor Gray
    exit 1
}

if (-not (Test-Path (Join-Path $buildDir "package.txt"))) {
    Write-Error "IFSF_Build/package.txt introuvable. Lancez d'abord le téléchargement (IFSF_JENKINS_URL défini) ou préparez le dossier."
    exit 1
}

# Étape 2 : Installation Local Upgrade (Robot)
Write-Host "=== Installation IFSF (Local Upgrade) ===" -ForegroundColor Cyan
robot --variable "QAtcherHost:$QAtcherHost" `
      --variable "QAtcherPort:$QAtcherPort" `
      --variable "QAtcherTerminalID:$QAtcherTerminalID" `
      --variable "IFSF_BUILD_DIR:$buildDir" `
      --test "Install IFSF From Jenkins" `
      --outputdir output_ifsf `
      Install_IFSF_From_Jenkins.robot
exit $LASTEXITCODE
