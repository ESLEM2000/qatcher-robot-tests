# Configuration IFSF - Upgrade logiciel IFSF sur le terminal
# Définir IFSF_JENKINS_URL (ex: https://jenkins.company.com/job/IFSF-Build/)
# Optionnel: IFSF_BUILD_DIR (dossier de sortie), IFSF_TERMINAL_TYPE (TETRA|T2|SELF)
# Optionnel: noms des artefacts Jenkins pour les 3 .7z (sinon recherche par motif)

$script:IFSF_JENKINS_URL = if ($env:IFSF_JENKINS_URL) { $env:IFSF_JENKINS_URL.TrimEnd('/') } else { $null }
$script:IFSF_BUILD_DIR   = if ($env:IFSF_BUILD_DIR)   { $env:IFSF_BUILD_DIR } else { Join-Path $PSScriptRoot "IFSF_Build" }
$script:IFSF_TERMINAL_TYPE = $env:IFSF_TERMINAL_TYPE  # TETRA | T2 | SELF

# Noms des artefacts .7z dans le build Jenkins (ou motifs pour lastSuccessfulBuild)
$script:IFSF_ARTIFACT_DEVPROXY     = if ($env:IFSF_ARTIFACT_DEVPROXY)     { $env:IFSF_ARTIFACT_DEVPROXY } else { "DevProxy*.7z" }
$script:IFSF_ARTIFACT_IFSF         = if ($env:IFSF_ARTIFACT_IFSF)         { $env:IFSF_ARTIFACT_IFSF } else { "IFSF*.7z" }
$script:IFSF_ARTIFACT_XMLCONFIGDLL  = if ($env:IFSF_ARTIFACT_XMLCONFIGDLL) { $env:IFSF_ARTIFACT_XMLCONFIGDLL } else { "XMLConfigDLL*.7z" }

# Mapping des fichiers par type de terminal (relatif à la racine de chaque archive extraite)
# Package = envoyés vers /package sur le terminal
# Import  = envoyés vers /import (fichiers HOST)
$script:IFSF_PACKAGE_FILES = @{
    TETRA = @{
        DevProxy     = "Bin/GNU_ARM_RELEASE_TETRA/8515360465_DEV_PROXY.P3A"
        IFSF         = "Bin/GNU_ARM_RELEASE_TETRA/8226760662_IFSF_0662.P3A"
        XMLConfigDLL = "Bin/GNU_ARM_RELEASE_TETRA/8226750662_XMLCFG_DLL.P3L"
    }
    T2 = @{
        DevProxy     = "Bin/GNU_ARM_RELEASE_T2/8515360465.AGN"
        IFSF         = "Bin/GNU_ARM_RELEASE_T2/8226760662.AGN"
        XMLConfigDLL = "Bin/GNU_ARM_RELEASE_T2/8226750662.LGN"
    }
    SELF = @{
        DevProxy     = "Bin/GNU_ARM_RELEASE_SELF/8515361465_DEV_PROXY.P3A"
        IFSF         = "Bin/GNU_ARM_RELEASE_SELF/8226761662_IFSF_1662.P3A"
        XMLConfigDLL = "Bin/GNU_ARM_RELEASE_SELF/8226751662_XMLCFG_DLL.P3L"
    }
}

# Import: 6 fichiers HOST (extension .V0662 pour TETRA/T2, .V1662 pour SELF)
$script:IFSF_IMPORT_BASENAMES = @("CRD_RQT", "CRD_RSP", "DVC_RQT", "DVC_RSP", "SVC_RQT", "SVC_RSP")
$script:IFSF_IMPORT_EXT = @{
    TETRA = ".V0662"
    T2    = ".V0662"
    SELF  = ".V1662"
}

function Get-IFSFTerminalTypeFromQAtcherID {
    param([string]$QAtcherTerminalID)
    if ([string]::IsNullOrWhiteSpace($QAtcherTerminalID)) { return "TETRA" }
    $id = $QAtcherTerminalID.ToUpperInvariant()
    if ($id -match "SELF")  { return "SELF" }
    if ($id -match "T2")    { return "T2" }
    # Move3500, TETRA, etc.
    return "TETRA"
}

function Get-IFSFConfig {
    [PSCustomObject]@{
        JenkinsUrl    = $script:IFSF_JENKINS_URL
        BuildDir      = $script:IFSF_BUILD_DIR
        TerminalType  = $script:IFSF_TERMINAL_TYPE
        PackageFiles  = $script:IFSF_PACKAGE_FILES
        ImportBasenames = $script:IFSF_IMPORT_BASENAMES
        ImportExt     = $script:IFSF_IMPORT_EXT
    }
}
