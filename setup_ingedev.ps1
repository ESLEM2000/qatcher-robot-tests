# Préparer l'installation IngeDev 8.22.0.6
# Crée les dossiers cibles, diagnostique et affiche les instructions.

$ErrorActionPreference = "Continue"

$PathsToCreate = @(
    "C:\Program Files\Ingenico\IngeDev_8.22.0.6",
    "C:\Ingenico\IngeDev_8.22.0.6"
)

$PathsToSearch = @(
    "C:\Program Files\Ingenico\IngeDev_8.22.0.6",
    "C:\Program Files (x86)\Ingenico\IngeDev_8.22.0.6",
    "C:\Ingenico\IngeDev_8.22.0.6",
    "D:\Ingenico\IngeDev_8.22.0.6",
    "C:\IngeDev_8.22.0.6",
    "C:\Users\eslem.hajamor\Desktop\haj amor eslem\Ingedev_8.22.0.6"
)

Write-Host "=== Configuration IngeDev 8.22.0.6 ===" -ForegroundColor Cyan
Write-Host ""

# 1. Créer les dossiers cibles
Write-Host "1. Création des dossiers cibles..." -ForegroundColor Yellow
foreach ($dir in $PathsToCreate) {
    if (-not (Test-Path -LiteralPath $dir)) {
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "   Créé : $dir" -ForegroundColor Green
        } catch {
            Write-Host "   Échec : $dir (droits administrateur ?)" -ForegroundColor Red
            Write-Host "   $($_.Exception.Message)" -ForegroundColor Gray
        }
    } else {
        Write-Host "   Déjà présent : $dir" -ForegroundColor Gray
    }
}
Write-Host ""

# 2. Diagnostic : où est antCmdLine.bat ?
Write-Host "2. Recherche de antCmdLine.bat..." -ForegroundColor Yellow
$found = $null
foreach ($base in $PathsToSearch) {
    $bat = Join-Path $base "antCmdLine.bat"
    if (Test-Path -LiteralPath $bat) {
        $found = $base
        Write-Host "   Trouvé : $bat" -ForegroundColor Green
        break
    }
}
if (-not $found) {
    # Recherche dans les sous-dossiers des emplacements courants
    $parentDirs = @("C:\Program Files\Ingenico", "C:\Program Files (x86)\Ingenico", "C:\Ingenico", "D:\Ingenico")
    foreach ($parent in $parentDirs) {
        if (-not (Test-Path -LiteralPath $parent)) { continue }
        $bat = Get-ChildItem -Path $parent -Filter "antCmdLine.bat" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($bat) {
            $found = $bat.Directory.FullName
            Write-Host "   Trouvé : $($bat.FullName)" -ForegroundColor Green
            break
        }
    }
}
if (-not $found) {
    Write-Host "   Aucune installation IngeDev trouvée." -ForegroundColor Red
}
Write-Host ""

# 3. Instructions
Write-Host "3. Instructions" -ForegroundColor Yellow
if ($found) {
    Write-Host "   IngeDev est déjà présent ici : $found" -ForegroundColor Green
    Write-Host "   Pour forcer son utilisation, définir la variable d'environnement :" -ForegroundColor Gray
    Write-Host "   `$env:INGEDEV_ROOT = `"$found`"" -ForegroundColor White
    Write-Host "   Puis relancer : .\build_slfuelapp_ingenico.ps1" -ForegroundColor Gray
} else {
    Write-Host "   Copiez (ou installez) IngeDev 8.22.0.6 dans l'un de ces dossiers :" -ForegroundColor White
    Write-Host "     - C:\Program Files\Ingenico\IngeDev_8.22.0.6" -ForegroundColor Cyan
    Write-Host "     - C:\Ingenico\IngeDev_8.22.0.6" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Le dossier doit contenir antCmdLine.bat à la racine." -ForegroundColor Gray
    Write-Host "   Source possible : équipe IT, portail Ingenico, ou copie depuis une autre machine." -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Voir INSTALL_INGEDEV.md pour plus de détails." -ForegroundColor Gray
}
Write-Host ""
Write-Host "=== Fin ====" -ForegroundColor Cyan
