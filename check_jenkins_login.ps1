<#
.SYNOPSIS
    Vérifie l'accès à la page "S'identifier" (login) Jenkins avec un utilisateur/mot de passe ou token API.

.DESCRIPTION
    Utilise l'authentification Basic pour appeler l'API Jenkins.
    Ne jamais committer le mot de passe : utiliser -Password / -ApiToken ou les variables d'environnement.
    Si vous avez une erreur 401 avec le mot de passe correct, Jenkins exige souvent un token API :
    Jenkins → clic sur l'utilisateur (en haut à droite) → Configure → "Add new Token".

.PARAMETER JenkinsUrl
    URL de base Jenkins (ex: http://localhost:8081 ou https://votre-jenkins.company.com).
    Définir JENKINS_URL si votre Jenkins n'est pas sur localhost:8081.

.PARAMETER Username
    Utilisateur Jenkins.

.PARAMETER Password
    Mot de passe du compte. Si 401, utiliser plutôt un token API (-ApiToken ou JENKINS_API_TOKEN).

.PARAMETER ApiToken
    Token API Jenkins (préféré pour l'API). Jenkins → Utilisateur → Configure → Add new Token.

.PARAMETER SkipCertificateCheck
    Ignorer les erreurs de certificat SSL (Jenkins HTTPS avec certificat auto-signé).
#>
param(
    [string]$JenkinsUrl = $env:JENKINS_URL,
    [string]$Username = $env:JENKINS_USER,
    [string]$Password = $env:JENKINS_PASSWORD,
    [string]$ApiToken = $env:JENKINS_API_TOKEN,
    [switch]$SkipCertificateCheck
)

if ([string]::IsNullOrWhiteSpace($JenkinsUrl)) {
    $JenkinsUrl = "http://localhost:8081"
}
$JenkinsUrl = $JenkinsUrl.TrimEnd('/')

if ([string]::IsNullOrWhiteSpace($Username)) {
    $Username = Read-Host "Utilisateur Jenkins"
}

# Token API prioritaire pour l'accès API Jenkins (évite 401 avec mot de passe)
if (-not [string]::IsNullOrWhiteSpace($ApiToken)) {
    $secret = $ApiToken
    $authType = "API Token"
} elseif (-not [string]::IsNullOrWhiteSpace($Password)) {
    $secret = $Password
    $authType = "Mot de passe"
} else {
    $sec = Read-Host "Mot de passe ou token API Jenkins" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    $secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    $authType = "Saisi"
}

if ([string]::IsNullOrWhiteSpace($secret)) {
    Write-Host "Erreur: mot de passe ou token API requis ( -Password, -ApiToken ou variables d'environnement )." -ForegroundColor Red
    exit 1
}

# Basic Auth: Jenkins attend utilisateur:mot de passe OU utilisateur:token_api
$pair = "${Username}:${secret}"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
$base64 = [Convert]::ToBase64String($bytes)
$headers = @{
    "Authorization" = "Basic $base64"
}

# Certificat SSL (auto-signé)
if ($SkipCertificateCheck) {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $script:PSDefaultParameterValues['Invoke-RestMethod:SkipCertificateCheck'] = $true
    } else {
        add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) { return true; }
}
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    }
}

Write-Host "Verification acces Jenkins: $JenkinsUrl" -ForegroundColor Cyan
Write-Host "Utilisateur: $Username (auth: $authType)" -ForegroundColor Gray
Write-Host ""

try {
    $params = @{
        Uri     = "$JenkinsUrl/api/json"
        Headers = $headers
        Method  = 'Get'
        ErrorAction = 'Stop'
    }
    if ($PSVersionTable.PSVersion.Major -ge 6 -and $SkipCertificateCheck) {
        $params['SkipCertificateCheck'] = $true
    }
    $r = Invoke-RestMethod @params
    Write-Host "OK - Acces Jenkins reussi." -ForegroundColor Green
    Write-Host "  Mode: $($r.mode)" -ForegroundColor Gray
    Write-Host "  Jenkins: $($r.jenkinsVersion)" -ForegroundColor Gray
    exit 0
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "ERREUR - Acces refuse ou indisponible." -ForegroundColor Red
    Write-Host "  HTTP: $statusCode" -ForegroundColor Yellow
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Gray
    if ($statusCode -eq 401) {
        Write-Host "" -ForegroundColor Gray
        Write-Host "  Solutions possibles:" -ForegroundColor Yellow
        Write-Host "  1. Verifier l'URL : si Jenkins n'est pas sur ce PC, definissez JENKINS_URL :" -ForegroundColor White
        Write-Host "     `$env:JENKINS_URL = 'https://votre-jenkins.company.com'" -ForegroundColor Gray
        Write-Host "  2. Utiliser un token API (souvent requis pour l'API) :" -ForegroundColor White
        Write-Host "     Jenkins -> votre nom (haut droite) -> Configure -> Add new Token" -ForegroundColor Gray
        Write-Host "     Puis : `$env:JENKINS_API_TOKEN = 'votre_token'" -ForegroundColor Gray
        Write-Host "  3. Mot de passe avec le caractere `$ : utiliser des guillemets simples :" -ForegroundColor White
        Write-Host "     `$env:JENKINS_PASSWORD = 'ITAGuetUser2025`$'" -ForegroundColor Gray
    }
    if ($_.Exception.Message -match "certificat|SSL|TLS") {
        Write-Host "  4. Jenkins HTTPS avec certificat non fiable : relancer avec -SkipCertificateCheck" -ForegroundColor White
    }
    exit 1
}
