*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn

Suite Setup      Setup System
Suite Teardown   Run keyword and ignore error   Breakdown System

Force Tags       lum-433   lum-327   webservices   ecu_backup_restore

*** Variables ***
${IP}   10.215.23.97
${user}   sysadmin
${pass}   newpassword

${new_site}   SEPARATOR=\n
...     {
...         "name": "New Site",
...         "version": "Version 4.0.0",
...         "customer": "QA",
...         "project": "Robot",
...         "author": "Amabini",
...         "default": true,
...         "date": "06/15/2017 10:45:00 AM",
...         "username": "sysadmin",
...         "password": "newpassword",
...         "fullname": "A Mabini",
...         "site-type": "lumenade"
...     }

*** Test Cases ***
Backup ECU
    [Documentation]   Backup ECU test
    Login   ${user}   ${pass}
    Backup ecu and download   location=.//artifacts//ecu_backup1.zip
    Delete site with id   SITE0
    Backup ecu and download   location=.//artifacts//ecu_backup2.zip
    Compare ecu backups   .//artifacts//ecu_backup1.zip   .//artifacts//ecu_backup2.zip
    Reboot
    Run keyword and ignore error   Disconnect

Backup after Reboot
    [Documentation]   Validates site is not restored after reboot
    Setup System
    Login   ${user}   ${pass}
    Backup ecu and download   location=.//artifacts//ecu_backup3.zip
    Compare ecu backups   .//artifacts//ecu_backup2.zip   .//artifacts//ecu_backup3.zip
    #Factory default ecu

Restore Backup and Validate
    [Documentation]   Restores the first backup and validate it with a new backup
    Restore ecu     ${IP}   ecu_backup=.//artifacts//ecu_backup1.zip
    Login   ${user}   ${pass}
    Backup ecu and download   location=.//artifacts//ecu_backup4.zip
    Compare ecu backups   .//artifacts//ecu_backup1.zip   .//artifacts//ecu_backup4.zip
    Reboot

Restore Backup 2 and Validate
    [Documentation]  Restores the 2nc backup and validates it with a new backup
    Login   ${user}   ${pass}
    Restore ecu   ${IP}   ecu_backup=.//artifacts//ecu_backup2.zip
    Login   ${user}   ${pass}
    Backup ecu and download   .//artifacts//ecu_backup5.zip
    Compare ecu backups   .//artifacts//ecu_backup2.zip   .//artifacts/ecu_backup5.zip

*** Keywords ***
Setup System
    [Documentation]   Create a site and upload a floorplan
    WebServiceLibrary.Connect to web services   ${IP}   sysadmin   1um3nad3
    Connect to ecu   ${IP}
    Create new site   ${new_site}
    Get database information
    Login   ${user}   ${pass}
    Logout

Breakdown System
    [Documentation]   Delete the site
    Login   ${user}   ${pass}
    Disconnect
    Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout