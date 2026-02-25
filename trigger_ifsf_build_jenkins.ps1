<#
.SYNOPSIS
    Déclenche le build IFSF dans Jenkins sans intervention manuelle (API), et optionnellement attend la fin.

.DESCRIPTION
    Appelle l'API Jenkins buildWithParameters sur le job Build IFSF (ReleasePackage-ITA0148-IFSF-TETRA / IFSF-Build)
    avec les paramètres par défaut (USE_GIT=true, dépôt ita-emb-app-ifsf, branche main).
    Utilise JENKINS_USER + JENKINS_PASSWORD ou JENKINS_API_TOKEN pour l'authentification.

.PARAMETER JenkinsUrl
    URL de base Jenkins (ex: http://10.3.2.184:49680) ou URL du job (ex: .../job/ReleasePackage-ITA0148-IFSF-TETRA/).
    Variable d'environnement : IFSF_BUILD_JENKINS_URL ou JENKINS_URL.

.PARAMETER JobName
    Nom exact du job (sensible à la casse). Défaut : ReleasePackage-ITA0148-IFSF-TETRA.

.PARAMETER NoWait
    Ne pas attendre la fin du build : déclencher et quitter tout de suite.

.PARAMETER UseGit
    Utiliser le clone Git (true) ou sources locales (false). Défaut : true.

.PARAMETER GitRepoUrl
    URL du dépôt à construire. Défaut : git@github.com:worldlineMSITA/ita-emb-app-ifsf.git

.PARAMETER GitBranch
    Branche à construire. Défaut : main.

.PARAMETER GitCredentialsId
    ID de la credential Jenkins pour le clone (si dépôt privé).

.PARAMETER IngeDevRoot
    Chemin IngeDev (ex: C:\Ingenico\IngeDev_8.22.0.6). Optionnel.

.PARAMETER SkipCertificateCheck
    Ignorer les erreurs de certificat SSL (HTTPS auto-signé).

.EXAMPLE
    $env:JENKINS_USER = "admin"
    $env:JENKINS_API_TOKEN = "xxx"
    .\trigger_ifsf_build_jenkins.ps1 -JenkinsUrl "http://10.3.2.184:49680"

.EXAMPLE
    .\trigger_ifsf_build_jenkins.ps1 -NoWait
#>
param(
    [string]$JenkinsUrl = $env:IFSF_BUILD_JENKINS_URL,
    [string]$JobName = "ReleasePackage-ITA0148-IFSF-TETRA",
    [switch]$NoWait,
    [bool]$UseGit = $true,
    [string]$GitRepoUrl = "git@github.com:worldlineMSITA/ita-emb-app-ifsf.git",
    [string]$GitBranch = "main",
    [string]$GitCredentialsId = $env:IFSF_GIT_CREDENTIALS_ID,
    [string]$IngeDevRoot = "",
    [switch]$SkipCertificateCheck,
    [string]$JenkinsUser = $env:JENKINS_USER,
    [string]$JenkinsPassword = $env:JENKINS_PASSWORD,
    [string]$JenkinsApiToken = $env:JENKINS_API_TOKEN
)

# Normaliser l'URL : enlever /job/... à la fin pour avoir la base
$baseUrl = $JenkinsUrl.TrimEnd('/')
if ($baseUrl -match '/job/[^/]+$') {
    $baseUrl = $baseUrl -replace '/job/[^/]+$', ''
}
if ([string]::IsNullOrWhiteSpace($baseUrl)) {
    $baseUrl = "http://localhost:8080"
}

$jobUrl = "$baseUrl/job/$([System.Uri]::EscapeDataString($JobName))"
$buildWithParamsUrl = "$jobUrl/buildWithParameters"

# Auth (même logique que download_ifsf_from_jenkins.ps1)
$headers = @{}
$secret = $null
if (-not [string]::IsNullOrWhiteSpace($JenkinsApiToken)) { $secret = $JenkinsApiToken }
elseif (-not [string]::IsNullOrWhiteSpace($JenkinsPassword)) { $secret = $JenkinsPassword }
if (-not [string]::IsNullOrWhiteSpace($JenkinsUser) -and -not [string]::IsNullOrWhiteSpace($secret)) {
    $pair = "${JenkinsUser}:${secret}"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
    $headers["Authorization"] = "Basic $([Convert]::ToBase64String($bytes))"
}

if ($SkipCertificateCheck -and $PSVersionTable.PSVersion.Major -ge 6) {
    $script:PSDefaultParameterValues['Invoke-RestMethod:SkipCertificateCheck'] = $true
    $script:PSDefaultParameterValues['Invoke-WebRequest:SkipCertificateCheck'] = $true
}

function Add-QueryParam {
    param([System.Collections.Generic.List[string]]$list, [string]$name, [string]$value)
    if ([string]::IsNullOrWhiteSpace($value)) { return }
    $list.Add("$name=$([System.Uri]::EscapeDataString($value))")
}

$queryParts = [System.Collections.Generic.List[string]]::new()
Add-QueryParam -list $queryParts -name "USE_GIT" -value $(if ($UseGit) { "true" } else { "false" })
Add-QueryParam -list $queryParts -name "GIT_REPO_URL" -value $GitRepoUrl
Add-QueryParam -list $queryParts -name "GIT_BRANCH" -value $GitBranch
Add-QueryParam -list $queryParts -name "GIT_CREDENTIALS_ID" -value $GitCredentialsId
if (-not [string]::IsNullOrWhiteSpace($IngeDevRoot)) {
    Add-QueryParam -list $queryParts -name "INGEDEV_ROOT" -value $IngeDevRoot
}

$queryString = $queryParts -join '&'
# URL courte (sans query) pour éviter "URI non valide" sur certains systèmes ; paramètres envoyés en body
$buildTriggerUrl = $buildWithParamsUrl
$body = $queryString

Write-Host "=== Declenchement build IFSF (sans intervention) ===" -ForegroundColor Cyan
Write-Host "  Jenkins: $baseUrl" -ForegroundColor White
Write-Host "  Job: $JobName" -ForegroundColor White
Write-Host "  USE_GIT=$UseGit, GIT_BRANCH=$GitBranch" -ForegroundColor Gray
if ($NoWait) { Write-Host "  Mode: declencher puis quitter (NoWait)" -ForegroundColor Yellow }
else { Write-Host "  Mode: declencher et attendre la fin du build" -ForegroundColor White }
Write-Host ""

try {
    $reqParams = @{
        Uri             = $buildTriggerUrl
        Method          = 'Post'
        UseBasicParsing = $true
        TimeoutSec      = 60
        Headers         = $headers
        ContentType     = 'application/x-www-form-urlencoded'
        Body            = $body
    }
    if ($PSVersionTable.PSVersion.Major -ge 6 -and $SkipCertificateCheck) {
        $reqParams['SkipCertificateCheck'] = $true
    }
    $response = Invoke-WebRequest @reqParams
} catch {
    $statusCode = $null
    if ($_.Exception.Response) { $statusCode = $_.Exception.Response.StatusCode.value__ }
    $msg = $_.Exception.Message
    Write-Error "Impossible de declencher le build. HTTP $statusCode - $msg"
    if ($statusCode -eq 401) {
        Write-Host "  Definissez JENKINS_USER et JENKINS_PASSWORD (ou JENKINS_API_TOKEN)." -ForegroundColor Yellow
    }
    if ($statusCode -eq 404) {
        Write-Host "  Verifiez l'URL et le nom du job: $JobName" -ForegroundColor Yellow
    }
    exit 2
}

# 201 = créé, build mis en file
if ($response.StatusCode -notin 200, 201) {
    Write-Error "Reponse inattendue: $($response.StatusCode)"
    exit 2
}

$queueLocation = $response.Headers['Location']
if ([string]::IsNullOrWhiteSpace($queueLocation)) {
    Write-Host "Build declenche (pas de Location queue). Consultez Jenkins pour le statut." -ForegroundColor Green
    exit 0
}

# Extraire l'URL absolue de la queue (parfois relative)
if ($queueLocation -notmatch '^https?://') {
    $queueLocation = "$baseUrl$queueLocation"
}
$queueLocation = $queueLocation.TrimEnd('/')

Write-Host "Build en file: $queueLocation" -ForegroundColor Green

if ($NoWait) {
    Write-Host "Termine (NoWait). Suivi du build sur Jenkins." -ForegroundColor Cyan
    exit 0
}

# Attendre que le build soit pris en charge puis qu'il se termine
$queueApi = "$queueLocation/api/json"
$maxWaitMinutes = 30
$pollIntervalSec = 15
$deadline = (Get-Date).AddMinutes($maxWaitMinutes)
$buildNumber = $null
$buildUrl = $null

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 5
    try {
        $params = @{ Uri = $queueApi; Method = 'Get'; UseBasicParsing = $true; TimeoutSec = 30 }
        if ($headers.Count -gt 0) { $params['Headers'] = $headers }
        if ($SkipCertificateCheck -and $PSVersionTable.PSVersion.Major -ge 6) { $params['SkipCertificateCheck'] = $true }
        $q = Invoke-RestMethod @params
    } catch {
        Write-Host "  Poll queue: $($_.Exception.Message)" -ForegroundColor Gray
        continue
    }
    if ($q.executable) {
        $buildNumber = $q.executable.number
        $buildUrl = $q.executable.url
        break
    }
    if ($q.cancelled) {
        Write-Error "Build annule dans la file."
        exit 3
    }
    Write-Host "  En attente en file..." -ForegroundColor Gray
}

