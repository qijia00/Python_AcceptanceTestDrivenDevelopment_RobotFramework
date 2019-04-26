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
DALI LS PD - Occupancy functionality test
    Connect to DALI magic with serial   00491103070A2E0D
    ${SAK_ID} =   Get SAK Reference
    LOG    SAK id : ${SAK_ID}
    ${SAK_ID_STR} =   convert to string   ${SAK_ID}
    Write property access   ${SAK_ID_STR}   9   1
    Sleep   20
    :FOR   ${INDEX}   IN RANGE   ${TEST_REP}
    \   Create presence
    \   Sleep   5
    \   Verify lights level
    \   Log   Waiting for lights to go OFF after timeout ...
    \   Sleep   70
    \   Run keyword and expect error   *   Verify lights level
    Disconnect DALI Magic

DALI LS PD - Photo detection functionality test
    Connect to DALI magic with serial   00490E0C100A163B
    ${SAK_ID} =   Get SAK Reference
    LOG    SAK id : ${SAK_ID}
    ${SAK_ID_STR} =   convert to string   ${SAK_ID}
    Write property access   ${SAK_ID_STR}   9   1
    Sleep   20
    :FOR   ${INDEX}   IN RANGE   ${TEST_REP}
    \   Off
    \   Sleep   5
    \   run keyword and ignore error   PHS light reading increased  # to get first value of reading
    \   Move to level   100
    \   Sleep   5
    \   PHS light reading increased
    \   Move to level   200
    \   Sleep   5
    \   PHS light reading increased
    \   Move to level   100
    \   Sleep   5
    \   Run keyword and expect error   Light level decreased   PHS light reading increased
    \   Off
    \   Sleep   5
    \   Run keyword and expect error   Light level decreased   PHS light reading increased
    Disconnect DALI Magic

*** Keywords ***
Setup system
    Connect to ECU   ${IP}
    DALI log to console

Teardown system
    Disconnect
