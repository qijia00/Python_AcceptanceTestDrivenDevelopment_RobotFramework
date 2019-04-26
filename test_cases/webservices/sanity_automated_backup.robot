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
Create site on Master ECU and Bring Master ECU into site
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Create new site   ${new_site_for_automated_backup}
    Login   ${user}   ${def_pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU   site_type=${site_type}
    logout

Bring Slave ECU into site
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Get database information
    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in this test case
    Logout
    Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Remove from site
    Bring ECU into site   ${IP}   ecu_name=SlaveECU   site_type=${site_type}   offset=OFFSET0
    Logout

#Site/ECU Management Test - Switch to Master ECU
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Free offsets   SITE0   {"offsets":${offsets_list}}
    Logout

#Site/ECU Management Test - Switch to Master ECU
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Free offsets   SITE0   {"offsets":${offsets_list}}
    Logout

Automated backup
    establish ssh connection   ${IP}
    # you need to leave enough time to create site, bring ecu into site, then backup all the log files.
    set linux clock   02:58:00   ${automated_backup_date}
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    set automated backup configuration   ${automated_backup_config_input_site}
    get automated backup configuration
    sleep   3 minutes   # we have to sleep longer if "store-log-files" is "all-backups"
    get automated backup

    # when back up from same ip, site backup and ecut backup can not happen at the same time
    establish ssh connection   ${IP}
    # you need to leave enough time to create site, bring ecu into site, then backup all the log files.
    set linux clock   03:58:00   ${automated_backup_date}
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    set automated backup configuration   ${automated_backup_config_input_ecu}
    get automated backup configuration
    sleep   3 minutes   # we have to sleep longer if "store-log-files" is "all-backups"
    get automated backup

    automated backup download   ${automated_master_site_backup_download}   location=.//artifacts//automated-master-site-backup.zip
    automated backup download   ${automated_master_ecu_backup_download}   location=.//artifacts//automated-master-ecu-backup.zip
    automated backup download   ${automated_slave_ecu_backup_download}   location=.//artifacts//automated-slave-ecu-backup.zip
    Logout

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.101
${slave_IP}   172.24.172.102
${user}   sysadmin
${def_pass}   1um3nad3
${default_ip}   172.24.172.200
${automated_backup_date}   2018-05-09

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

${automated_backup_config_input_site}   SEPARATOR=\n
...   {
...      "automated-backups": [
...      {
...        "backup-type": "site-backup",
...        "store-log-files": "none",
...        "time-of-day": 3,
...        "day-of-week": "Saturday",
...        "num-of-months": 1,
...        "week-of-month": 4,
...        "num-of-weeks": 1,
...        "num-of-days": 5,
...        "ecu-address": "${IP}"
...      }
...     ]
...  }

${automated_backup_config_input_ecu}   SEPARATOR=\n
...   {
...      "automated-backups": [
...      {
...        "backup-type": "ecu-backup",
...        "store-log-files": "none",
...        "time-of-day": 4,
...        "day-of-week": "Saturday",
...        "num-of-months": 1,
...        "week-of-month": 4,
...        "num-of-weeks": 1,
...        "num-of-days": 5,
...        "ecu-address": "${IP}"
...       },
...      {
...        "backup-type": "ecu-backup",
...        "store-log-files": "none",
...        "time-of-day": 4,
...        "day-of-week": "Saturday",
...        "num-of-months": 1,
...        "week-of-month": 4,
...        "num-of-weeks": 1,
...        "num-of-days": 5,
...        "ecu-address": "${slave_IP}"
...       }
...     ]
...  }

${automated_master_site_backup_download}   SEPARATOR=\n
...   {
...       "ecu-address": "${IP}",
...       "backup-date": "${automated_backup_date}",
...       "backup-name": "ECU_site_${IP}.zip"
...   }

${automated_master_ecu_backup_download}   SEPARATOR=\n
...   {
...       "ecu-address": "${IP}",
...       "backup-date": "${automated_backup_date}",
...       "backup-name": "ECU_${IP}.zip"
...   }

${automated_slave_ecu_backup_download}   SEPARATOR=\n
...   {
...       "ecu-address": "${slave_IP}",
...       "backup-date": "${automated_backup_date}",
...       "backup-name": "ECU_${slave_IP}.zip"
...   }

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

System Breakdown
    Log   please manually delete the Automated-backup folder in Master ECU before run the script again   WARN
    Remove File   .//artifacts//*.zip
    Remove File   .//artifacts//*.sqlite

    Establish ssh connection   ${IP}
    Delete Folder Contents   folder_path=//firmware//automated-backup

    Extract Spy Messages

    Run keyword and continue on failure   Reset System   ${IP}
    Run keyword and continue on failure   Reset System   ${slave_IP}

Reset System
    [Arguments]   ${ip}

    LOG TO CONSOLE    try to connect to slave webservices
    Connect to web services   ${ip}   ${user}   ${def_pass}
    Factory default with IP change   ${ip}

    Connect to ECU   ${ip}
    Add public key
    Disconnect

Factory default with IP change
    [Arguments]   ${ip}
    Factory default ecu   timeout=120
    Log to console   please be patient, it may take a couple minutes before the script can ping 172.24.172.200
    Connect to web services   ${default_ip}  timeout=120

    ${json}=   Evaluate   json.loads('''${original_master_IP}''')   json
    Set to dictionary   ${json}   Address=${ip}
    ${json_string}=   Evaluate   json.dumps(${json})   json

    Change local ip   json_payload=${json_string}
    Sleep   30
