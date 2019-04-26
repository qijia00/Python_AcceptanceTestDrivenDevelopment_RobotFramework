*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       lum-830   webservices   restore_ecu   resotre_site

*** Variables ***
${IP}   10.215.21.121
${slave_IP}   10.215.21.17
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   password
${new_pass}   newpassowrd

${site}   SEPARATOR=\n
...     {
...         "name": "Site",
...         "version": "Version 4.0.0",
...         "customer": "QA",
...         "project": "Robot",
...         "author": "Amabini",
...         "default": true,
...         "date": "06/15/2017 10:45:00 AM",
...         "username": "${user}",
...         "password": "${pass}",
...         "fullname": "A Mabini",
...         "site-type": "lumenade"
...     }

${new_site}   SEPARATOR=\n
...     {
...         "name": "New Site",
...         "version": "Version 4.0.0",
...         "customer": "QA",
...         "project": "Robot",
...         "author": "Jia",
...         "default": true,
...         "date": "08/15/2017 10:45:00 AM",
...         "username": "${user}",
...         "password": "${newpass}",
...         "fullname": "A Mabini",
...         "site-type": "lumenade"
...     }

${back_ecu_input}   SEPARATOR=\n
...     {
...         "store-log-files": true,
...         "store-event-files": true,
...         "store-core-dumps": true
...     }

${backup_slave_ecu_file_location}   .//artifacts//slave_ecu_backup.zip
${backup_master_ecu_file_location}   .//artifacts//master_ecu_backup.zip
${backup_site_file_location}   .//artifacts//site_backup.zip

*** Test Cases ***
#Bring slave ECU into site and Backup slave ECU
#    Connect to web services   ${IP}   ${user}   ${pass}
#    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in this test case
#    Connect to web services   ${slave_IP}   ${user}   ${def_pass}
#    run keyword and ignore error   Remove from site
#    Login   ${user}   ${def_pass}
#    Bring ECU into site   ${IP}   ecu_name=SlaveECU   offset=OFFSET0
#    Backup ecu and download   ${back_ecu_input}   location=${backup_slave_ecu_file_location}
#    Remove from site
#    Connect to web services   ${IP}   ${user}   ${pass}
#    Get database information
#    Free offsets   SITE0   {"offsets":${offsets_list}}
#    Logout

Backup site and master ECU when in site
#    Connect to web services   ${IP}   ${user}   ${pass}
##    backup site and download   location=${backup_site_file_location}
#    Backup ecu and download   ${back_ecu_input}   location=${backup_master_ecu_file_location}
#    remove from site
##    Delete site with id   SITE0
#    logout

#Create a new site and bring master and slave ecu into the new site
#    Connect to web services   ${IP}   ${user}   ${def_pass}
#    Create new site   ${new_site}
#    Logout
#    Login   ${user}   ${new_pass}
#    Get database information
#    Bring ECU into site   ${IP}   ecu_name=MasterECU
#    Get Local IP
#    Start Locator   local_only=True
#    Start Locator   local_only=False
#    Start Locator   local_only=
#    Start Locator   local_only=None
#    Get Locator   local_only=True
#    Get Locator   local_only=False
#    Get Locator   local_only=
#    Get Locator   local_only=none
##    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in this test case
#    Logout
#
#    Connect to web services   ${slave_IP}   ${user}   ${def_pass}
#    run keyword and ignore error   Remove from site
#    Login   ${user}   ${def_pass}
#    Bring ECU into site   ${IP}   ecu_name=SlaveECU   offset=OFFSET0
#    Logout
#    Connect to web services   ${IP}   ${user}   ${new_pass}
#    Get database information
#    Free offsets   SITE0   {"offsets":${offsets_list}}
#    Logout

#Restore site backup when no site
#    Restore site   ${backup_site_file_location}

#Restore site backup when site
#    Connect to web services   ${IP}   ${user}   ${pass}
#    Restore site   ${backup_site_file_location}   SITE0
#    Logout

#Restore ecu backup when no db and not in site
#    restore ecu   ${IP}   ${backup_master_ecu_file_location}

#Restore ecu backup when no db but in site
#    Connect to web services   ${slave_IP}   ${user}   ${def_pass}
#    ${slave_ecu_offset}=   get ecu offset
#    restore ecu   ${IP}   ${backup_slave_ecu_file_location}   SITE0   ${slave_ecu_offset}
#    logout

#Restore ecu backup when db but not in site
#    run keyword and expect error   *   restore ecu   ${IP}   ${backup_master_ecu_file_location}
#    Connect to web services   ${IP}   ${user}   ${pass}
#    restore ecu   ${IP}   ${backup_master_ecu_file_location}

#Restore ecu backup when db and in site
#    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}
#    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${new_pass}
#    get database information
#    ${master_ecu_offset}=   get ecu offset
#    restore ecu   ${IP}   ${backup_master_ecu_file_location}   SITE0   ${master_ecu_offset}
##    Connect to web services   ${slave_IP}   ${user}   ${def_pass}
##    ${slave_ecu_offset}=   get ecu offset
##    restore ecu   ${IP}   ${backup_master_ecu_file_location}   SITE0   ${slave_ecu_offset}
##    logout

*** Keywords ***
Setup System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${new_pass}
    run keyword and ignore error   Get database information
    run keyword and ignore error   remove from site
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${site}
#    logout
#    Login   ${user}   ${pass}
#    Get database information
##    bring ecu into site   ${IP}   ecu_name=MasterECU
#    Logout

Breakdown System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${new_pass}
    run keyword and ignore error   Get database information
    run keyword and ignore error   remove from site
    Run keyword and ignore error   Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.zip
#    Remove File   .//artifacts//*.sqlite