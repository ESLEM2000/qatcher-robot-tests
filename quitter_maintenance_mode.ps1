# Script pour quitter le mode maintenance d'un terminal QAtcher.
# Par défaut : Move3500_54227826. Le terminal redémarre et revient à l'écran normal.

$defaultTerminal = "Move3500_54227826"

Write-Host "=== Quitter le mode maintenance (terminal QAtcher) ===" -ForegroundColor Cyan
Write-Host ""

if ($args.Count -eq 0) {
    Write-Host "Terminal ID (Entrée = $defaultTerminal): " -NoNewline -ForegroundColor Yellow
    $inputId = Read-Host
    $terminalID = if ([string]::IsNullOrWhiteSpace($inputId)) { $defaultTerminal } else { $inputId }
} else {
    $terminalID = $args[0]
}

if ([string]::IsNullOrWhiteSpace($terminalID)) {
    Write-Host "Erreur: QAtcherTerminalID est requis" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Terminal ID : $terminalID" -ForegroundColor White
Write-Host "Hôte QAtcher: localhost" -ForegroundColor White
Write-Host "Port QAtcher: 8080" -ForegroundColor White
Write-Host ""
Write-Host "Le terminal va redémarrer et quitter le mode maintenance." -ForegroundColor Yellow
Write-Host "Lancement du test..." -ForegroundColor Green
Write-Host ""

$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $testDir

robot `
    --variable "QAtcherTerminalID:$terminalID" `
    --variable "QAtcherHost:localhost" `
    --variable "QAtcherPort:8080" `
    --test "Quitter le mode maintenance" `
    Set_Maintenance_Mode.robot

$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "=== Terminal sorti du mode maintenance avec succès ===" -ForegroundColor Green
} else {
    Write-Host "=== Échec (code: $exitCode). Vérifiez les logs. ===" -ForegroundColor Red
}
exit $exitCode
