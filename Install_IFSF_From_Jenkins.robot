*** Settings ***
Resource    ${CURDIR}/../resources.robot

Library    BuiltIn
Library    Collections
Library    OperatingSystem
Library    String
Library    Process
Library    QAtcherLibrary    host=${QAtcherHost}    port=${QAtcherPort}

*** Variables ***
${QAtcherTerminalID}    Move3500_54227826
${IFSF_BUILD_DIR}       ${EMPTY}
${IFSF_JENKINS_URL}     ${EMPTY}

*** Test Cases ***

Install IFSF From Jenkins
    [Documentation]    Télécharge le dernier build IFSF depuis Jenkins (si IFSF_JENKINS_URL défini),
    ...                prépare les fichiers selon le type de terminal (TETRA/T2/SELF),
    ...                puis installe via Local Upgrade (/package et /import).
    ...                Terminal type: IFSF_TERMINAL_TYPE ou déduit de QAtcherTerminalID.
    # 1) Obtenir le répertoire des fichiers IFSF (téléchargement Jenkins ou IFSF_BUILD_DIR)
    Run Keyword If    '''${IFSF_BUILD_DIR}''' == ''    Télécharger IFSF depuis Jenkins puis définir répertoire
    Should Not Be Empty    ${IFSF_BUILD_DIR}    msg=Définir IFSF_BUILD_DIR (ou IFSF_JENKINS_URL dans l'environnement pour téléchargement auto)
    ${build_dir}=    Set Variable    ${IFSF_BUILD_DIR}

    # 2) Lire les listes package et import
    ${pkg_content}=    Get File    ${build_dir}${/}package.txt
    ${pkg_lines}=    Get Lines    ${pkg_content}
    ${import_content}=    Get File    ${build_dir}${/}import.txt
    ${import_lines}=    Get Lines    ${import_content}

    # 3) Connexion et préparation LLT
    Connect Device    ${QAtcherTerminalID}
    FOR    ${i}    IN RANGE    3
        ${status}=    Run Keyword And Return Status    Local Upgrade Disconnect    ${QAtcherTerminalID}
        Run Keyword If    ${status}    Log    Session LLT fermée (tentative ${i+1})    level=INFO
        Sleep    2s
    END
    Sleep    3s
    Local Upgrade Connect    ${QAtcherTerminalID}

    # 4) Envoi des fichiers package vers /package
    FOR    ${f}    IN    @{pkg_lines}
        Continue For Loop If    '''${f}''' == ''
        ${path}=    Set Variable    ${build_dir}${/}${f}
        Local Upgrade Download    ${QAtcherTerminalID}    ${path}    /package
    END

    # 5) Envoi des fichiers import vers /import
    FOR    ${f}    IN    @{import_lines}
        Continue For Loop If    '''${f}''' == ''
        ${path}=    Set Variable    ${build_dir}${/}${f}
        Local Upgrade Download    ${QAtcherTerminalID}    ${path}    /import
    END

    # 6) Déconnexion LLT et attente du redémarrage
    Local Upgrade Disconnect    ${QAtcherTerminalID}
    Wait For Terminal    ${QAtcherTerminalID}    timeout=120    available=True
    Disconnect Device    ${QAtcherTerminalID}
    Log    IFSF installé sur ${QAtcherTerminalID}.    level=INFO

*** Keywords ***

Télécharger IFSF depuis Jenkins puis définir répertoire
    ${result}=    Run Process    powershell.exe    -NoProfile    -ExecutionPolicy    Bypass    -File    ${CURDIR}${/}download_ifsf_from_jenkins.ps1    -QAtcherTerminalID    ${QAtcherTerminalID}    cwd=${CURDIR}
    Should Be Equal As Integers    ${result.rc}    0    msg=Échec du téléchargement IFSF: ${result.stderr}
    ${lines}=    Get Lines    ${result.stdout}
    ${count}=    Get Length    ${lines}
    Should Be True    ${count} > 0    msg=Aucune sortie du script de téléchargement
    ${last_index}=    Evaluate    int($count) - 1
    ${last}=    Get From List    ${lines}    ${last_index}
    ${build_dir}=    Strip String    ${last}
    Set Suite Variable    ${IFSF_BUILD_DIR}    ${build_dir}
    Log    IFSF_BUILD_DIR=${build_dir}    level=INFO
