*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

#Suite Setup      Setup System
#Suite Teardown   Breakdown System

Force Tags       lum-769   lum-770   lum-2395   webservices   automated_backup

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   10.215.21.17
${Slave_IP}   10.215.21.157
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   1um3nad3

${new_site}   SEPARATOR=\n
...     {
...         "name": "New Site",
...         "version": "Version 4.0.0",
...         "customer": "QA",
...         "project": "Robot",
...         "author": "Amabini",
...         "default": true,
...         "date": "06/15/2017 10:45:00 AM",
...         "username": "${user}",
...         "password": "${pass}",
...         "fullname": "A Mabini",
...         "site-type": "${site_type}"
...     }

${back_ecu_input}   SEPARATOR=\n
...     {
...         "store-log-files": false,
...         "store-event-files": false,
...         "store-core-dumps": false
...     }

${back_ecu_default_input}   SEPARATOR=\n
...     {
...     }

${automated_backup_config_input}   SEPARATOR=\n
...   {
...      "automated-backups": [
...      {
...        "backup-type": "site-backup",
...        "store-log-files": "all-backups",
...        "time-of-day": 3,
...        "day-of-week": "Saturday",
...        "num-of-months": 1,
...        "week-of-month": 4,
...        "num-of-weeks": 1,
...        "num-of-days": 5,
...        "ecu-address": "${IP}"
...      },
...      {
...        "backup-type": "ecu-backup",
...        "store-log-files": "none",
...        "time-of-day": 3,
...        "day-of-week": "Saturday",
...        "num-of-months": 1,
...        "week-of-month": 4,
...        "num-of-weeks": 1,
...        "num-of-days": 5,
...        "ecu-address": "${IP}"
...       },
...      {
...        "backup-type": "ecu-backup",
...        "store-log-files": "last-backup-only",
...        "time-of-day": 3,
...        "day-of-week": "Saturday",
...        "num-of-months": 1,
...        "week-of-month": 4,
...        "num-of-weeks": 1,
...        "num-of-days": 5,
...        "ecu-address": "${slave_IP}"
...       }
...     ]
...  }

${automated_backup_download}   SEPARATOR=\n
...   {
...       "ecu-address": "${IP}",
...       "backup-date": "2018-04-30",
...       "backup-name": "ECU_${IP}.zip"
...   }

*** Test Cases ***
#Backup ECU
#    [Documentation]   Backup ECU test
#    Connect to web services   ${IP}
#    Login   ${user}   ${pass}
#    Backup ecu and download   ${back_ecu_default_input}   location=.//artifacts//ecu_backup0.zip
#    Backup ecu and download   ${back_ecu_input}   location=.//artifacts//ecu_backup1.zip
#    logout

Automated backup config
    establish ssh connection   ${IP}
    set linux clock   02:59:45   2018-05-16
#    set linux clock   16:59:30
    Connect to web services   ${IP}   ${user}   ${pass}
    set automated backup configuration   ${automated_backup_config_input}
    get automated backup configuration
    logout

    establish ssh connection   ${slave_IP}
    set linux clock   02:59:45   2018-05-16
#    set linux clock   16:59:30
    Connect to web services   ${slave_IP}   ${user}   ${pass}
    set automated backup configuration   ${automated_backup_config_input}
    get automated backup configuration
    logout

Automated backup
    Connect to web services   ${IP}
    Login   ${user}   ${pass}
    get automated backup
    automated backup download   ${automated_backup_download}   location=.//artifacts//automated-backup.zip
    logout

*** Keywords ***
Setup System
    Connect to web services   ${IP}   sysadmin   1um3nad3
    Create new site   ${new_site}
    Get database information
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU   site_type=lumenade
    Logout

Breakdown System
    Login   ${user}   ${pass}
    Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.zip
    Remove File   .//artifacts//*.sqlite