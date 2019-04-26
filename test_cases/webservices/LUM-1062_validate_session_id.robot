*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

#Suite Setup      Setup System
#Suite Teardown   Breakdown System

Force Tags       webservices   LUM-1062   validate_seesion_id

*** Test Cases ***
#Validate session id
#    clean sessions
#    Connect to web services   ${IP}   db_read=false
#    Login   ${user}   ${pass}   # SESSION0 is returned
#    Connect to websocket   ${IP}   SESSION0
#    Get database information   SESSION0
#    Connect to websocket   ${slave_IP}   SESSION0
#    Connect to web services   ${slave_IP}
#    Get version    SESSION0
#    Connect to web services   ${IP}
#    LOGOUT
#    run keyword and expect error   *   Connect to websocket   ${IP}   SESSION0
#    run keyword and expect error   *   Get database information   SESSION0
#    run keyword and expect error   *   Connect to websocket   ${slave_IP}   SESSION0
#    Connect to web services   ${slave_IP}
#    run keyword and expect error   *   Get version    SESSION0
#
#    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}   # SESSION1 is returned
#    Connect to websocket   ${slave_IP}   SESSION1
#    Get version    SESSION1
#    Connect to websocket   ${IP}   SESSION1
#    connect to web services   ${IP}
#    Get database information   SESSION1

#Unplug master ecu
#    run keyword and expect error   *   connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
#    run keyword and expect error   *   Connect to websocket   ${slave_IP}   SESSION1
#    Connect to web services   ${slave_IP}
#    run keyword and expect error   *   Get version    SESSION1

#Plug master ecu   # all session ids are cleans after ECU reboot
#    Connect to web services   ${slave_IP}
#    validate session   session_id=iaTFL7k5QYAuPzEzDESVERff   is_valid=False
#    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}   # SESSION0 is returned
#    validate session   session_index=SESSION0
#    logout
#    validate session   session_index=SESSION0   is_valid=False
#
#session id time out after 30 minutes
#    clean sessions
#    connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}   # SESSION2 is returned
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   1 minutes
#    validate session   session_index=SESSION0
#    sleep   2 minutes
#    validate session   session_index=SESSION0   is_valid=False

login multiple slave ecus at the same time
    clean sessions
    Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}   # SESSION0 is returned
    Connect to websocket   ${IP}   SESSION0
    Connect to websocket   ${slave_IP}   SESSION0
    connect to websocket   ${slave_IP1}   SESSION0
    connect to websocket   ${slave_IP2}   SESSION0
    connect to websocket   ${slave_IP3}   SESSION0
    connect to websocket   ${slave_IP4}   SESSION0
    connect to websocket   ${slave_IP5}   SESSION0
    connect to websocket   ${slave_IP6}   SESSION0
    connect to websocket   ${slave_IP7}   SESSION0
    connect to websocket   ${slave_IP8}   SESSION0

*** Variables ***
${version}   v2
${site_type}   lumenade
${IP}   172.24.172.111
${slave_IP}   172.24.172.112
${slave_IP1}   172.24.172.101
${slave_IP2}   172.24.172.102
${slave_IP3}   172.24.172.103
${slave_IP4}   172.24.172.104
${slave_IP5}   172.24.172.106
${slave_IP6}   172.24.172.107
${slave_IP7}   172.24.172.109
${slave_IP8}   172.24.172.110
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
#Create a cfg.json file under non-master ECU /firmware/webservice/data/cfg.json to indicate who is the master ECU:
#
#{
#    "master-ip" : "10.215.21.121"
#}
#
#Eventually, the cfg.json file will be created by Polaris to indicate who is the master ECU.

#Websockets can be enabled via the ECU.ini configuration option "SocketOptions".
#
#SocketOptions = {"enable-web-sockets" : true, "certificate-file" : "data/security/nginxcertificate.crt", "key-file" : "data/security/nginxcertificate.key"}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout

Breakdown System
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}   ${version}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}   ${version}
    Get database information
    Delete site with id   SITE0
    Logout
    Remove File   .//artifacts//*.sqlite