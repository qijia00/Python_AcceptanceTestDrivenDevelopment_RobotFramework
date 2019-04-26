*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   regression

*** Test Cases ***
Create Offline Site Then Move to Online ECU - Create Offline Site
    Connect to web services   ${IP}   ${user}   ${def_pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Create new site   ${new_site}
    Logout
    Run keyword and expect error   *   Login   ${user}   ${def_pass}
    Login   ${user}   ${pass}
    Logout

Create Offline Site Then Move to Online ECU - Backup Offline Site
    Connect to web services   ${IP}   ${user}   ${pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Backup site and download   location=${backup_site_file_location}   offline=True
    Logout
    Disconnect from web services

Create Offline Site Then Move to Online ECU - Restore Site to Online ECU
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    restore site   ${backup_site_file_location}
    Logout

Create offline site Then Move to Online ECU - Validate Online ECU has the site
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Bring ECU into site   ${IP}   ecu_name=MasterECU   site_type=${site_type}
    Logout
    Disconnect from web services

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

${backup_site_file_location}   .//artifacts//site_backup.zip

*** Keywords ***
Setup System
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout
    Disconnect from web services
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout
    Disconnect from web services

Breakdown System
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Disconnect from web services
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Run keyword and ignore error   Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Disconnect from web services
    Remove File   .//artifacts//*.sqlite
    Remove File   .//artifacts//testdata//data//*.json
    Remove File   ${backup_site_file_location}