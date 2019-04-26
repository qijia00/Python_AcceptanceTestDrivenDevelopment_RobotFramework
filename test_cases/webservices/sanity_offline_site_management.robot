*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   regression

*** Test Cases ***
Site Management Test - Create Site
    Connect to web services   ${IP}   ${user}   ${def_pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Create new site   ${new_site}
    Logout
    Run keyword and expect error   *   Login   ${user}   ${def_pass}
    Login   ${user}   ${pass}
    Logout

Site Management Test - Delete Site
    Login   ${user}   ${pass}
    Get database information
    Delete site with id   SITE0
    Logout
    Run keyword and expect error   *   Login   ${user}   ${pass}

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   192.168.86.88
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

${offline_dll}   .//artifacts//DataServiceDLL.dll
${offline_storage}   .//artifacts//testdata

*** Keywords ***
Setup System
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout

Breakdown System
    Disconnect from web services
    Remove File   .//artifacts//*.sqlite
    Remove File   .//artifacts//testdata//data//*.json