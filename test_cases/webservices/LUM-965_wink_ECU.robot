*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   lum-965   wink_ecu

*** Test Cases ***
Master ECU Wink Test
    Login   ${user}   ${pass}
#    Logout
    Get database information
    Bring ECU into site   ecu_name=MasterECU   site_type=${site_type}
#    Logout
    WINK ECU
    Logout

Slave ECU Wink Test
    Login   ${user}   ${pass}
    Get database information
    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in this test case
    Logout
    Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}    db_read=False
#    logout
    run keyword and ignore error   Remove from site
    Login   ${user}   ${def_pass}
    Bring ECU into site   ${IP}   ecu_name=SlaveECU   site_type=${site_type}   offset=OFFSET0
#    logout
    wink ecu
    Remove from site
    Logout

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   10.215.21.121
${slave_IP}   10.215.21.17
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
    [Documentation]   Create a new site on Master ECU & Bring the Master ECU to site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout

Breakdown System
    [Documentation]   Remove the Master ECU from the site & Delete the site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Run keyword and ignore error   Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.sqlite