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
    ${lock_id}=   Lock configuration   USER0   force=
#    Unlock configuration
#    Configuration lock status   lock_id=None
    Add user   ${new_user}
    Logout
    Login   ${new_user_name}   ${new_user_password}
#    Get user list
#    Lock configuration   USER1   force=true
    Configuration lock status   lock_id=${lock_id}

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   10.215.21.17
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
...       "user-group": 4,
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