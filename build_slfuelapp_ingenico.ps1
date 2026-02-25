# Build SLFuelApp comme sous Jenkins (IngeDev + Ant)
# IngeDev_8.22.0.6 doit être installé. Le script cherche à plusieurs emplacements.

$ErrorActionPreference = "Stop"

# Emplacements possibles (ordre de recherche). INGEDEV_ROOT prioritaire, puis chemin Bureau si complet.
$IngeDevCandidates = @(
    $env:INGEDEV_ROOT,
    "C:\Users\eslem.hajamor\Desktop\haj amor eslem\Ingedev_8.22.0.6",
    "C:\Program Files\Ingenico\IngeDev_8.22.0.6",
    "C:\Ingenico\IngeDev_8.22.0.6"
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

$Workspace = "C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA"
$BuildXml  = "C:\ProgramData\Jenkins\.jenkins\workspace\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml"

# Préférer l'emplacement qui a antCmdLine.bat ET lltc (installation complète).
$IngeDevRoot = $null
$fallbackRoot = $null
foreach ($candidate in $IngeDevCandidates) {
    $antBat = Join-Path $candidate "antCmdLine.bat"
    if (-not (Test-Path -LiteralPath $antBat)) { continue }
    $hasLltc = (Test-Path -LiteralPath (Join-Path $candidate "lltc.exe")) -or (Test-Path -LiteralPath (Join-Path $candidate "lltc.bat"))
    if ($hasLltc) {
        $IngeDevRoot = $candidate
        break
    }
    if ($null -eq $fallbackRoot) { $fallbackRoot = $candidate }
}
if ($null -eq $IngeDevRoot) { $IngeDevRoot = $fallbackRoot }

if (-not $IngeDevRoot) {
    Write-Host "IngeDev introuvable. Emplacements vérifiés :" -ForegroundColor Red
    foreach ($c in $IngeDevCandidates) { Write-Host "  - $c" }
    Write-Host ""
    Write-Host "Exécutez .\setup_ingedev.ps1 pour créer les dossiers et afficher les instructions." -ForegroundColor Yellow
    Write-Host "Voir INSTALL_INGEDEV.md pour obtenir et installer IngeDev 8.22.0.6." -ForegroundColor Yellow
    exit 1
}

$antBat = Join-Path $IngeDevRoot "antCmdLine.bat"
$lltcExe = Join-Path $IngeDevRoot "lltc.exe"
$lltcBat = Join-Path $IngeDevRoot "lltc.bat"
$hasLltc = (Test-Path -LiteralPath $lltcExe) -or (Test-Path -LiteralPath $lltcBat)

if (-not $hasLltc) {
    Write-Host "IngeDev trouvé : $IngeDevRoot" -ForegroundColor Green
    Write-Host ""
    Write-Host "Erreur : le composant 'lltc' est absent (antCmdLine.bat en a besoin)." -ForegroundColor Red
    Write-Host "Vérifiez que l'un des fichiers suivants existe :" -ForegroundColor Red
    Write-Host "  - $lltcExe" -ForegroundColor Gray
    Write-Host "  - $lltcBat" -ForegroundColor Gray
    Write-Host ""
    Write-Host "L'installation IngeDev est incomplète. Obtenez le package IngeDev COMPLET" -ForegroundColor Yellow
    Write-Host "(avec antCmdLine.bat et tous les composants dont lltc) auprès de votre IT / Ingenico," -ForegroundColor Yellow
    Write-Host "ou copiez tout le dossier IngeDev_8.22.0.6 depuis une machine où le build fonctionne." -ForegroundColor Yellow
    Write-Host "Voir INSTALL_INGEDEV.md (section 'Installation complète et composant lltc')." -ForegroundColor Yellow
    exit 1
}

Write-Host "IngeDev trouvé : $IngeDevRoot" -ForegroundColor Green

Set-Location -LiteralPath $IngeDevRoot
& cmd /c "`"$antBat`" `"$Workspace`" `"$BuildXml`""
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) { exit $exitCode }
