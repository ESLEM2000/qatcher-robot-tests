<#
.SYNOPSIS
    Trouve le(s) job(s) Jenkins qui publient les 3 artefacts .7z (DevProxy, IFSF, XMLConfigDLL)
    pour renseigner IFSF_JENKINS_URL.

.PARAMETER JenkinsUrl
    URL de base Jenkins (ex: http://127.0.0.1:8081). Par defaut: JENKINS_URL ou http://127.0.0.1:8081

.PARAMETER JenkinsUser
    Utilisateur Jenkins (optionnel si Jenkins est public).

.PARAMETER JenkinsPassword
    Mot de passe ou token API.

.EXAMPLE
    .\find_ifsf_jenkins_job.ps1
    .\find_ifsf_jenkins_job.ps1 -JenkinsUrl http://127.0.0.1:8081 -JenkinsUser eslem_hajamor -JenkinsPassword "***"
#>
param(
    [string]$JenkinsUrl = $env:JENKINS_URL,
    [string]$JenkinsUser = $env:JENKINS_USER,
    [string]$JenkinsPassword = $env:JENKINS_PASSWORD,
    [string]$JenkinsApiToken = $env:JENKINS_API_TOKEN
)

if ([string]::IsNullOrWhiteSpace($JenkinsUrl)) {
    $JenkinsUrl = "http://127.0.0.1:8081"
}
$JenkinsUrl = $JenkinsUrl.TrimEnd('/')

$headers = @{}
$secret = $JenkinsApiToken
if ([string]::IsNullOrWhiteSpace($secret)) { $secret = $JenkinsPassword }
if (-not [string]::IsNullOrWhiteSpace($JenkinsUser) -and -not [string]::IsNullOrWhiteSpace($secret)) {
    $pair = "${JenkinsUser}:${secret}"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
    $headers["Authorization"] = "Basic $([Convert]::ToBase64String($bytes))"
}

$ErrorActionPreference = "Stop"
$scriptRoot = $PSScriptRoot

Write-Host "=== Recherche des jobs Jenkins qui publient DevProxy/IFSF/XMLConfigDLL .7z ===" -ForegroundColor Cyan
Write-Host "  Jenkins: $JenkinsUrl" -ForegroundColor White
Write-Host ""

function Get-JenkinsJson {
    param([string]$Uri)
    $params = @{ Uri = $Uri; Method = 'Get'; UseBasicParsing = $true }
    if ($headers.Count -gt 0) { $params['Headers'] = $headers }
    try {
        return Invoke-RestMethod @params
    } catch {
        return $null
    }
}

# Liste des jobs (niveau racine)
$root = Get-JenkinsJson -Uri "$JenkinsUrl/api/json?tree=jobs[name,url]"
if (-not $root -or -not $root.jobs) {
    Write-Host "Impossible de recuperer la liste des jobs. Verifier l'URL et les credentials." -ForegroundColor Red
    exit 1
}

$jobsToCheck = @()
foreach ($j in $root.jobs) {
    $jobsToCheck += [PSCustomObject]@{ Name = $j.name; Url = $j.url }
}

# Si des jobs sont des dossiers (type "folder"), on peut les explorer
$allJobs = [System.Collections.ArrayList]@()
foreach ($j in $jobsToCheck) {
    $jobJson = Get-JenkinsJson -Uri "$($j.Url)api/json?tree=name,url,jobs"
    if (-not $jobJson) { continue }
    if ($jobJson.jobs -and $jobJson.jobs.Count -gt 0) {
        foreach ($sub in $jobJson.jobs) {
            $subUrl = $sub.url
            if (-not $subUrl) { $subUrl = "$($j.Url)job/$($sub.name)/" }
            [void]$allJobs.Add([PSCustomObject]@{ Name = $sub.name; Url = $subUrl })
        }
    } else {
        [void]$allJobs.Add([PSCustomObject]@{ Name = $jobJson.name; Url = $jobJson.url })
    }
}
if ($allJobs.Count -eq 0) {
    $allJobs = [System.Collections.ArrayList]@($jobsToCheck)
}

$patternDevProxy    = "DevProxy"
$patternIFSF        = "IFSF"
$patternXMLConfig   = "XMLConfigDLL"
$ext7z              = ".7z"

$found = [System.Collections.ArrayList]@()
foreach ($job in $allJobs) {
    $buildUrl = "$($job.Url)lastSuccessfulBuild/api/json?tree=artifacts[fileName]"
    $build = Get-JenkinsJson -Uri $buildUrl
    if (-not $build -or -not $build.artifacts) { continue }
    $names = @($build.artifacts | ForEach-Object { $_.fileName })
    $hasDevProxy  = $names | Where-Object { $_ -like "*DevProxy*" -and $_ -like "*.7z" } | Select-Object -First 1
    $hasIFSF      = $names | Where-Object { $_ -like "*IFSF*"   -and $_ -like "*.7z" -and $_ -notlike "*XMLConfig*" } | Select-Object -First 1
    $hasXMLConfig = $names | Where-Object { $_ -like "*XMLConfig*" -and $_ -like "*.7z" } | Select-Object -First 1
    if ($hasDevProxy -and $hasIFSF -and $hasXMLConfig) {
        [void]$found.Add([PSCustomObject]@{
            JobName = $job.Name
            JobUrl  = $job.Url.TrimEnd('/')
            DevProxy = $hasDevProxy
            IFSF     = $hasIFSF
            XMLConfig = $hasXMLConfig
        })
    }
}

if ($found.Count -eq 0) {
    Write-Host "Aucun job ne publie les 3 artefacts (DevProxy, IFSF, XMLConfigDLL .7z)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Jobs verifies (avec lastSuccessfulBuild) :" -ForegroundColor Gray
    foreach ($job in $allJobs) {
        $build = Get-JenkinsJson -Uri "$($job.Url)lastSuccessfulBuild/api/json?tree=artifacts[fileName]"
        if ($build -and $build.artifacts) {
            $count7z = @($build.artifacts | Where-Object { $_.fileName -like "*.7z" }).Count
            Write-Host "  - $($job.Name) : $count7z fichier(s) .7z" -ForegroundColor Gray
        }
    }
    Write-Host ""
    Write-Host "Creer un job qui publie les 3 archives .7z, ou indiquer l''URL du bon job si sur un autre Jenkins." -ForegroundColor Gray
    exit 0
}

Write-Host "Job(s) trouvé(s) qui publient DevProxy + IFSF + XMLConfigDLL .7z :" -ForegroundColor Green
Write-Host ""
foreach ($f in $found) {
    Write-Host "  Nom : $($f.JobName)" -ForegroundColor White
    Write-Host "  IFSF_JENKINS_URL a utiliser : $($f.JobUrl)" -ForegroundColor Cyan
    Write-Host "  Artefacts : $($f.DevProxy), $($f.IFSF), $($f.XMLConfig)" -ForegroundColor Gray
    Write-Host ""
}
Write-Host "Dans le job IFSF-install, Build with Parameters > IFSF_JENKINS_URL : coller l''URL ci-dessus (ex: $($found[0].JobUrl))." -ForegroundColor Green
