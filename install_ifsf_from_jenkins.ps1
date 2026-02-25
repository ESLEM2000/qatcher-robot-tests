<#
.SYNOPSIS
    Télécharge le dernier build IFSF depuis Jenkins et installe sur le terminal via Local Upgrade
    (fichiers package -> /package, fichiers import -> /import).

.DESCRIPTION
    Utilise IFSF_JENKINS_URL (obligatoire si IFSF_BUILD_DIR non fourni).
    Type terminal: IFSF_TERMINAL_TYPE ou déduit de QAtcherTerminalID (TETRA si Move3500, SELF si SELF, T2 si T2).

.PARAMETER QAtcherTerminalID
    ID du terminal (ex: Move3500_54227826).

.PARAMETER IFSF_BUILD_DIR
    Dossier déjà préparé (package.txt, import.txt, fichiers). Si fourni, pas de téléchargement Jenkins.

.EXAMPLE
    $env:IFSF_JENKINS_URL = "https://jenkins.company.com/job/IFSF-Build/"
    .\install_ifsf_from_jenkins.ps1 -QAtcherTerminalID Move3500_54227826
#>
param(
    [string]$QAtcherTerminalID = $env:QAtcherTerminalID,
    [string]$IFSF_BUILD_DIR = $env:IFSF_BUILD_DIR
)

if ([string]::IsNullOrWhiteSpace($QAtcherTerminalID)) {
    $QAtcherTerminalID = Read-Host "QAtcherTerminalID (ex: Move3500_54227826)"
}
if ([string]::IsNullOrWhiteSpace($QAtcherTerminalID)) {
    Write-Error "QAtcherTerminalID requis."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($IFSF_BUILD_DIR)) {
    $env:QAtcherTerminalID = $QAtcherTerminalID
}

$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $testDir

$robotArgs = @(
    "--variable", "QAtcherTerminalID:$QAtcherTerminalID",
    "--variable", "QAtcherHost:localhost",
    "--variable", "QAtcherPort:8080",
    "--test", "Install IFSF From Jenkins",
    "Install_IFSF_From_Jenkins.robot"
)
if (-not [string]::IsNullOrWhiteSpace($IFSF_BUILD_DIR)) {
    $robotArgs += @("--variable", "IFSF_BUILD_DIR:$IFSF_BUILD_DIR")
}

Write-Host "=== Installation IFSF depuis Jenkins / Local Upgrade ===" -ForegroundColor Cyan
Write-Host "  Terminal: $QAtcherTerminalID" -ForegroundColor White
if ($IFSF_BUILD_DIR) { Write-Host "  IFSF_BUILD_DIR: $IFSF_BUILD_DIR" -ForegroundColor White }
else { Write-Host "  Téléchargement depuis Jenkins (IFSF_JENKINS_URL)" -ForegroundColor White }
Write-Host ""

& robot @robotArgs
exit $LASTEXITCODE
