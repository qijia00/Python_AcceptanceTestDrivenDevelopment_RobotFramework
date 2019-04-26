*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Force Tags       webservices   LUM-3800   bug

*** Test Cases ***
Obtain the current version of the ECU files
    Connect to web services   ${IP}
    clean sessions
    Log   ecu version wil fail due to LUM-3800   WARN
    ecu version

*** Variables ***
${IP}   172.24.172.102
${user}   sysadmin

*** Keywords ***