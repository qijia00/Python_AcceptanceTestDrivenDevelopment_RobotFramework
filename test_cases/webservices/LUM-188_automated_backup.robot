*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       lum-188   webservices   automated_backup

*** Variables ***
${IP}   172.24.172.101
${user}   sysadmin
${pass}   123456

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
...         "site-type": "lumenade"
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
...        "day-of-week": "Thursday",
...        "num-of-months": 2,
...        "week-of-month": 2,
...        "num-of-weeks": 1,
...        "num-of-days": 1,
...        "ecu-address": "${IP}"
...      },
...      {
...        "backup-type": "ecu-backup",
...        "store-log-files": "none",
...        "time-of-day": 3,
...        "day-of-week": "Thursday",
...        "num-of-months": 2,
...        "week-of-month": 3,
...        "num-of-weeks": 2,
...        "num-of-days": 3,
...        "ecu-address": "${IP}"
...       }
...     ]
...  }

${automated_backup_download}   SEPARATOR=\n
...   {
...       "ecu-address": "${IP}",
...       "backup-date": "2017-08-15",
...       "backup-name": "ecu_backup1.zip"
...   }

*** Test Cases ***
Backup ECU
    [Documentation]   Backup ECU test
    Login   ${user}   ${pass}
    Backup ecu and download   ${back_ecu_default_input}   location=.//artifacts//ecu_backup0.zip
    Backup ecu and download   ${back_ecu_input}   location=.//artifacts//ecu_backup1.zip
    logout

Automated backup config
    establish ssh connection   ${IP}
    # you need to leave enough time to create site, bring ecu into site, then backup all the log files.
    set linux clock   02:59:00
    Connect to web services   ${IP}   ${user}   ${pass}
    set automated backup configuration   ${automated_backup_config_input}
    get automated backup configuration
    logout

Automated backup
    Login   ${user}   ${pass}
    get automated backup
    automated backup download   ${automated_backup_download}   location=.//artifacts//automated-backup.zip
    logout

*** Keywords ***
Setup System
    [Documentation]   Create a site and upload a floorplan
    Connect to web services   ${IP}   sysadmin   1um3nad3
    Create new site   ${new_site}
    Get database information
    Login   ${user}   ${pass}
    Logout

Breakdown System
    [Documentation]   Delete the site
    Login   ${user}   ${pass}
    Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.zip
#    Remove File   .//artifacts//*.sqlite