*** Settings ***
Library          WebServiceLibrary
Library          ECULibrary
Library          BuiltIn
Library          OperatingSystem
Library          DateTime

Suite Setup         Setup system
Suite Teardown      Breakdown System

Force Tags       websocket   LUM-3052   web_socket_reliability    stress

*** Test Cases ***
Test websocket connection
    ${fail}=  Set Variable  0
    :FOR  ${index}  IN RANGE  ${repeat}
    \  Get Current Date
    \  ${passed}=  Run Keyword and Return Status    Execute
    \  Continue For Loop If  ${passed}
    \  ${fail}=  Evaluate   ${fail} + 1
    ${success}=  Set Variable  ${repeat} - ${fail}
    Log Many   Success:  ${success}
    Log Many   fail:  ${fail}

*** Variables ***
${repeat}   600   #script will run 15 hours, each round is 92 seconds.
#${repeat}   40   #script will run 1 hours, each round is 92 seconds.

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
Setup System
    Log   require special websocket image to run   WARN

Execute
    #Test websocket connection
    Connect to websocket   ${IP}
    close websocket
    clean sessions
    connect to web services   ${IP}
    Login   ${user}   ${def_pass}
    Connect to websocket   ${IP}
    Logout
    close websocket

    #Test create site then bring into site
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

    #Test websocket connection after bring into site
    Connect to websocket   ${IP}
    clean sessions
    connect to web services   ${IP}
    Login   ${user}   ${pass}
    Connect to websocket   ${IP}
    Logout

    #Test remove from site then delete site
    Connect to web services   ${IP}   ${user}   ${pass}
    Remove from site
    Get database information
    Connect to web services   ${IP}   ${user}   ${pass}
    Delete site with id   SITE0
    Logout

    #Test websocket connection after remove from site
    Connect to websocket   ${IP}
    clean sessions
    connect to web services   ${IP}
    Login   ${user}   ${def_pass}
    Connect to websocket   ${IP}
    close websocket
    Logout
    close websocket

Breakdown System
    Remove File   .//artifacts//*.sqlite
