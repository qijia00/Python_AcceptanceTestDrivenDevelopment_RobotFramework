*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   LUM-1112   master_pointing

*** Test Cases ***
Bring master ECU into Site
    Connect to web services   ${IP}
    run keyword and ignore error   Login   ${user}   ${def_pass}
    run keyword and ignore error   Login   ${user}   ${pass}
    run keyword and ignore error   Remove from site
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout

Bring slave ECU into Site
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
    clean sessions
    Login   ${user}   ${pass}
    get automated backup configuration   SESSION0
    logout

Modify TBL_ECU in the site database
    #you will need this test case/step to make master ECU strart posting master-info
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Get database information
    ${update_id}=   get update id
    Update tables   site_index=SITE0   json_payload=${tbl}   update_id=${update_id}   lock_id=
    logout
    # verify slave got master pointing info after setup properly
    Connect to web services   ${slave_IP}
    clean sessions
    Login   ${user}   ${pass}
    get automated backup configuration   SESSION0
    logout

Backup slave ECU then remove it from site
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Backup ecu and download   ${back_ecu_input}   location=${backup_slave_ecu_file_location}
    Remove from site

Backup master ECU with both ECU and Site, and remove from site, then delete site.
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Backup ecu and download   ${back_ecu_input}   location=${backup_master_ecu_file_location}
    Backup site and download   location=${backup_site_file_location}
    Remove from site
    run keyword and ignore error   get ecu offset   # should be 0, i.e., not in site
    Get database information
    Delete site with id   SITE0
    Logout

Restore the site and ecu files backed up from the original master ECU to the original slave ECU to make it the new master
    Connect to web services   ${slave_IP}
    Restore site   ${backup_site_file_location}
    clean sessions
    Login   ${user}   ${pass}
    get database information
    Run keyword and expect error   *   Remove from site
    #this will also reboot the ecu after upload the files, reboot ecu cause all sessions becomes invalid
    Restore ecu   ${slave_IP}   ${backup_master_ecu_file_location}   session_index=SESSION0

Restore the ecu file backed up from the original slave ECU to the original master ECU to make it the new slave
    Connect to web services   ${IP}
    # this will also reboot the ecu after upload the files, reboot ecu cause all sessions becomes invalid
    Restore ecu   ${slave_IP}   ${backup_slave_ecu_file_location}
    sleep   6 minutes   # wait for master pointing from current master ECU to slave ECU
    # verify slave got master pointing info after restore
    clean sessions
    Connect to web services   ${IP}
    Login   ${user}   ${pass}
    get automated backup configuration   SESSION0
    logout

Change master ECU IP - note the original slave is master now
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    change local ip   json_payload=${new_IP}
    sleep   20s
    # verify ip change succeed
    Connect to web services   ${IP_new}
    ${ip_return}=  get local ip   expected_ip=${IP_new}

    # verify master is good
    Connect to web services   ${IP_new}   ${user}   ${pass}   ${version}
    Get master info

    # verify slave got master pointing info after master ECU IP change
    sleep   6 minutes   # wait for master pointing from current master ECU to slave ECU
    Connect to web services   ${IP}
    clean sessions
    Login   ${user}   ${pass}
    get automated backup configuration   SESSION0
    logout

Change slave ECU IP from original master ECU IP back to original slave ECU IP
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    change local ip   json_payload=${original_slave_IP}
    sleep   20s
    # verify ip change succeed
    Connect to web services   ${slave_IP}
    ${ip_return}=  get local ip   expected_ip=${slave_IP}
    # verify slave got master pointing info after itself IP change
    clean sessions
    Login   ${user}   ${pass}
    get automated backup configuration   SESSION0
    logout

Reboot Slave ECU
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Reboot ecu
    # verify slave got master pointing info after reboot
    Connect to web services   ${slave_IP}
    clean sessions
    Login   ${user}   ${pass}
    get automated backup configuration   SESSION0
    logout

Change master ECU IP back to its original IP
    Connect to web services   ${IP_new}   ${user}   ${pass}   ${version}
    change local ip   json_payload=${original_master_IP}
    sleep   25s
    # verify ip change succeed
    Connect to web services   ${IP}
    ${ip_return}=  get local ip   expected_ip=${IP}

swap the IP to their originals
    # at this point, your 2 ECU IPs are swaped
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    change local ip   json_payload=${new_IP}
    sleep   25s
    # verify ip change succeed
    Connect to web services   ${IP_new}
    ${ip_return}=  get local ip   expected_ip=${IP_new}

    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    change local ip   json_payload=${original_master_IP}
    sleep   25s
    # verify ip change succeed
    Connect to web services   ${IP}
    ${ip_return}=  get local ip   expected_ip=${IP}

    Connect to web services   ${IP_new}   ${user}   ${pass}   ${version}
    change local ip   json_payload=${original_slave_IP}
    sleep   20s
    # verify ip change succeed
    Connect to web services   ${slave_IP}
    ${ip_return}=  get local ip   expected_ip=${slave_IP}

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.101
${slave_IP}   172.24.172.102
${IP_new}   172.24.172.103
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
...                 {"IDENTIFIER": "22222222-2222-2222-2222-222222222222", "IP_ADDRESS": "${slave_IP}"},
...                 {"IDENTIFIER": "33333333-3333-3333-3333-333333333333", "IP_ADDRESS": "${IP_new}"}
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

${original_slave_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${slave_IP}"
...   }

${new_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${IP_new}"
...   }

${original_master_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${IP}"
...   }

*** Keywords ***
Setup System
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    run keyword and ignore error   Connect to web services   ${IP_new}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP_new}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Run keyword and ignore error   Delete site with id   SITE0
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
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    run keyword and ignore error   Connect to web services   ${IP_new}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP_new}   ${user}   ${def_pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Remove File   .//artifacts//*.zip
    Remove File   .//artifacts//*.sqlite