if (-not $buildNumber) {
    Write-Error "Timeout: le build n'a pas demarre dans les $maxWaitMinutes min. Verifiez la file Jenkins."
    exit 4
}

# Attendre la fin du build
$buildApi = "$buildUrl/api/json?tree=result,building"
Write-Host "Build #$buildNumber en cours: $buildUrl" -ForegroundColor Cyan

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds $pollIntervalSec
    try {
        $params = @{ Uri = $buildApi; Method = 'Get'; UseBasicParsing = $true; TimeoutSec = 30 }
        if ($headers.Count -gt 0) { $params['Headers'] = $headers }
        if ($SkipCertificateCheck -and $PSVersionTable.PSVersion.Major -ge 6) { $params['SkipCertificateCheck'] = $true }
        $b = Invoke-RestMethod @params
    } catch {
        Write-Host "  Poll build: $($_.Exception.Message)" -ForegroundColor Gray
        continue
    }
    if (-not $b.building -and $null -ne $b.result) {
        Write-Host ""
        if ($b.result -eq "SUCCESS") {
            Write-Host "Build #$buildNumber reussi. Artefacts .7z disponibles sur Jenkins." -ForegroundColor Green
            exit 0
        }
        Write-Error "Build #$buildNumber termine avec statut: $($b.result)"
        exit 1
    }
    Write-Host "  Build en cours..." -ForegroundColor Gray
}

Write-Error "Timeout: le build n'est pas termine dans les $maxWaitMinutes min."
exit 4
