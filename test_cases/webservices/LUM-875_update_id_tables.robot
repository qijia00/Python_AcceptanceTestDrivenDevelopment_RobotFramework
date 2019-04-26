*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       lum-875   webservices   non_volatile_sync_id

*** Variables ***
${IP}   10.215.21.121
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   password

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

${tbl_add}      SEPARATOR=\n
...   {
...       "lock-id": "",
...       "add": [
...           {
...               "db_info": [
...                   {"DB_DATA": "", "DB_NAME": "Jia", "DB_VALUE": "7+"}
...                ]
...           }
...       ]
...   }

${tbl_delete}      SEPARATOR=\n
...   {
...       "lock-id": "",
...       "delete": [
...           {
...               "db_info": [
...                   {"DB_DATA": "", "DB_NAME": "Jia", "DB_VALUE": "7+"}
...                ]
...           }
...       ]
...   }

*** Test Cases ***
Test
#    Connect to web services   ${IP}   ${user}   ${pass}
#    get update id
#    Reboot ecu
    Connect to web services   ${IP}   ${user}   ${pass}
    Get user list
    ${lock_id}=   Lock configuration   USER0   force=true
    ${update_id}=   get update id
    Get database information
#    Update tables hack   site_index=SITE0   json_payload=${tbl_add}   lock_id=${lock_id}
    Update tables   site_index=SITE0   json_payload=${tbl_add}   update_id=${update_id}   lock_id=${lock_id}
    ${update_id}=   get update id
    Get table   site_index=SITE0   table=db_info
#    Reboot ecu   # After reboot, the update id should remain.
#    Login   ${user}   ${pass}
#    ${update_id}=   get update id
    Update tables   site_index=SITE0   json_payload=${tbl_delete}   update_id=${update_id}   lock_id=${lock_id}
    ${update_id}=   get update id
    Get table   site_index=SITE0   table=db_info
    Logout

*** Keywords ***
Setup System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}
    run keyword and ignore error   remove from site
    run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${site}
    logout

Breakdown System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}
    Unlock configuration   force=True
    run keyword and ignore error   remove from site
    run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.sqlite