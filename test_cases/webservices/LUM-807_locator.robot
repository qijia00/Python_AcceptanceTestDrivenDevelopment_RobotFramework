*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       lum-807   webservices   locator

*** Test Cases ***
Misc Test
    Login   ${user}   ${pass}
    Get Local IP
    Start Locator   local_only=True
    Start Locator   local_only=False
    Start Locator   local_only=
    Start Locator   local_only=true
    Start Locator   local_only=false
    Start Locator   local_only=None
    Get Locator   local_only=True
    Get Locator   local_only=False
    Get Locator   local_only=
    Get Locator   local_only=none
    Logout

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   10.215.21.17
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
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}    db_read=False
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout

Breakdown System
    [Documentation]   Remove the Master ECU from the site & Delete the site
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Unlock configuration   force=True
    Run keyword and ignore error   Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
#    Remove File   .//artifacts//*.sqlite