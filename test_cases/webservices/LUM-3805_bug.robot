*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Force Tags       webservices   LUM-3805   bug

*** Test Cases ***
Upgrade without login on blank ECU
    Connect to web services   ${IP}
    clean sessions
    Log   upgrade wil fail due to LUM-3805   WARN
    upgrade   ${upgrade_zip}
    ecu version

*** Variables ***
${IP}   172.24.172.101
${upgrade_zip}   .//input//LUMENADE_WM_ECU_UPDATE_ZIP_109.zip



