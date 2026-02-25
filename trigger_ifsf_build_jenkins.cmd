@echo off
REM Déclenche le build IFSF dans Jenkins sans intervention (script PowerShell).
REM Définir avant d'exécuter (ou dans les variables d'environnement) :
REM   JENKINS_URL ou IFSF_BUILD_JENKINS_URL  = URL Jenkins (ex: http://10.3.2.184:49680)
REM   JENKINS_USER                           = utilisateur Jenkins
REM   JENKINS_PASSWORD ou JENKINS_API_TOKEN  = mot de passe ou token API
REM Exemple : set JENKINS_URL=http://10.3.2.184:49680 && set JENKINS_USER=admin && set JENKINS_API_TOKEN=xxx && trigger_ifsf_build_jenkins.cmd

set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%trigger_ifsf_build_jenkins.ps1" %*
exit /b %ERRORLEVEL%
