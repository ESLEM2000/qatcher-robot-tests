*** Settings ***
Resource    ../resources.robot
Library    QAtcherLibrary    host=${QAtcherHost}    port=${QAtcherPort}    device_id=${QAtcherTerminalID}    peripheral=terminal

Suite Setup    Safe Connect and Get Product Name
Suite Teardown    Safe Disconnect Device
# Make sure we go back to the payment screen between each test case (ne fait pas échouer si Payment absent)
Test Teardown    Safe Reset Screen
