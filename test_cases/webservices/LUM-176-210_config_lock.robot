*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       lum-176   lum-210   webservices   configuration-lock   update-tables

*** Test Cases ***
Miscellaneous & Table Management Test
    Login   ${user}   ${pass}
    Get user list
    Lock configuration   USER0
    Configuration lock status
    Unlock configuration
    Configuration lock status
    Lock configuration   USER0
    Get database information
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry}
    Update tables   site_index=SITE0   json_payload=${tbl}
    Reboot ecu   # After reboot, the lock should remain.
    Login   ${user}   ${pass}
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry}
    Get table   site_index=SITE0   table=db_info
    Update tables   site_index=SITE0   json_payload=${tbl}
    Get table   site_index=SITE0   table=db_info
    Sleep   10s   # sleep 10 seconds after reboot so the entropy (randomness) can increase to the level it should be at
    Add user   ${new_user}
    Logout
    Login   ${new_user_name}   ${new_user_password}
    # if you pass in the current lock-id belongs to ${user}, then you still can update table, but this is not a valid user case
    Run keyword and expect error   *   Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry2}   lock_id=invalid
    Run keyword and expect error   *   Update tables   site_index=SITE0   json_payload=${tbl2}   lock_id=invalid
    Unlock configuration   force=True
    Configuration lock status
    Get user list
    Lock configuration   USER1
    Configuration lock status
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry_2}
    Update tables   site_index=SITE0   json_payload=${tbl_2}
    Logout
    Login   ${user}   ${pass}
    Configuration lock status
    Run keyword and expect error   *   Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry2}   lock_id=invalid
    Run keyword and expect error   *   Update tables   site_index=SITE0   json_payload=${tbl2}   lock_id=invalid
    # pass in empty lock-id will overide the lock-id check
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry}   lock_id=
    Update tables   site_index=SITE0   json_payload=${tbl}   lock_id=
    Unlock configuration   force=True
    Configuration lock status
    Logout

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   10.215.21.121
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   newpassword
${new_user_name}   New User
${new_user_password}   Lumenade-1234!

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

${new_user}   SEPARATOR=\n
...   {
...       "user-id": "",
...       "user-name": "${new_user_name}",
...       "user-group": 3,
...       "password-plaintext" : "${new_user_password}"
...   }

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

${tbl}      SEPARATOR=\n
...   {
...       "update-id" : "D84BF8ED-F8F3-4662-B070-F58BE4FFE800",
...       "lock-id": "",
...       "add": [
...           {
...               "db_info": [
...                   {"DB_DATA": "", "DB_NAME": "Jia", "DB_VALUE": "7"}
...                ]
...           }
...       ]
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

${tbl2}      SEPARATOR=\n
...   {
...       "update-id" : "D84BF8ED-F8F3-4662-B070-F58BE4FFE801",
...       "lock-id": "",
...       "delete": [
...           {
...               "db_info": [
...                   {"DB_DATA": "", "DB_NAME": "Jia", "DB_VALUE": "7"}
...                ]
...           }
...       ]
...   }

*** Keywords ***
Setup System
    [Documentation]   Create a new site on Master ECU & Bring the Master ECU to site
    Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}    db_read=False
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout

Breakdown System
    [Documentation]   Remove the Master ECU from the site & Delete the site
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Unlock configuration   force=True
    Run keyword and ignore error   Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .\\artifacts\\default.sqlite