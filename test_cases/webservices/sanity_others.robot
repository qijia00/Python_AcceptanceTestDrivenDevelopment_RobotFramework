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
General Test
    Login   ${user}   ${pass}
    Get Version
    Logout

Misc Test
    clean sessions
    Login   ${user}   ${pass}
    validate session   session_index=SESSION0
    validate session   session_id=invalid   is_valid=False
    Get About
    Get Database Information
    Get ECU Information
    Get Local IP
    Start Locator   local_only=
    Get Locator   local_only=
    Wink ecu
    Logout

User Management Test   # This test needs to be run before Table Management & Miscellaneous Test to make both of them work
    Login   ${user}   ${pass}
    Get user list
    Get user info
    Add user   ${new_user}   # configrator
    Logout
    Login   ${new_user_name}   ${new_user_password}
    # Get user list suppose to work for admin user, but ECU does not check any user privilidge.
    Get user list
    # add user only add user to TBL_ECS_USER but not TBS_ECS_USER_BZONE table, so Get user info which checks both tables will not work.
    # but when add user from Polaris, the user will be added to both table.
    Run keyword and expect error   *   Get user info
    Change user password   USER1   ${change_password}
    Logout
    Login   ${new_user_name}   ${new_user_changed_password}
    Change user password   USER1   ${change_password_back}
    Logout
    Login   ${new_user_name}   ${new_user_password}
    Logout

Offset Management Test
    Login   ${user}   ${pass}
    Get database information
    Get registration offset
    ${offsets_list}=   Get offsets   SITE0   2
    ${ecu_offset}=   get ecu offset
    ${ref_addrs_list}=   Get addresses   site_index=SITE0   offset=${ecu_offset}   num=2
    # test /api/site/X/ecu/Y/ref-addresses
    Free addresses   SITE0   {"ref-addresses":${ref_addrs_list}}   ${ecu_offset}
    ${ref_addrs_list}=   Get addresses   site_index=SITE0   offset=${ecu_offset}   num=2
    # test /api/site/X/ref-addresses
    Free addresses   SITE0   {"ref-addresses":${ref_addrs_list}}
    Free offsets   SITE0   {"offsets":${offsets_list}}
    logout

Plan Management Test
    Login   ${user}   ${pass}
    Get user list
    ${lock_id}=   Lock configuration   USER0   force=true
    Get database information
    Upload floorplan   SITE0   .//input//floorplan.efg.gz
    Get floorplan   SITE0   FLOOR0   .//artifacts
    Delete floorplan   SITE0   FLOOR0
    Unlock configuration   force=true
    Logout

Table Management & Miscellaneous & User Management Test
    Login   ${user}   ${pass}
    Get user list
    ${lock_id}=   Lock configuration   USER0   force=true
    Configuration lock status   lock_id=${lock_id}
    Unlock configuration   force=true
    Configuration lock status   lock_id=
    ${lock_id}=   Lock configuration   USER0   force=true
    Get database information
    ${update_id}=   get update id
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry}   update_id=${update_id}   lock_id=${lock_id}
    ${update_id}=   get update id
    Get table   site_index=SITE0   table=db_info
    Update tables   site_index=SITE0   json_payload=${tbl}   update_id=${update_id}   lock_id=${lock_id}
    ${update_id}=   get update id
    Get table   site_index=SITE0   table=db_info
    Reboot ecu   # After reboot, the lock and update id should remain.
    Login   ${user}   ${pass}
    Get database information
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry2}   update_id=${update_id}   lock_id=${lock_id}
    ${update_id}=   get update id
    Get table   site_index=SITE0   table=db_info
    Update tables   site_index=SITE0   json_payload=${tbl2}   update_id=${update_id}   lock_id=${lock_id}
    ${update_id}=   get update id
    Get table   site_index=SITE0   table=db_info
    Logout
    Login   ${new_user_name}   ${new_user_password}
    # if you pass in the current lock-id belongs to ${user}, then you still can update table, but this is not a valid user case
    Run keyword and expect error   *   Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry}   update_id=${update_id}   lock_id=invalid
    Run keyword and expect error   *   Update tables   site_index=SITE0   json_payload=${tbl}   update_id=${update_id}   lock_id=invalid
    Unlock configuration   force=true
    Configuration lock status   lock_id=
    Get user list
    ${lock_id}=   Lock configuration   USER1   force=true
    Configuration lock status   lock_id=${lock_id}
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry}   update_id=${update_id}   lock_id=${lock_id}
    ${update_id}=   get update id
    Get table   site_index=SITE0   table=db_info
    Update tables   site_index=SITE0   json_payload=${tbl}   update_id=${update_id}   lock_id=${lock_id}
    ${update_id}=   get update id
    Get table   site_index=SITE0   table=db_info
    Logout
    Login   ${user}   ${pass}
    Configuration lock status   lock_id=${lock_id}
    Run keyword and expect error   *   Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry2}   update_id=${update_id}   lock_id=invalid
    Run keyword and expect error   *   Update tables   site_index=SITE0   json_payload=${tbl2}   update_id=${update_id}   lock_id=invalid
    # pass in empty lock-id will overide the lock-id check
    Update table   site_index=SITE0   table=db_info   json_payload=${tbl_entry2}   update_id=${update_id}   lock_id=
    ${update_id}=   get update id
    Get table   site_index=SITE0   table=db_info
    Update tables   site_index=SITE0   json_payload=${tbl2}   update_id=${update_id}   lock_id=
    Get table   site_index=SITE0   table=db_info
    Unlock configuration   force=True
    Configuration lock status   lock_id=${lock_id}
    Logout

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   192.168.86.88
${default_ip}   172.24.172.200
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   newpassword
${new_user_name}   New User
${new_user_password}   Lumenade-1234!
${new_user_changed_password}   !4321-Lumenade

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

${change_password}   SEPARATOR=\n
...   {
...       "user-id": "",
...       "password-plaintext": "${new_user_changed_password}"
...   }

${change_password_back}   SEPARATOR=\n
...   {
...       "user-id": "",
...       "password-plaintext": "${new_user_password}"
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
...       "update-id" : "",
...       "lock-id": "",
...       "delete": [
...           {
...               "db_info": [
...                   {"DB_DATA": "", "DB_NAME": "Jia", "DB_VALUE": "7"}
...                ]
...           }
...       ]
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

    Connect to ECU   ${IP}   spy_port=9119
    Connect to web services   ${IP}   ${user}   ${def_pass}

    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Logout

System Breakdown
    Extract Spy Messages
    Disconnect
    Run keyword and continue on failure   Reset System   ${IP}

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
    Connect to web services   ${default_ip}  timeout=120

    ${json}=   Evaluate   json.loads('''${original_master_IP}''')   json
    Set to dictionary   ${json}   Address=${ip}
    ${json_string}=   Evaluate   json.dumps(${json})   json

    Change local ip   json_payload=${json_string}
    Sleep   30
