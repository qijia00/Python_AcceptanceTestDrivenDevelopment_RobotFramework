*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Run keyword and ignore error   Breakdown System

Force Tags       lum-170   webservices   ecu_backup_restore   site_backup_restore

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.111
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   12345

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

${back_ecu_input}   SEPARATOR=\n
...     {
...         "store-log-files": true,
...         "store-event-files": true,
...         "store-core-dumps": true
...     }

*** Test Cases ***
Backup ECU and Site
    [Documentation]   Backup ECU test
    Login   ${user}   ${pass}
    Backup ecu and download   ${back_ecu_input}   location=.//artifacts//lum170_ecu_backup.zip
    Backup site and download   location=.//artifacts//lum170_site_backup.zip
    Remove from site
    get database information
    Delete site with id   SITE0
    Reboot ECU

Validate Blank Site
    [Documentation]   Validate new site password no longer exists
    Run keyword and expect error   *   Login   ${user}   ${pass}
    Login   ${user}   ${def_pass}
    Logout

Restore ECU
    [Documentation]   Restore Backed up ECU
    restore ecu   ${IP}   .//artifacts//lum170_ecu_backup.zip

Restore Site
    [Documentation]   Restore Backed up Site
    Restore site   .//artifacts//lum170_site_backup.zip

Validate Restored Site
    [Documentation]   Validate restored site backup my trying to log in with the backed up password
    Run keyword and expect error   *   Login   ${user}   ${def_pass}
    Login   ${user}   ${pass}
    Logout

*** Keywords ***
Setup System
    [Documentation]   Create a site and upload a floorplan
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout
    Login   ${user}   ${pass}
    Get database information
    Get user list
    ${lock_id}=   Lock configuration   USER0   force=true
    Upload floorplan   SITE0   .//input//floorplan.efg.gz
    Unlock configuration   force=true
    Logout

Breakdown System
    [Documentation]   Delete the site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.egf.gz
    Remove File   .//artifacts//*.sqlite
    Remove File   .//artifacts//*.zip