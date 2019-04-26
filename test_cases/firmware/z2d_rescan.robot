*** Settings ***
Library             ECULibrary
Library             DaliMagicLibrary
Library             BuiltIn
Suite Setup         Setup system
Suite Teardown      Run keyword and ignore error   Teardown system

*** Variables ***
${IP}      172.24.172.201
${TEST_REP}  2

*** Test Cases ***
Rescan - all devices unaddressed and unknown   #Scenario 1
    ${SAK_ID} =   Get SAK Reference
    LOG    SAK id : ${SAK_ID}
    ${SAK_ID_STR} =   convert to string   ${SAK_ID}
    :FOR   ${INDEX}   IN RANGE   ${TEST_REP}
    \   Delete DALI short address
    \   Randomize DALI search address
    \   Delete DALI sensor address
    \   Randomize DALI sensor search address
    \   Sleep   5
    \   Run keyword and expect error  *   Validate node tree status   "io-no-communication"
    \   Start rescan   ${SAK_ID_STR}   9
    \   Sleep   20
    \   Validate node tree status

Rescan - all devices unknown and addressed   #Scenario 2
    ${SAK_ID} =   Get SAK Reference
    LOG    SAK id : ${SAK_ID}
    ${SAK_ID_STR} =   convert to string   ${SAK_ID}
    :For   ${INDEX}   IN RANGE   ${TEST_REP}
    \   Start rescan   ${SAK_ID_STR}   9
    \   Sleep   10
    \   Randomize DALI search address
    \   start rescan   ${SAK_ID_STR}   9
    \   Sleep   15
    \   Validate node tree status

Rescan - all devices known and addressed   #Scenario 3
    ${SAK_ID} =   Get SAK Reference
    LOG    SAK id : ${SAK_ID}
    ${SAK_ID_STR} =   convert to string   ${SAK_ID}
    :FOR   ${INDEX}   IN RANGE   ${TEST_REP}
    \   Start rescan   ${SAK_ID_STR}   9
    \   Sleep   10
    \   Validate node tree status

Rescan - two devices with the same short address   #Scenario 4
    ${SAK_ID} =   Get SAK Reference
    LOG    SAK id : ${SAK_ID}
    ${SAK_ID_STR} =   convert to string   ${SAK_ID}
    :FOR   ${INDEX}   IN RANGE   ${TEST_REP}
    \   Start rescan   ${SAK_ID_STR}   9
    \   Sleep   10
    \   Randomize DALI search address   0x01
    \   Assign new DALI address
    \   Start rescan   ${SAK_ID_STR}   9
    \   Sleep   15
    \   Validate node tree status

*** Keywords ***
Setup system
    Connect to ECU   ${IP}
    Connect to DALI magic with serial   00491103070A2E0D
    Ecu log to console

Teardown system
    Disconnect
    Disconnect DALI Magic
