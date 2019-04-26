*** Settings ***
Library             ECULibrary
Library             BuiltIn
Suite Setup         Setup system
Suite Teardown      Run keyword and ignore error   Teardown system

*** Variables ***
${IP}
${linuxecu}
${datawebservice}
${updatewebservice}

*** Test Cases ***
Upgrade ECU Files
    Upgrade application   ${linuxecu}   ..//firmware//LinuxECU.exe
    Upgrade application   ${datawebservice}   ..//firmware//webservice//DataWebService.exe
    Upgrade application   ${updatewebservice}   ..//firmware//webservice//UpdateWebService.exe   reboot=True

*** Keywords ***
Setup system
    Establish SSH connection   ${IP}

Teardown system
    Disconnect
