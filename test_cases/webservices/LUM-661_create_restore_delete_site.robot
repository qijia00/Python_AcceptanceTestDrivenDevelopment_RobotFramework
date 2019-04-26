*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       lum-661   webservices   create-site   restore-site    delete-site

*** Variables ***
${version}   v1
${IP}   10.215.23.87
${user}   sysadmin
${ori_pass}   1um3nad3
${pass}   newpassword
${backup_file_location}   .\\artifacts\\lum661_site_backup.zip

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

*** Test Cases ***
Create Site
    [Documentation]   Create site test
    Login   ${user}   ${ori_pass}
    get ecu information
    Create new site   ${new_site}
    get ecu information
    Logout

Backup Site
    [Documentation]   Backup site
    Login   ${user}   ${pass}
    Backup site and download   ${backup_file_location}
    Logout

Delete Site
    [Documentation]   Delete site
    Login   ${user}   ${pass}
    Get database information
    Delete site with id   SITE0

Validate Blank Site
    [Documentation]   Validate the site has been deleted
    Run keyword and expect error   *   Login   ${user}   ${pass}
    Login   ${user}   ${ori_pass}
    get ecu information
    Logout

Restore Site
    [Documentation]   Restore site with backup
    Login   ${user}   ${ori_pass}
    Restore site   ${backup_file_location}
    get ecu information
    Logout

Validate Restored Site
    [Documentation]   Validate site is restored with the site user and password
    Run keyword and expect error   *   Login   ${user}   ${ori_pass}
    Login   ${user}   ${pass}
    Logout

Validate Set Master Set Slave are removed
    Login   ${user}   ${pass}
    run keyword and expect error   *   Assign master ecu
    run keyword and expect error   *   Assign slave ecu
    Logout

*** Keywords ***
Setup System
    [Documentation]   Remove ECU from site and Delete site if necessary
    Connect to web services  ${IP}   ${user}   ${ori_pass}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout

Breakdown System
    [Documentation]   Delete the site
    Login   ${user}   ${pass}
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .\\artifacts\\default.sqlite
    Remove File   ${backup_file_location}