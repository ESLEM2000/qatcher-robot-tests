*** Settings ***
Resource    ${CURDIR}/../resources.robot

Library    BuiltIn
Library    QAtcherLibrary    host=${QAtcherHost}    port=${QAtcherPort}

*** Variables ***
${QAtcherTerminalID}    Move3500_54227826

*** Test Cases ***

Mettre le terminal en mode maintenance
    [Documentation]    Connecte le terminal, active le mode maintenance puis attend son redémarrage.
    ...                Le terminal affichera l'écran MAINTENANCE. Ne déconnecte pas (terminal en maintenance).
    # Connexion du terminal à QAtcher
    Connect Device    ${QAtcherTerminalID}
    # Activation du mode maintenance (le terminal va redémarrer)
    Set Maintenance Mode    ${True}
    # Attente que le terminal soit à nouveau disponible après redémarrage
    Wait For Terminal    ${QAtcherTerminalID}    timeout=120    available=True
    Log    Le terminal ${QAtcherTerminalID} est en mode maintenance.    level=INFO

Quitter le mode maintenance
    [Documentation]    Désactive le mode maintenance du terminal. Le terminal redémarre et revient à l'écran normal.
    Connect Device    ${QAtcherTerminalID}
    Set Maintenance Mode    ${False}
    Wait For Terminal    ${QAtcherTerminalID}    timeout=120    available=True
    Disconnect Device    ${QAtcherTerminalID}
    Log    Le terminal ${QAtcherTerminalID} a quitté le mode maintenance.    level=INFO
