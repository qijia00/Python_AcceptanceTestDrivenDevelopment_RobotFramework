*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       lum-1046   webservices   update_id_for_single_table

*** Variables ***
${IP}   10.215.21.17
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

${tbl_entry}      SEPARATOR=\n
...   {
...       "lock-id": "",
...       "data": [
...            {
...               "DB_DATA": "",
...               "DB_NAME": "Project",
...               "DB_VALUE": "Modified Project"
...             }
...        ]
...   }

${tbl_entry2}      SEPARATOR=\n
...   {
...       "lock-id": "",
...       "data": [
...            {
...               "DB_DATA": "",
...               "DB_NAME": "Project",
...               "DB_VALUE": "Robot"
...             }
...        ]
...   }

*** Test Cases ***
Test
    Connect to web services   ${IP}   ${user}   ${pass}
    get update id
    Reboot ecu    # After reboot, the update id should remain.
    Connect to web services   ${IP}   ${user}   ${pass}
    Get user list
    ${lock_id}=   Lock configuration   USER0   force=true
    ${update_id}=   get update id
    Get database information
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry}   update_id=   lock_id=${lock_id}
    ${update_id}=   get update id
    Get table   site_index=SITE0   table=db_info
    Reboot ecu   # After reboot, the update id should remain.
    Login   ${user}   ${pass}
    ${update_id}=   get update id
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry2}   update_id=${update_id}   lock_id=${lock_id}
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