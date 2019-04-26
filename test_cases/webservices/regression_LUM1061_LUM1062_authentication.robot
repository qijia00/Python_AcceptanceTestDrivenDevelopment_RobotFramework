*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Setup      Setup System
Suite Teardown   Breakdown System

Force Tags       webservices   LUM-1061   LUM-1062   websocket

*** Test Cases ***
Session id validality and bring slave ECU into site
    clean sessions
    connect to web services   ${IP}
    Login   ${user}   ${pass}   # SESSION0 is returned
    validate session   session_index=SESSION0
    Logout   # SESSION0 becomes invalid
    validate session   session_index=SESSION0   is_valid=False
    Login   ${user}   ${pass}   # SESSION1 is returned
    Logout   SESSION1   # SESSION1 becomes invalid
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}   # SESSION2 is returned
    validate session   session_index=SESSION2
    ${offsets_list}=    Get offsets   SITE0   1   # return value is local variable, only valid in this test case
    Connect to web services   ${slave_IP}
    run keyword and ignore error   Login   ${user}   ${def_pass}   # SESSION3 is returned
    run keyword and ignore error   Login   ${user}   ${pass}   # SESSION3 is returned
    run keyword and ignore error   Remove from site
    Bring ECU into site   ${IP}   ecu_name=SlaveECU   site_type=${site_type}   offset=OFFSET0
    # SESSION3 was returned before bring the Slave ECU into site, so Master ECU has no knowledge of it.
    validate session   session_index=SESSION3      is_valid=False
    # User need to logout and login to slave ECU agian to obtain a valid session with the master ECU.
    logout
    Login   ${user}   ${pass}   # SESSION4 is returned
    validate session   session_index=SESSION4
    logout   # SESSION4 becomes invalid
    validate session   session_index=SESSION4   is_valid=False

    Connect to web services   ${IP}   db_read=false
    logout   SESSION2   # SESSION2 becomes invalid
    validate session   session_index=SESSION2   is_valid=False

Forward login logout to master with site username and password
    clean sessions
    Connect to web services   ${IP}   db_read=false
    Login   ${user}   ${pass}   # SESSION0 is returned
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}   # SESSION1 is returned
    get automated backup configuration    SESSION0
    get automated backup configuration   SESSION1
    Connect to web services   ${IP}
    Get database information   session_index=SESSION0
    Get database information   session_index=SESSION1
    Connect to web services   ${slave_IP}
    logout   # SESSION1 becomes invalid
    validate session   session_index=SESSION1   is_valid=False
    Connect to web services   ${IP}
    Get database information   session_index=SESSION0
    run keyword and expect error   *   Get database information   session_index=SESSION1

Forward login logout to master with newly created username and password
    Add user   ${new_user}   SESSION0
    Connect to web services   ${slave_IP}    ${new_user_name}   ${new_user_password}   ${version}   # SESSION2 is returned
    run keyword and expect error   *   Add user   ${new_user2}
    get automated backup configuration    SESSION0
    get automated backup configuration   SESSION2
    Connect to web services   ${IP}
    Get database information   session_index=SESSION0
    Get database information   session_index=SESSION2
    Connect to web services   ${IP}
    logout   #SESSION2 becomes invalid
    validate session   session_index=SESSION2   is_valid=False
    Connect to web services   ${slave_IP}
    run keyword and expect error   *   get automated backup configuration   SESSION2
    get automated backup configuration   SESSION0

Validate session id
    Log   Session does not work with websocket   WARN
    clean sessions
    Connect to web services   ${IP}   db_read=false
    Login   ${user}   ${pass}   # SESSION0 is returned
#    Connect to websocket   ${IP}   SESSION0
    Get database information   session_index=SESSION0
#    Connect to websocket   ${slave_IP}   SESSION0
    Connect to web services   ${slave_IP}
    get automated backup configuration    SESSION0
    Connect to web services   ${IP}
    LOGOUT
#    run keyword and expect error   *   Connect to websocket   ${IP}   SESSION0
    run keyword and expect error   *   Get database information   session_index=SESSION0
#    run keyword and expect error   *   Connect to websocket   ${slave_IP}   SESSION0
    Connect to web services   ${slave_IP}
    run keyword and expect error   *   get automated backup configuration   SESSION0

    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}   # SESSION1 is returned
#    Connect to websocket   ${slave_IP}   SESSION1
    get automated backup configuration    SESSION1
#    Connect to websocket   ${IP}   SESSION1
    connect to web services   ${IP}
    Get database information   session_index=SESSION1

All session ids are cleaned after ECU reboot
    clean sessions
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}   # SESSION0 is returned
    Connect to web services   ${IP}   ${user}   ${pass}   ${version}   # SESSION1 is returned
    Get database information   session_index=SESSION0
    Get database information   session_index=SESSION1
    validate session   session_index=SESSION0
    validate session   session_index=SESSION1
    reboot ecu
    run keyword and expect error   *   Get database information   session_index=SESSION0
    run keyword and expect error   *   Get database information   session_index=SESSION1
    validate session   session_index=SESSION0   is_valid=False
    validate session   session_index=SESSION1   is_valid=False

session id time out after 30 minutes
    clean sessions
    connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}   # SESSION0 is returned
    validate session   session_index=SESSION0
    sleep   31 minutes
    validate session   session_index=SESSION0   is_valid=False

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.101
${slave_IP}   172.24.172.102
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   12345
${new_user_name}   New Admin
${new_user_password}   54321
${new_user_name2}   New Admin2
${new_user_password2}   54321

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

${new_user2}   SEPARATOR=\n
...   {
...       "user-id": "",
...       "user-name": "${new_user_name2}",
...       "user-group": 4,
...       "password-plaintext" : "${new_user_password2}"
...   }

*** Keywords ***
Setup System
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout

Breakdown System
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
    Remove from site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Remove from site
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.sqlite