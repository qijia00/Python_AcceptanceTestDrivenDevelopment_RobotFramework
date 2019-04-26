*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   LUM-1112   master_pointing

*** Test Cases ***
Bring Master ECU into Site
    Connect to web services   ${IP}
    run keyword and ignore error   Login   ${user}   ${def_pass}
    run keyword and ignore error   Login   ${user}   ${pass}
    run keyword and ignore error   Remove from site
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout

Bring Slave ECU into Site
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in this test case

    Connect to web services   ${slave_IP}
    run keyword and ignore error   Login   ${user}   ${def_pass}
    run keyword and ignore error   Login   ${user}   ${pass}
    run keyword and ignore error   Remove from site
    Bring ECU into site   ${IP}   ecu_name=SlaveECU   site_type=${site_type}   offset=OFFSET0
    #Note that once bring-into-site is called for a slave ECU, you will need to log out and log back in again,
    #since the authentication will now be based on the master-forwarding mechanism.
    logout
    Login   ${user}   ${pass}
    Get version
    logout

Modify TBL_ECU in the site database
    #you will need this test case/step to make master ECU strart posting master-info
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Get database information
    ${update_id}=   get update id
    Update tables   site_index=SITE0   json_payload=${tbl}   update_id=${update_id}   lock_id=
    logout

    Connect to web services   ${slave_IP}
    Login   ${user}   ${pass}
    Get version
    logout
#
#Backup Slave ECU A then retore it to Slave ECU B
#    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
#    Backup ecu and download   ${back_ecu_input}   location=${backup_slave_ecu_file_location}
#    Logout
#
#    Connect to web services   ${slave_IP_B}   ${user}   ${def_pass}   ${version}
#    Restore ecu   ${IP}   ${backup_slave_ecu_file_location}   #this will also reboot the ecu after upload the files
#    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
#    Get version
#    Logout
#
#Backup Master ECU 1 with both ECU and Site, and unplug it, then restore it on Master ECU 2
#    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
#    Backup ecu and download   ${back_ecu_input}   location=${backup_master_ecu_file_location}
#    Backup site and download   location=${backup_site_file_location}
#
##    Unplug Master ECU 1
#
#    Connect to web services   ${master_IP_2}   ${user}   ${def_pass}   ${version}
#    Restore site   ${backup_site_file_location}
#    Logout
#    Login   ${user}   ${pass}
#    Restore ecu   ${master_IP_2}   ${backup_master_ecu_file_location}   #this will also reboot the ecu after upload the files
#
#    Sleep   15s

#    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
#    Get version
#    Logout
#
#    Connect to web services   ${slave_IP_B}   ${user}   ${pass}   ${version}
#    Get version
#    Logout
#
#Change Master ECU 2 IP
#    Manual change IP

#    Sleep   15s
#
#    Connect to web services   ${master_IP_2_new}   ${user}   ${pass}   ${version}
#    Get master info
#
#    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
#    Get version
#    Logout

#    Connect to web services   ${slave_IP_B}   ${user}   ${pass}   ${version}
#    Get version
#    Logout
#
#
#Reboot Slave ECU
#    Connect to web services   ${slave_IP_B}   ${user}   ${pass}   ${version}
#    Reboot ecu
#    #Manual reboot ecu
#
#    Connect to web services   ${slave_IP_B}   ${user}   ${pass}   ${version}
#    Get version
#    Logout

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.111
${master_IP_2}   172.24.172.101
${master_IP_2_new}   172.24.172.121
${slave_IP}   172.24.172.112
${slave_IP_B}   172.24.172.102
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

${tbl}      SEPARATOR=\n
...   {
...       "update-id" : "",
...       "lock-id": "",
...       "add": [
...           {
...               "ecu": [
...                 {"IDENTIFIER": "11111111-1111-1111-1111-111111111111", "IP_ADDRESS": "${IP}"},
...                 {"IDENTIFIER": "22222222-2222-2222-2222-222222222222", "IP_ADDRESS": "${master_IP_2}"},
...                 {"IDENTIFIER": "33333333-3333-3333-3333-333333333333", "IP_ADDRESS": "${slave_IP}"},
...                 {"IDENTIFIER": "44444444-4444-4444-4444-444444444444", "IP_ADDRESS": "${slave_IP_B}"},
...                 {"IDENTIFIER": "55555555-5555-5555-5555-555555555555", "IP_ADDRESS": "${master_IP_2_new}"}
...                ]
...           }
...       ]
...   }

${back_ecu_input}   SEPARATOR=\n
...     {
...         "store-log-files": true,
...         "store-event-files": true,
...         "store-core-dumps": true
...     }

${backup_slave_ecu_file_location}   .//artifacts//slave_ecu_backup.zip
${backup_master_ecu_file_location}   .//artifacts//master_ecu_backup.zip
${backup_site_file_location}   .//artifacts//site_backup.zip

${master_info}   SEPARATOR=\n
...   {
...      "master-ecu-ip": "${master_IP_2_new}",
...      "site-id" : ""
...  }

*** Keywords ***
Setup System
#    run keyword and ignore error   Connect to web services   ${slave_IP_B}   ${user}   ${def_pass}   ${version}
#    run keyword and ignore error   Connect to web services   ${slave_IP_B}   ${user}   ${pass}   ${version}
#    Run keyword and ignore error   Remove from site
#    Run keyword and ignore error   Logout
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Logout
#    run keyword and ignore error   Connect to web services   ${master_IP_2}   ${user}   ${def_pass}   ${version}
#    run keyword and ignore error   Connect to web services   ${master_IP_2}   ${user}   ${pass}   ${version}
#    Run keyword and ignore error   Remove from site
#    Run keyword and ignore error   Get database information
#    Run keyword and ignore error   Delete site with id   SITE0
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Logout

Breakdown System
#    run keyword and ignore error   Connect to web services   ${slave_IP_B}   ${user}   ${def_pass}   ${version}
#    run keyword and ignore error   Connect to web services   ${slave_IP_B}   ${user}   ${pass}   ${version}
#    Remove from site
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Remove from site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout
#    run keyword and ignore error   Connect to web services   ${master_IP_2}   ${user}   ${pass}   ${version}
#    run keyword and ignore error   Connect to web services   ${master_IP_2}   ${user}   ${def_pass}   ${version}
#    Remove from site
#    Get database information
#    Delete site with id   SITE0
#    Logout
#    run keyword and ignore error   Connect to web services   ${master_IP_2_new}   ${user}   ${pass}   ${version}
#    run keyword and ignore error   Connect to web services   ${master_IP_2_new}   ${user}   ${def_pass}   ${version}
#    Remove from site
#    Get database information
#    Delete site with id   SITE0
#    Logout
    Remove File   .//artifacts//*.zip
    Remove File   .//artifacts//*.sqlite