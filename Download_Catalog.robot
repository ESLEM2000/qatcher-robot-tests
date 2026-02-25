*** Settings ***
Resource    ${CURDIR}/../resources.robot

Library    BuiltIn
Library    Collections
Library    QAtcherLibrary    host=${QAtcherHost}    port=${QAtcherPort}
Library    ${CURDIR}/../resources/Library/decode_base64.py

*** Variables ***
${QAtcherTerminalID}    Move3500_54227826
${CATALOG_PATH}    C:/Users/eslem.hajamor/Desktop/haj amor eslem/QAtcher_v3 (2)/QAtcher_v3/2.28.0/QAtcherSuiteV3_2.28.0-0/QAtcherEmbeddedTETRA/CMP_QATCHER_EMBEDDED.Mxx

*** Test Cases ***

Download Catalog Test
    # Connect device to QAtcher
    Connect Device    ${QAtcherTerminalID}
    # Force disconnect any existing LLT session to avoid "Another local upgrade request is being processed" (409)
    FOR    ${i}    IN RANGE    3
        ${status}=    Run Keyword And Return Status    Local Upgrade Disconnect    ${QAtcherTerminalID}
        Run Keyword If    ${status}    Log    Session LLT fermée (tentative ${i+1})    level=INFO
        Sleep    2s    # Let the server release the lock
    END
    Sleep    3s    # Extra wait before opening a new LLT session
    # Connect the device in LLT Mode
    Local Upgrade Connect    ${QAtcherTerminalID}
    # Download a file to the terminal
    Local Upgrade Download      ${QAtcherTerminalID}    ${CATALOG_PATH}        /import
    # Disconnect LLT session
    Local Upgrade Disconnect    ${QAtcherTerminalID}
    # Wait for the terminal to reboot and be connected to QAtcher Server again
    Wait For Terminal    ${QAtcherTerminalID}    timeout=120    available=True
    Disconnect Device    ${QAtcherTerminalID}

Maintenance mode
    # Only excute test on Self devices
    Pass Execution If       not "SELF" in """${ProductName}"""    Skip test, not a Self Device
    # Switch device to maintenance mode. Device will reboot
    ${status}=    Run Keyword And Return Status    Set Maintenance Mode    ${True}
    Run Keyword If    not ${status}    Log    Set Maintenance Mode True ignoré    level=WARN
    # Wait until device is available again
    ${status}=    Run Keyword And Return Status    Wait For Terminal    timeout=5    available=True
    Run Keyword If    not ${status}    Log    Wait For Terminal ignoré    level=WARN
    # Wait for the maintenance mode screen to appear
    ${status}=    Run Keyword And Return Status    Wait For Text    MAINTENANCE
    Run Keyword If    not ${status}    Log    Wait For Text MAINTENANCE ignoré    level=WARN
    # Disable maintenance mode. Device will reboot
    ${status}=    Run Keyword And Return Status    Set Maintenance Mode    ${False}
    Run Keyword If    not ${status}    Log    Set Maintenance Mode False ignoré    level=WARN
    # Wait until device is available again
    ${status}=    Run Keyword And Return Status    Wait For Terminal    timeout=5    available=True
    Run Keyword If    not ${status}    Log    Wait For Terminal ignoré    level=WARN    