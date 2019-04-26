*** Settings ***
Library             ECULibrary
Library             WebServiceLibrary
Library             OperatingSystem
Library             BuiltIn
Library             String
Library             Collections
Library             HWSupportLibrary

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       firmware   bug

*** Test Cases ***
Unmap ECU will loose site ID
    connect to ECU   ${IP}
    # unmap all the notes from the ECU, you can call unmap ecu API, but your ECU needs to be in site.
    Connect to web services   ${IP}   ${user}   ${pass}
    unmap ecu   timeout=60
    Disconnect

*** Variables ***
${IP}   172.24.172.101
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   newpassword

${new_site}   SEPARATOR=\n
...     {
...         "name": "Site management test",
...         "version": "Version 4.0.0",
...         "customer": "QA",
...         "project": "Robot",
...         "author": "Jia",
...         "default": true,
...         "date": "06/29/2017 9:54:00 AM",
...         "username": "${user}",
...         "password": "${pass}",
...         "fullname": "System Administrator",
...         "site-type": "lumenade"
...     }

*** Keywords ***
Setup System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout

Breakdown System
    [Documentation]   Remove the Master ECU from the site & Delete the site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}
    Run keyword and ignore error   Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.sqlite