*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn

Suite Setup      System Startup
Suite Teardown   System Breakdown
Test Teardown    Extract Spy Messages

Force Tags       webservices   sanity_test   smoke_test

*** Test Cases ***
Sessionless Get API Calls
    Connect to web services   ${IP}   timeout=30
    ${ip_return}=  Get local ip   expected_ip=${IP}
    Get version
    Get about
    Get ecu information
    Get locator

Sessionless Post API Calls
    Wink ecu
    Create new site   ${new_site}

General API Calls
    Login   ${user}   ${pass}
    Logout

Miscellaneous API Calls
    Login   ${user}   ${pass}
    Get user list
    ${lock_id}=   Lock configuration   USER0   force=false
    Configuration lock status   ${lock_id}
    Unlock configuration   force=false

Site Management API Calls
    Get database information
    Bring ecu into site   ${IP}
    Get master info
    Backup site and download   .\\artifacts\\site_backup.zip
    Rename site   ${new_site_name}   SITE0
    Unmap ecu
    Remove from site
    Delete site with id   SITE0
    Restore site   .\\artifacts\\site_backup.zip

Offset Management API Calls
    Login   ${user}   ${pass}
    Get database information
    Get registration offset
    ${offsets_list}=   Get offsets   SITE0   1
    ${ecu_offset}=   Get ecu offset
    ${ref_addrs_list}=   Get addresses   site_index=SITE0   offset=${ecu_offset}   num=1
    Free addresses   SITE0   {"ref-addresses":${ref_addrs_list}}
    Free offsets   SITE0   {"offsets":${offsets_list}}

Plan and Table Management API Calls
    Login   ${user}   ${pass}
    Get database information
    Get user list
    ${lock_id}=   Lock configuration   USER0   force=true
    Upload floorplan   SITE0   .//input//floorplan.efg.gz
    Get floorplan   SITE0   FLOOR0   .//artifacts
    Delete floorplan   SITE0   FLOOR0
    Get table   SITE0   DB_INFO
    ${update_id}=   Get update id
    Update tables   SITE0     ${db_info}   update_id=${update_id}   lock_id=${lock_id}
    Unlock configuration   force=true

User Management API Calls
    Get user info

ECU Management API Calls
    Backup ecu and download   ${back_ecu_input}   location=.//artifacts//ecu_backup.zip
    Reboot ecu
    Restore ecu   ${IP}   ecu_backup=.//artifacts//ecu_backup.zip
    Login   ${user}   ${pass}
    run keyword and ignore error   Unmap ecu

*** Keywords ***
System Startup
    Reset System
    Connect to ECU   ${IP}   spy_port=9119

System Breakdown
    Extract Spy Messages
    Disconnect
    Reset System

Reset System
    ${status}   ${value}=   run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}

    run keyword if  '${status}' == 'PASS'
    ...   Factory default with IP change

    Connect to web services   ${IP}   ${user}   ${def_pass}
    Factory default with IP change

    Connect to ECU   ${IP}   spy_port=9119
    Add public key
    Disconnect

Factory default with IP change
    Factory default ecu   timeout=120
    Connect to web services   ${default_ip}  timeout=120
    Change local ip   json_payload=${original_master_IP}
    Sleep   30

*** Variables ***
${site_type}   lumenade
${IP}   192.168.86.88
${default_ip}   172.24.172.200
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   3nc31ium

${new_site}   SEPARATOR=\n
...     {
...         "name": "Simple Sanity",
...         "version": "Version 4.0.0",
...         "customer": "QA",
...         "project": "Robot",
...         "author": "Alexis Mabini",
...         "default": true,
...         "date": "06/29/2017 9:54:00 AM",
...         "username": "${user}",
...         "password": "${pass}",
...         "fullname": "System Administrator",
...         "site-type": "${site_type}"
...     }

${new_site_name}   SEPARATOR=\n
...     {
...         "site-name": "New Simple Sanity"
...     }

${back_ecu_input}   SEPARATOR=\n
...     {
...         "store-log-files": true,
...         "store-event-files": true,
...         "store-core-dumps": true
...     }

${original_master_IP}   SEPARATOR=\n
...   {
...       "Dhcp": false,
...       "Netmask": "255.255.255.0",
...       "Gateways": [],
...       "Address": "${IP}"
...   }

${automated_backup_config_input}   SEPARATOR=\n
...   {
...      "automated-backups": [
...      {
...        "backup-type": "site-backup",
...        "store-log-files": "all-backups",
...        "time-of-day": 9,
...        "day-of-week": "Monday",
...        "num-of-months": 2,
...        "week-of-month": 2,
...        "num-of-weeks": 0,
...        "num-of-days": 1,
...        "ecu-address": "${IP}"
...      },
...      {
...        "backup-type": "ecu-backup",
...        "store-log-files": "none",
...        "time-of-day": 13,
...        "day-of-week": "Saturday",
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

${db_info}   SEPARATOR=\n
...   {
...       "update-id" : "",
...       "lock-id": "",
...       "add": [
...           {
...               "db_info": [
...                   {"DB_DATA": "", "DB_NAME": "Alex", "DB_VALUE": "7"}
...                ]
...           }
...       ]
...   }
