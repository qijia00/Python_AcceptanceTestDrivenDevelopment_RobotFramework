*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       lum-657   webservices   factory_reset

*** Test Cases ***
Test
    Login   ${user}   ${pass}
    Factory default ecu
    run keyword and expect error   *   establish ssh connection   ${IP}

Test 2
    establish ssh connection   ${default_ip}   # please run this test on you own network
    change encelium ip   ${IP}   255.255.252.0   10.215.20.1
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}    db_read=False
    run keyword and ignore error   Logout

Test 3
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}    db_read=False
    Logout


*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   10.215.21.121
${default_ip}   172.24.172.200
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
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}    db_read=False
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout

Breakdown System
    Remove File   .//artifacts//*.sqlite