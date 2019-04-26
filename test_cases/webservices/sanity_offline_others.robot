*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   regression

*** Test Cases ***
Misc Test
    Login   ${user}   ${pass}
    Get Database Information
    Logout

Offset Management Test
    Login   ${user}   ${pass}
    Get database information
    # For offline site, use Get offset to obtain "ECU" offset
    ${offset_list}=   Get offsets   SITE0   1
    ${offset}=   Get Offline offset   SITE0
    ${ref_addrs_list}=   Get addresses   site_index=SITE0   offset=${offset}   num=2
    # test /api/site/X/ecu/Y/ref-addresses
    Free addresses   SITE0   {"ref-addresses":${ref_addrs_list}}   ${offset}
    ${ref_addrs_list}=   Get addresses   site_index=SITE0   offset=${offset}   num=2
    # test /api/site/X/ref-addresses
    Free addresses   SITE0   {"ref-addresses":${ref_addrs_list}}
    Free offsets   SITE0   {"offsets":${offset_list}}
    logout

Plan Management Test
    Login   ${user}   ${pass}
    Get user list
    Get database information
    Upload floorplan   SITE0   .//input//floorplan.efg.gz
    Get floorplan   SITE0   FLOOR0   .//artifacts
    Delete floorplan   SITE0   FLOOR0
    Logout

Table Management & Miscellaneous & User Management Test
    Login   ${user}   ${pass}
    Get user list
    Get database information
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry}
    Get table   site_index=SITE0   table=db_info
    ${update_id}=   get update id
    # pass in empty lock-id will overide the lock-id check
    Update tables   site_index=SITE0   json_payload=${tbl}   update_id=${update_id}   lock_id=

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   192.168.86.88
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   newpassword

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
...       "update-id" : "",
...       "lock-id": "",
...       "add": [
...           {
...               "db_info": [
...                   {"DB_DATA": "", "DB_NAME": "Jia", "DB_VALUE": "7"}
...                ]
...           }
...       ]
...   }

${offline_dll}   .//artifacts//DataServiceDLL.dll
${offline_storage}   .//artifacts//testdata

*** Keywords ***
Setup System
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout

Breakdown System
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   dll=${offline_dll}   dll_data=${offline_storage}
    Run keyword and ignore error   Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Disconnect from web services
    Remove File   .//artifacts//*.egf.gz
    Remove File   .//artifacts//*.sqlite
    Remove File   .//artifacts//testdata//data//db//*.sqlite
    Remove File   .//artifacts//testdata//data//plan//*.egf.gz
    Remove File   .//artifacts//testdata//data//*.json