# Script pour télécharger le package complet CMP_QATCHER_EMBEDDED.Mxx
# Utilise le test Robot Framework existant "Download Full Package Only"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Téléchargement du package complet" -ForegroundColor Cyan
Write-Host "  CMP_QATCHER_EMBEDDED.Mxx" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Demander le Terminal ID si non fourni en argument
if ($args.Count -eq 0) {
    Write-Host "Veuillez entrer votre QAtcherTerminalID" -ForegroundColor Yellow
    Write-Host "Exemple: Move3500_54227826" -ForegroundColor Gray
    Write-Host ""
    $terminalID = Read-Host "QAtcherTerminalID"
} else {
    $terminalID = $args[0]
}

if ([string]::IsNullOrWhiteSpace($terminalID)) {
    Write-Host ""
    Write-Host "ERREUR: QAtcherTerminalID est requis pour exécuter le test" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Green
Write-Host "  Terminal ID: $terminalID" -ForegroundColor White
Write-Host "  Hôte QAtcher: localhost" -ForegroundColor White
Write-Host "  Port QAtcher: 8080" -ForegroundColor White
Write-Host "  Catalogue: CMP_QATCHER_EMBEDDED.Mxx" -ForegroundColor White
Write-Host ""
Write-Host "Démarrage du test 'Download Full Package Only'..." -ForegroundColor Yellow
Write-Host ""

# Changer vers le répertoire du test
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $testDir

# Exécuter le test Robot Framework
robot `
    --variable "QAtcherTerminalID:$terminalID" `
    --variable "QAtcherHost:localhost" `
    --variable "QAtcherPort:8080" `
    --test "Download Full Package Only" `
    --name "Download Full Package" `
    "Qatcher sample full package.robot"

$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Test terminé avec succès!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Le package complet a été téléchargé et installé sur le terminal." -ForegroundColor Green
} else {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  Test terminé avec des erreurs" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Code de sortie: $exitCode" -ForegroundColor Yellow
    Write-Host "Consultez les fichiers log.html et report.html pour plus de détails." -ForegroundColor Yellow
}

exit $exitCode
