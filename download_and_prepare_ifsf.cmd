@echo off
REM Telecharge le dernier build IFSF (3 .7z), extrait, selectionne les fichiers (TETRA/T2/SELF), prepare IFSF_Build.
REM Modifier les variables ci-dessous selon votre environnement.

set "IFSF_JENKINS_URL=http://127.0.0.1:8081/job/IFSF-Build/"
set "JENKINS_USER=eslem_hajamor"
set "JENKINS_PASSWORD=VOTRE_MOT_DE_PASSE"
set "QAtcherTerminalID=Move3500_54227826"
REM Optionnel: set "IFSF_TERMINAL_TYPE=TETRA"

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\download_ifsf_from_jenkins.ps1" -QAtcherTerminalID "%QAtcherTerminalID%"
if errorlevel 1 (
    echo [ERREUR] Echec du telechargement / preparation IFSF.
    exit /b 1
)
if not exist ".\IFSF_Build\package.txt" (
    echo [ERREUR] IFSF_Build\package.txt absent.
    exit /b 1
)
echo [OK] IFSF_Build pret : package.txt et import.txt. Fichiers prets pour Local Upgrade.
exit /b 0
