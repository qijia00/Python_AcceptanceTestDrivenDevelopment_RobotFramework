*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   LUM-721   password_recovery   semi-automated

*** Test Cases ***
Original password for user still works when Challenge Key is outstanding
    connect to web services   ${master_ECU_IP}
    login   ${user}   ${pass}
    reboot ecu   # bring the ECU time back to normal

*** Variables ***
${version}   v2
${site_type}   lumenade
${master_ECU_IP}   172.24.172.101
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
...         "site-type": "${site_type}"
...     }

*** Keywords ***
Setup System
    run keyword and ignore error   Connect to web services   ${master_ECU_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${master_ECU_IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${master_ECU_IP}   ecu_name=MasterECU   site_type=${site_type}
    Logout

Breakdown System
    run keyword and ignore error   Connect to web services   ${master_ECU_IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${master_ECU_IP}   ${user}   ${def_pass}   ${version}
    Run keyword and ignore error   Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.sqlite