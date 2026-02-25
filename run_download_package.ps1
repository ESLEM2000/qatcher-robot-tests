# Script pour télécharger le package complet CMP_QATCHER_EMBEDDED.Mxx
# Demande le QAtcherTerminalID et exécute le test

Write-Host "=== Téléchargement du package complet CMP_QATCHER_EMBEDDED.Mxx ===" -ForegroundColor Cyan
Write-Host ""

# Demander le Terminal ID si non fourni en argument
if ($args.Count -eq 0) {
    $terminalID = Read-Host "Entrez votre QAtcherTerminalID (ex: Move3500_54227826)"
} else {
    $terminalID = $args[0]
}

if ([string]::IsNullOrWhiteSpace($terminalID)) {
    Write-Host "Erreur: QAtcherTerminalID est requis" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Terminal ID: $terminalID" -ForegroundColor Yellow
Write-Host "Hôte QAtcher: localhost" -ForegroundColor Yellow
Write-Host "Port QAtcher: 8080" -ForegroundColor Yellow
Write-Host ""
Write-Host "Démarrage du test..." -ForegroundColor Green
Write-Host ""

# Exécuter le test Robot Framework
$testFile = "Qatcher sample full package.robot"
robot `
    --variable "QAtcherTerminalID:$terminalID" `
    --variable "QAtcherHost:localhost" `
    --variable "QAtcherPort:8080" `
    --test "Download Full Package Only" `
    $testFile

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Test terminé avec succès ===" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "=== Test terminé avec des erreurs (code: $LASTEXITCODE) ===" -ForegroundColor Red
    Write-Host "Consultez les logs pour plus de détails." -ForegroundColor Yellow
}
