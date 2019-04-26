*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem
Library          Collections

Suite Setup      System Startup
Suite Teardown   System Breakdown
Test Teardown    Extract Spy Messages

Force Tags       webservices   regression

*** Test Cases ***
Site/ECU Management Test - Bring Slave ECU into site and Backup Slave ECU then reboot
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Get database information
    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in this test case
    Logout
    Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Remove from site
    Bring ECU into site   ${IP}   ecu_name=SlaveECU   site_type=${site_type}   offset=OFFSET0
    Logout
    Login   ${user}   ${pass}
    Backup ecu and download   ${back_ecu_input}   location=${backup_slave_ecu_file_location}
    Remove from site

#Site/ECU Management Test - Restore Slave ECU when has no DB and not in site
    Connect to web services   ${slave_IP}
    clean sessions
    Restore ecu   ${IP}   ${backup_slave_ecu_file_location}   #this will also reboot the ecu after upload the files

#Site/ECU Management Test - Restore Slave ECU when has no DB but in site
    clean sessions
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    ${slave_ecu_offset}=   get ecu offset
    Restore ecu   ${IP}   ${backup_slave_ecu_file_location}   SITE0   ${slave_ecu_offset}   SESSION0
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Remove from site

#Site/ECU Management Test - Switch to Master ECU
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Free offsets   SITE0   {"offsets":${offsets_list}}
    Logout

Site/ECU Management Test - Backup Master ECU and Site then reboot
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    get ecu offset   # should be an interger >=100, i.e., in site
    Backup ecu and download   ${back_ecu_input}   location=${backup_master_ecu_file_location}
    Backup site and download   location=${backup_site_file_location}
    Remove from site
    get ecu offset   # should be 0, i.e., not in site
    Get database information
    Delete site with id   SITE0
    Logout
    Login   ${user}   ${def_pass}
    Reboot ECU

Site/ECU Management Test - Try to connect to Slave ECU while Site was deleted in Master
    run keyword and expect error   *   connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}

Site/ECU Management Test - Validate Blank Site
    Run keyword and expect error   *   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Logout

Site/ECU Management Test - Restore Site when no site
    Connect to web services   ${IP}
    clean sessions
    Restore site   ${backup_site_file_location}

Site/ECU Management Test - Validate Restored Site & Restore the site again when there is site
    Run keyword and expect error   *   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Get database information
    Restore site   ${backup_site_file_location}   SITE0
    Logout

Site/ECU Management Test - Try to connect to Slave ECU while Master ECU is not part of site
    run keyword and expect error   *   connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}

Site/ECU Management Test - Restore Master ECU when has db but not in site
    clean sessions
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and expect error   *   Remove from site
    clean sessions
    Restore ecu   ${IP}   ${backup_master_ecu_file_location}   #this will also reboot the ecu after upload the files
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    get ecu offset   # should be an interger >=100
    Remove from site
    Logout

Site/ECU Management Test - Restore Master ECU when has db and in site
    clean sessions
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and expect error   *   Remove from site
    Bring ECU into site   ${IP}   ecu_name=MasterECU   site_type=${site_type}
    Get database information
    ${master_ecu_offset}=   get ecu offset   # should be 0
    restore ecu   ${IP}   ${backup_master_ecu_file_location}   SITE0   ${master_ecu_offset}   SESSION0
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    get ecu offset   # should be an interger >=100
    Remove from site
    Logout

Site/ECU Management Test - Cancle site and ECU backup
    Remove File   ${backup_master_ecu_file_location}
    Remove File   ${backup_site_file_location}
    Login   ${user}   ${pass}
    Run keyword and expect error   *   Backup ecu and download   ${back_ecu_input}   location=${backup_master_ecu_file_location}   timeout=1
    Run keyword and expect error   *   Backup site and download   location=${backup_site_file_location}   timeout=1
    File should not exist   ${backup_master_ecu_file_location}
    File should not exist   ${backup_site_file_location}
    Logout

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.101
${slave_IP}   172.24.172.102
${user}   sysadmin
${def_pass}   1um3nad3
${default_ip}   172.24.172.200
${pass}   newpassword
${automated_backup_date}   2018-05-09

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

${new_site_for_automated_backup}   SEPARATOR=\n
...     {
...         "name": "Automated Backup test",
...         "version": "Version 4.0.0",
...         "customer": "QA",
...         "project": "Robot",
...         "author": "Jia",
...         "default": true,
...         "date": "09/21/2017 10:59:00 AM",
...         "username": "${user}",
...         "password": "${def_pass}",
...         "fullname": "System Administrator",
...         "site-type": "${site_type}"
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

${original_master_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${IP}"
...   }

*** Keywords ***
System Startup
    Run keyword and continue on failure   Reset System   ${IP}
    Run keyword and continue on failure   Reset System   ${slave_IP}

    Connect to ECU   ${IP}   spy_port=9119
    Connect to web services   ${IP}   ${user}   ${def_pass}

    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU   site_type=${site_type}
    Logout

System Breakdown
    Remove File   .//artifacts//*.zip
    Remove File   .//artifacts//*.sqlite

    Extract Spy Messages
    Disconnect

    Run keyword and continue on failure   Reset System   ${IP}
    Run keyword and continue on failure   Reset System   ${slave_IP}


Reset System
    [Arguments]   ${ip}
    ${status}   ${value}=   run keyword and ignore error   Connect to web services   ${ip}   ${user}   ${pass}

    run keyword if  '${status}' == 'PASS'
    ...   Factory default with IP change   ${ip}

    Connect to web services   ${ip}   ${user}   ${def_pass}
    Factory default with IP change   ${ip}

    Connect to ECU   ${ip}
    Add public key
    Disconnect

Factory default with IP change
    [Arguments]   ${ip}
    Factory default ecu   timeout=120
    Log   please be patient, it may take a coupld minutes before the script can ping 172.24.172.200
    Connect to web services   ${default_ip}  timeout=120

    ${json}=   Evaluate   json.loads('''${original_master_IP}''')   json
    Set to dictionary   ${json}   Address=${ip}
    ${json_string}=   Evaluate   json.dumps(${json})   json

    Change local ip   json_payload=${json_string}
    Sleep   30
