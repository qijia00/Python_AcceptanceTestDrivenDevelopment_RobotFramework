*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem

Suite Teardown      Breakdown System

Force Tags       websocket   LUM-1407   LUM-1539   web_socket_connection

*** Test Cases ***
Test websocket connection
    Connect to websocket   ${IP}
    close websocket
    clean sessions
    connect to web services   ${IP}
    Login   ${user}   ${def_pass}
    Connect to websocket   ${IP}
    Logout
    close websocket

Test create site then bring into site
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${def_pass}
    run keyword and ignore error   Connect to web services   ${IP}   ${user}   ${pass}
    Run keyword and ignore error   Remove from site
    Run keyword and ignore error   Get database information
    Run keyword and ignore error   Delete site with id   SITE0
    Create new site   ${new_site}
    Logout
    Login   ${user}   ${pass}
    Get database information
    Bring ECU into site   ${IP}   ecu_name=MasterECU
    Logout

Test websocket connection after bring into site
    Connect to websocket   ${IP}
    clean sessions
    connect to web services   ${IP}
    Login   ${user}   ${pass}
    Connect to websocket   ${IP}
    Logout

Test remove from site then delete site
    Connect to web services   ${IP}   ${user}   ${pass}
    Remove from site
    Log   Get DB info will fail due to LUM4541   WARN
    Get database information
    Connect to web services   ${IP}   ${user}   ${pass}
    Delete site with id   SITE0
    Logout

Test websocket connection after remove from site
    Connect to websocket   ${IP}
    clean sessions
    connect to web services   ${IP}
    Login   ${user}   ${def_pass}
    Connect to websocket   ${IP}
    close websocket
    Logout
    close websocket

*** Variables ***
${IP}   172.24.172.101
${user}   sysadmin
${def_pass}   1um3nad3
${pass}   12345
${site_type}   lumenade

${new_site}   SEPARATOR=\n
...     {
...         "name": "websocket test site",
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

*** Keywords ***
Breakdown System
    Remove File   .//artifacts//*.sqlite
